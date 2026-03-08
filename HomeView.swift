//
//  HomeView.swift
//  OOTD.AI
//

import SwiftUI
import CoreLocation
import Combine

// -------------------------------------------------------------
// MARK: - Weather Models & Manager
//   (same as before – unchanged behavior, just kept here)
// -------------------------------------------------------------

struct WeatherResponse: Codable {
    let currentWeather: CurrentWeather
    
    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
    }
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
}

class WeatherManager {
    func fetchWeather(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        let urlString =
        "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current_weather=true"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherResponse.self, from: data).currentWeather
    }
}

// -------------------------------------------------------------
// MARK: - Weather ViewModel
// -------------------------------------------------------------

@MainActor
class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var temperature: String = "--"
    @Published var iconName: String = "sun.max.fill"
    
    private let weatherManager = WeatherManager()
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        
        Task {
            do {
                let weather = try await weatherManager.fetchWeather(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude
                )
                
                temperature = "\(Int(weather.temperature))°"
                iconName = icon(for: weather.weathercode)
            } catch {
                temperature = "--"
                iconName = "exclamationmark.triangle.fill"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
    
    private func icon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 95: return "cloud.bolt.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

// -------------------------------------------------------------
// MARK: - HomeView
// -------------------------------------------------------------

struct HomeView: View {
    
    @StateObject private var weather = WeatherViewModel()
    @EnvironmentObject var closetVM: ClosetViewModel
    
    let profile: UserProfile?
    
    @State private var outfitItems: [ClosetItem] = []
    @State private var isLoading = false
    @State private var showOutfitRequest = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // HEADER with lightbulb action
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OOTD.AI")
                            .font(.system(size: 42, weight: .bold))
                            .italic()
                            .foregroundColor(.black)
                        
                        Text("Your AI Stylist")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        showOutfitRequest = true
                    } label: {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                            .padding(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                // WEATHER PILL
                HStack(spacing: 10) {
                    Image(systemName: weather.iconName)
                        .font(.system(size: 22))
                    
                    Text(weather.temperature)
                        .font(.system(size: 22, weight: .semibold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.05))
                .clipShape(Capsule())
                .padding(.horizontal)
                
                // OUTFIT CARD
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today's Outfit")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                    
                    if isLoading {
                        ProgressView("Asking your AI stylist…")
                            .padding(.vertical, 16)
                    } else if outfitItems.isEmpty {
                        Text("Tap below to generate an outfit based on your style + weather.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    } else {
                        OutfitCarousel(items: outfitItems)
                            .frame(height: 260)
                    }
                    
                    Button(action: generateOutfit) {
                        Text(outfitItems.isEmpty ? "Generate Outfit" : "Regenerate Outfit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLoading ? Color.gray : Color.black)
                            .cornerRadius(12)
                    }
                    .disabled(isLoading)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $showOutfitRequest) {
            NavigationStack {
                OutfitRequestView(profile: profile)
                    .environmentObject(closetVM)
            }
        }
    }
    
    // MARK: - Generate Outfit (AI)
    
    private func generateOutfit() {
        isLoading = true
        
        let numericTemp: Double
        if weather.temperature.hasSuffix("°"),
           let val = Double(weather.temperature.dropLast()) {
            numericTemp = val
        } else {
            numericTemp = 70
        }
        
        closetVM.generateAIOutfit(temperature: numericTemp, profile: profile) { outfit in
            outfitItems = outfit.asArray()
            isLoading = false
        }
    }
}

// -------------------------------------------------------------
// MARK: - Outfit Carousel (read-only)
// -------------------------------------------------------------

struct OutfitCarousel: View {
    let items: [ClosetItem]
    
    var body: some View {
        GeometryReader { outerGeo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(items) { item in
                        GeometryReader { geo in
                            let cardCenter = geo.frame(in: .global).midX
                            let screenCenter = outerGeo.frame(in: .global).midX
                            
                            let distance = abs(cardCenter - screenCenter)
                            let normalized = min(distance / 300, 1)
                            
                            let scale = 1 - (0.45 * normalized)
                            let opacity = 1 - (0.6 * normalized)
                            let angle = Angle(degrees: Double((cardCenter - screenCenter) / 25))
                            
                            Image(uiImage: item.uiImage ?? UIImage(systemName: "photo")!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 170, height: 230)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 6)
                                .rotation3DEffect(
                                    angle,
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.8
                                )
                                .scaleEffect(scale)
                                .opacity(opacity)
                        }
                        .frame(width: 170, height: 230)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
        }
        .frame(height: 260)
    }
}

#Preview {
    HomeView(
        profile: UserProfile(
            mainStyle: .casual,
            fitPreference: .regular,
            colorPreference: .neutrals,
            climate: .mixed
        )
    )
    .environmentObject(ClosetViewModel())
}

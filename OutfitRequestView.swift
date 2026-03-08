//
//  OutfitRequestView.swift
//  OOTD.AI
//

import SwiftUI

struct OutfitRequestView: View {
    @EnvironmentObject var closetVM: ClosetViewModel
    let profile: UserProfile?

    @State private var promptText: String = ""
    @State private var generated: ClosetViewModel.Outfit? = nil
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    // Default temperature used only for the AI call signature
    private let defaultTemperature: Double = 70

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                // Top bar: left title, right chevron-down to dismiss
                HStack(alignment: .center) {
                    Text("Outfit Ideas")
                        .font(.title)
                        .fontWeight(.bold)
                        .italic()
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Editor directly under the title
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 6)

                    TextEditor(text: $promptText)
                        .padding(14)
                        .frame(minHeight: 220)
                        .autocapitalization(.sentences)
                        .disableAutocorrection(false)

                    if promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("What do you feel like wearing? Whats the occasion?")
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                            .padding(.leading, 18)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                // Generate button appears only when user has typed something
                if !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack {
                        Spacer()
                        Button(action: generate) {
                            HStack {
                                if isLoading { ProgressView() }
                                Text("Generate Outfit")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 6)
                }

                // Results
                if let outfit = generated {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Outfit")
                            .font(.headline)
                            .padding(.horizontal)

                        let jacketLabel = fallbackLabel(forHint: outfit.jacketHint, matchedName: outfit.jacket?.name, slot: "Jacket")
                        if !jacketLabel.isEmpty { Text("Jacket: \(jacketLabel)").padding(.horizontal) }

                        let shirtLabel = fallbackLabel(forHint: outfit.shirtHint, matchedName: outfit.shirt?.name, slot: "Shirt")
                        if !shirtLabel.isEmpty { Text("Shirt: \(shirtLabel)").padding(.horizontal) }

                        let pantsLabel = fallbackLabel(forHint: outfit.pantsHint, matchedName: outfit.pants?.name, slot: "Pants")
                        if !pantsLabel.isEmpty { Text("Pants: \(pantsLabel)").padding(.horizontal) }

                        let shoesLabel = fallbackLabel(forHint: outfit.shoesHint, matchedName: outfit.shoes?.name, slot: "Shoes")
                        if !shoesLabel.isEmpty { Text("Shoes: \(shoesLabel)").padding(.horizontal) }
                        if outfit.asArray().isEmpty { Text("No items available in closet to suggest.").padding(.horizontal) }
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
        }
    }

    private func generate() {
        isLoading = true
        closetVM.generateAIOutfit(temperature: defaultTemperature, profile: profile, freeTextPrompt: promptText) { outfit in
            DispatchQueue.main.async {
                self.generated = outfit
                self.isLoading = false
            }
        }
    }

    // Helper moved out of the ViewBuilder to avoid result builder issues
    private func fallbackLabel(forHint hint: String?, matchedName: String?, slot: String) -> String {
        if let hint = hint, !hint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return hint
        }
        if let name = matchedName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name != "New Item" {
            return name
        }
        // Try to extract a garment keyword from the prompt
        let keywords = ["jacket","coat","blazer","overcoat","trench","cardigan","sweater","hoodie","shirt","tee","t-shirt","pants","jeans","trousers","shorts","skirt","dress","shoes","sneakers","boots","loafers","heels","sandal","suit"]
        let lower = promptText.lowercased()
        for kw in keywords {
            if lower.contains(kw) {
                return "\(kw.capitalized) matching your prompt"
            }
        }
        // Fallback to a short snippet of the prompt
        let snippet = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        if snippet.isEmpty { return "No suggestion" }
        if snippet.count <= 60 { return snippet }
        let idx = snippet.index(snippet.startIndex, offsetBy: 60)
        return "\(snippet[..<idx])..."
    }
}

#Preview {
    OutfitRequestView(profile: nil)
        .environmentObject(ClosetViewModel())
}

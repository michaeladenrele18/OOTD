import SwiftUI

struct SurveyView: View {
    var onFinish: (UserProfile) -> Void

    @State private var mainStyle: StyleVibe = .casual
    @State private var fit: FitPreference = .regular
    @State private var colorPref: ColorPreference = .neutrals
    @State private var climate: Climate = .mixed

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What’s your main style vibe?")) {
                    Picker("Style", selection: $mainStyle) {
                        ForEach(StyleVibe.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }

                Section(header: Text("What fits do you like most?")) {
                    Picker("Fit", selection: $fit) {
                        ForEach(FitPreference.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section(header: Text("What colors do you wear the most?")) {
                    Picker("Colors", selection: $colorPref) {
                        ForEach(ColorPreference.allCases) { color in
                            Text(color.rawValue).tag(color)
                        }
                    }
                }

                Section(header: Text("What climate are you usually in?")) {
                    Picker("Climate", selection: $climate) {
                        ForEach(Climate.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                }

                Section {
                    Button("Continue") {
                        let profile = UserProfile(
                            mainStyle: mainStyle,
                            fitPreference: fit,
                            colorPreference: colorPref,
                            climate: climate
                        )
                        onFinish(profile)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Style Survey")
        }
    }
}

#Preview {
    SurveyView { _ in }
}

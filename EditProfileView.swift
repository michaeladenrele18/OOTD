import SwiftUI

struct EditProfileView: View {
    // Accept optional binding; if nil, load from UserDefaultsManager
    var profile: Binding<UserProfile?>? = nil
    @State private var workingProfile: UserProfile = UserProfile(mainStyle: .casual, fitPreference: .regular, colorPreference: .neutrals, climate: .mixed)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Style") {
                Picker("Main style", selection: $workingProfile.mainStyle) {
                    ForEach(StyleVibe.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                Picker("Fit preference", selection: $workingProfile.fitPreference) {
                    ForEach(FitPreference.allCases) { fit in
                        Text(fit.rawValue).tag(fit)
                    }
                }

                Picker("Colors you wear", selection: $workingProfile.colorPreference) {
                    ForEach(ColorPreference.allCases) { color in
                        Text(color.rawValue).tag(color)
                    }
                }

                Picker("Climate", selection: $workingProfile.climate) {
                    ForEach(Climate.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
            }

            Section {
                Button("Save") {
                    // persist
                    if let binding = profile {
                        binding.wrappedValue = workingProfile
                        UserDefaultsManager.saveProfile(workingProfile)
                    } else {
                        UserDefaultsManager.saveProfile(workingProfile)
                    }
                    dismiss()
                }

                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            if let binding = profile, let p = binding.wrappedValue {
                workingProfile = p
            } else if let p = UserDefaultsManager.loadProfile() {
                workingProfile = p
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(profile: .constant(
            UserProfile(mainStyle: .casual, fitPreference: .regular, colorPreference: .neutrals, climate: .mixed)
        ))
    }
}

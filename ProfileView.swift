//
//  ProfileView.swift
//  OOTD.AI
//

import SwiftUI

struct ProfileView: View {
    @Binding var profile: UserProfile?
    @State private var navigateToSettings = false
    @State private var navigateToManageAccount = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Header
                    HStack {
                        Text("OOTD.AI")
                            .font(.largeTitle.italic().bold())

                        Spacer()

                        Button {
                            navigateToSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top, 10)

                    if let profile {
                        // MARK: - Profile Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 52, height: 52)

                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your Style Profile")
                                        .font(.headline)

                                    Text(profile.mainStyle.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }

                            Divider()

                            HStack(spacing: 8) {
                                TagView(text: profile.fitPreference.rawValue)
                                TagView(text: profile.colorPreference.rawValue)
                                TagView(text: profile.climate.rawValue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(radius: 4, y: 2)
                        )

                        // MARK: - Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)

                            ProfileRow(label: "Main style", value: profile.mainStyle.rawValue)
                            ProfileRow(label: "Fit preference", value: profile.fitPreference.rawValue)
                            ProfileRow(label: "Colors you wear", value: profile.colorPreference.rawValue)
                            ProfileRow(label: "Climate", value: profile.climate.rawValue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(radius: 3, y: 2)
                        )
                    }

                    // MARK: - Actions
                    VStack(alignment: .leading, spacing: 16) {

                        // RETAKE SURVEY
                        Button {
                            UserDefaultsManager.clearProfile()
                            profile = nil   // Return to survey
                        } label: {
                            Text("Retake style survey")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .foregroundColor(.black)
                        }

                        // MANAGE ACCOUNT (Navigation)
                        Button {
                            navigateToManageAccount = true
                        } label: {
                            Text("Manage account")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView(profile: $profile)
            }
            .navigationDestination(isPresented: $navigateToManageAccount) {
                ManageAccountView()
            }
        }
    }
}

// MARK: - Reusable subviews
private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }
}

private struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.05))
            )
    }
}
#Preview {
    ProfileView(
        profile: .constant(
            UserProfile(
                mainStyle: .casual,
                fitPreference: .regular,
                colorPreference: .neutrals,
                climate: .mixed
            )
        )
    )
}

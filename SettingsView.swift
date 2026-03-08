//
//  SettingsView.swift
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    // optional binding to allow editing the profile from Settings
    var profile: Binding<UserProfile?>? = nil
    @State private var notificationsEnabled = true
    @State private var darkMode = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {

                    // HEADER
                    HStack {
                        Text("Settings")
                            .font(.largeTitle.bold())
                            .italic()

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // ACCOUNT SECTION
                    VStack(spacing: 0) {
                        // Edit Profile -> navigates to edit screen
                        NavigationLink {
                            EditProfileView(profile: profile)
                        } label: {
                            OOTDRow(icon: "person.circle.fill", title: "Edit Profile")
                        }

                        Divider()

                        // Change Password -> navigates to change password screen
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            OOTDRow(icon: "lock.fill", title: "Change Password")
                        }

                        Divider()

                        // Manage Account -> navigates to ManageAccountView
                        NavigationLink {
                            ManageAccountView()
                        } label: {
                            OOTDRow(icon: "person.crop.circle.badge.checkmark", title: "Manage account")
                        }

                        Divider()

                        // Notifications row - tapping asks for permission
                        Button {
                            requestNotificationPermission()
                        } label: {
                            OOTDRow(icon: "bell.fill", title: "Notifications")
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .padding(.horizontal)

                    // PREFERENCES SECTION
                    VStack(spacing: 0) {
                        OOTDSwitchRow(icon: "moon.fill", title: "Dark mode", isOn: $darkMode)
                        Divider()
                        OOTDSwitchRow(icon: "bell.badge.fill", title: "Push notifications", isOn: $notificationsEnabled)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .padding(.horizontal)

                    // ABOUT
                    VStack(spacing: 0) {
                        OOTDRow(icon: "info.circle.fill", title: "About OOTD.AI")
                        Divider()
                        OOTDRow(icon: "star.fill", title: "Rate the app")
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .background(Color.white.ignoresSafeArea())
            .onAppear(perform: checkNotificationStatus)
            .onChange(of: notificationsEnabled) { oldValue, newValue in
                if newValue {
                    requestNotificationPermission()
                } else {
                    permissionAlertMessage = "To disable notifications completely, open the system Settings app, go to Notifications, and turn off notifications for this app."
                    showingPermissionAlert = true
                    checkNotificationStatus()
                }
            }
            .alert(isPresented: $showingPermissionAlert) {
                Alert(title: Text("Notification Permission"), message: Text(permissionAlertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Notification helpers
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    permissionAlertMessage = "Failed to request notifications: \(error.localizedDescription)"
                    showingPermissionAlert = true
                    return
                }

                if granted {
                    permissionAlertMessage = "Notifications enabled. You may be prompted by the system to allow notifications from this app."
                    notificationsEnabled = true
                } else {
                    permissionAlertMessage = "Notifications were not enabled. You can enable them later in Settings > Notifications."
                    notificationsEnabled = false
                }

                showingPermissionAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(profile: .constant(
            UserProfile(mainStyle: .casual, fitPreference: .regular, colorPreference: .neutrals, climate: .mixed)
        ))
    }
}

import SwiftUI

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            Section("Current Password") {
                SecureField("Current password", text: $currentPassword)
            }

            Section("New Password") {
                SecureField("New password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }

            Section {
                Button("Change Password") {
                    changePassword()
                }
            }
        }
        .navigationTitle("Change Password")
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Password Change"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func changePassword() {
        // Basic local validation
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Please fill in all fields."
            showingAlert = true
            return
        }

        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match."
            showingAlert = true
            return
        }

        guard newPassword.count >= 8 else {
            alertMessage = "Password must be at least 8 characters."
            showingAlert = true
            return
        }

        // TODO: integrate with real auth service. For now, show success.
        alertMessage = "Your password has been changed successfully."
        showingAlert = true

        // Clear fields
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
    }
}

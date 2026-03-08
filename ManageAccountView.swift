//
//  ManageAccountView.swift
//

import SwiftUI

struct ManageAccountView: View {
    @State private var email: String = "michael@example.com"
    @State private var username: String = "michaeladenrele"
    @State private var showDeleteAlert = false
    @State private var navigateToChangePassword = false

    // Load stored values on appear
    private func loadStored() {
        if let storedEmail = UserDefaultsManager.loadAccountEmail() {
            email = storedEmail
        }
        if let storedUsername = UserDefaultsManager.loadAccountUsername() {
            username = storedUsername
        }
    }

    private func saveStored() {
        UserDefaultsManager.saveAccount(email: email, username: username)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {

                // HEADER
                HStack {
                    Text("Manage Account")
                        .font(.largeTitle.bold())
                        .italic()

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // PROFILE SECTION
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Info")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        // Email editable field
                        HStack {
                            Text("Email")
                            Spacer()
                            TextField("Email", text: $email, prompt: Text("Email"))
                                .multilineTextAlignment(.trailing)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundColor(.primary)
                        }
                        .padding()

                        Divider()

                        // Username editable field
                        HStack {
                            Text("Username")
                            Spacer()
                            TextField("Username", text: $username, prompt: Text("Username"))
                                .multilineTextAlignment(.trailing)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .padding(.horizontal)
                }

                // SECURITY SECTION
                VStack(spacing: 0) {
                    Button {
                        navigateToChangePassword = true
                    } label: {
                        OOTDRow(icon: "lock.fill", title: "Change Password")
                    }
                    Divider()
                    OOTDRow(icon: "iphone.and.arrow.forward", title: "Sign Out of Devices")
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .padding(.horizontal)

                // DELETE ACCOUNT
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .alert("Are you sure?", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {}
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This action cannot be undone.")
                }

                Spacer()
            }
            .padding(.bottom, 40)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear(perform: loadStored)
        .onDisappear(perform: saveStored)
        .navigationDestination(isPresented: $navigateToChangePassword) {
            ChangePasswordView()
        }
    }
}

#Preview {
    ManageAccountView()
}

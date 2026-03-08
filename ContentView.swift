//
//  ContentView.swift
//  OOTD.AI
//

import SwiftUI // Import the SwiftUI framework for building the app UI

struct ContentView: View { // Define the main ContentView conforming to the View protocol
    
    @StateObject private var closetVM = ClosetViewModel() // Create and own a ClosetViewModel instance as a state object
    @State private var userProfile: UserProfile? = UserDefaultsManager.loadProfile() // Load the saved user profile (if any) from UserDefaults into a state property
    
    var body: some View { // The view's body property that describes the UI
        Group { // Use a Group to conditionally show either the main tabs or the survey
            if let profile = userProfile { // If a user profile exists, unwrap it into a local constant
                TabView { // Create a tab bar interface
                    
                    HomeView(profile: profile) // First tab: the Home screen, passed the unwrapped profile
                        .environmentObject(closetVM) // Provide the shared closet view model to the HomeView environment
                        .tabItem { // Define the tab item UI for this tab
                            Label("Home", systemImage: "house.fill") // Use a label with text "Home" and a house icon
                        }
                    
                    ClosetView() // Second tab: the Closet screen
                        .environmentObject(closetVM) // Provide the same closet view model to the ClosetView environment
                        .tabItem { // Define the tab item UI for this tab
                            Label("Closet", systemImage: "hanger") // Use a label with text "Closet" and a hanger icon
                        }
                    
                    ProfileView(profile: $userProfile) // Third tab: the Profile screen, passing a binding to userProfile
                        .environmentObject(closetVM) // Provide the closet view model to ProfileView as well
                        .tabItem { // Define the tab item UI for the profile tab
                            Label("Profile", systemImage: "person.fill") // Use a label with text "Profile" and a person icon
                        }
                } // End of TabView
                .accentColor(.black) // Set the accent color for the tab view to black
            } else { // If there is no saved user profile
                SurveyView { completedProfile in // Show the SurveyView and handle the completion with a closure that receives the completed profile
                    UserDefaultsManager.saveProfile(completedProfile) // Save the completed profile to UserDefaults
                    userProfile = completedProfile // Assign the saved profile to the state property to transition to the main UI
                } // End of SurveyView closure
            } // End of if/else
        } // End of Group
    } // End of body
} // End of ContentView struct

#Preview { // SwiftUI preview provider macro for Xcode previews
    ContentView() // Instantiate ContentView for live previews in Xcode
}

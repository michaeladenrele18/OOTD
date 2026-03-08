import Foundation

struct UserDefaultsManager {
    private static let profileKey = "userProfile"
    private static let accountEmailKey = "accountEmail"
    private static let accountUsernameKey = "accountUsername"

    static func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }

    static func loadProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    static func clearProfile() {
        UserDefaults.standard.removeObject(forKey: profileKey)
    }

    // MARK: - Account info helpers
    static func saveAccount(email: String?, username: String?) {
        UserDefaults.standard.set(email, forKey: accountEmailKey)
        UserDefaults.standard.set(username, forKey: accountUsernameKey)
    }

    static func loadAccountEmail() -> String? {
        UserDefaults.standard.string(forKey: accountEmailKey)
    }

    static func loadAccountUsername() -> String? {
        UserDefaults.standard.string(forKey: accountUsernameKey)
    }
}

import Foundation

enum StyleVibe: String, CaseIterable, Identifiable, Codable {
    case streetwear = "Streetwear"
    case casual = "Casual"
    case businessCasual = "Business Casual"
    case formal = "Formal"
    case athleisure = "Athleisure"

    var id: String { rawValue }
}

enum FitPreference: String, CaseIterable, Identifiable, Codable {
    case oversized = "Oversized / Relaxed"
    case regular = "Regular Fit"
    case slim = "Slim / Fitted"

    var id: String { rawValue }
}

enum ColorPreference: String, CaseIterable, Identifiable, Codable {
    case neutrals = "Neutrals (black/white/grey)"
    case earthTones = "Earth tones (brown/green/tan)"
    case bright = "Bright colors"
    case pastels = "Pastels"

    var id: String { rawValue }
}

enum Climate: String, CaseIterable, Identifiable, Codable {
    case mostlyWarm = "Mostly warm"
    case mixed = "Mixed"
    case mostlyCold = "Mostly cold"

    var id: String { rawValue }
}

struct UserProfile: Codable {
    var mainStyle: StyleVibe
    var fitPreference: FitPreference
    var colorPreference: ColorPreference
    var climate: Climate
}

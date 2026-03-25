import Foundation

enum AppRuntimeConfig {
    static func supabaseURL() throws -> URL {
        let rawValue = try stringValue(forInfoKey: "SUPABASE_URL")
        guard let value = URL(string: rawValue), value.scheme != nil, value.host != nil else {
            throw RuntimeConfigError.invalidValue(key: "SUPABASE_URL")
        }
        return value
    }

    static func supabasePublishableKey() throws -> String {
        let value = try stringValue(forInfoKey: "SUPABASE_PUBLISHABLE_KEY")
        if value == "REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY" {
            throw RuntimeConfigError.invalidValue(key: "SUPABASE_PUBLISHABLE_KEY")
        }
        if !value.hasPrefix("sb_publishable_") {
            throw RuntimeConfigError.invalidValue(key: "SUPABASE_PUBLISHABLE_KEY")
        }
        return value
    }

    private static func stringValue(forInfoKey key: String) throws -> String {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            throw RuntimeConfigError.missingValue(key: key)
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw RuntimeConfigError.missingValue(key: key)
        }

        return value
    }
}

enum RuntimeConfigError: LocalizedError {
    case missingValue(key: String)
    case invalidValue(key: String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "Missing required runtime config value: \(key)"
        case .invalidValue(let key):
            return "Invalid runtime config value for key: \(key)"
        }
    }
}

import Foundation

public struct FeatureFlags: Sendable {
    public var skillVerification: Bool
    public var pinnedPublishing: Bool
    public var crossIDEAdapters: Bool
    public var telemetryOptIn: Bool
    public var bulkActions: Bool

    public init(
        skillVerification: Bool = true,
        pinnedPublishing: Bool = true,
        crossIDEAdapters: Bool = true,
        telemetryOptIn: Bool = false,
        bulkActions: Bool = true
    ) {
        self.skillVerification = skillVerification
        self.pinnedPublishing = pinnedPublishing
        self.crossIDEAdapters = crossIDEAdapters
        self.telemetryOptIn = telemetryOptIn
        self.bulkActions = bulkActions
    }

    public static func fromEnvironment(_ env: [String: String] = ProcessInfo.processInfo.environment) -> FeatureFlags {
        FeatureFlags(
            skillVerification: env.bool("STOOLS_FEATURE_VERIFICATION", defaultValue: true),
            pinnedPublishing: env.bool("STOOLS_FEATURE_PUBLISHING", defaultValue: true),
            crossIDEAdapters: env.bool("STOOLS_FEATURE_ADAPTERS", defaultValue: true),
            telemetryOptIn: env.bool("STOOLS_FEATURE_TELEMETRY", defaultValue: false),
            bulkActions: env.bool("STOOLS_FEATURE_BULK_ACTIONS", defaultValue: true)
        )
    }
}

private extension Dictionary where Key == String, Value == String {
    func bool(_ key: String, defaultValue: Bool) -> Bool {
        guard let raw = self[key]?.lowercased() else { return defaultValue }
        switch raw {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            return defaultValue
        }
    }
}

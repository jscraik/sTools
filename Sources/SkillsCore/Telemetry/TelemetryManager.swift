import Foundation

// MARK: - Telemetry Manager

/// Manages telemetry recording with opt-in gating.
/// All metrics recording should go through this manager to respect user preferences.
public actor TelemetryManager: Sendable {
    /// Shared singleton instance
    public static let shared = TelemetryManager()

    /// Whether telemetry is enabled (synced with SettingsView toggle)
    private nonisolated var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "telemetryEnabled")
    }

    private init() {}

    // MARK: - Public Interface

    /// Check if telemetry recording is enabled
    public var telemetryEnabled: Bool {
        isEnabled
    }

    /// Record a telemetry event if telemetry is enabled.
    /// Returns true if the event was recorded, false if skipped.
    @discardableResult
    public func record<T>(
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T? {
        guard isEnabled else {
            logTelemetryDisabled()
            return nil
        }
        return try await operation()
    }

    /// Record a telemetry event if telemetry is enabled (sync variant).
    /// Returns true if the event was recorded, false if skipped.
    @discardableResult
    public func record<T>(
        _ operation: @escaping @Sendable () throws -> T
    ) rethrows -> T? {
        guard isEnabled else {
            logTelemetryDisabled()
            return nil
        }
        return try operation()
    }

    /// Execute an operation only if telemetry is enabled.
    /// Use this for side-effect operations like logging.
    public func ifEnabled(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        guard isEnabled else {
            logTelemetryDisabled()
            return
        }
        try await operation()
    }

    // MARK: - Private

    private func logTelemetryDisabled() {
        #if DEBUG
        print("[TelemetryManager] Telemetry disabled - skipping metrics recording")
        #endif
    }
}

// MARK: - Convenience Extensions

public extension TelemetryManager {
    /// Check if telemetry should be recorded for a specific metric type
    func shouldRecord(metric: String) -> Bool {
        guard isEnabled else {
            logTelemetryDisabled()
            return false
        }
        return true
    }
}

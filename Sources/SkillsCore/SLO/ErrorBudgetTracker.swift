import Foundation
import OSLog

// MARK: - Error Budget Tracker

/// Real-time error budget tracking and alerting.
/// Monitors SLO compliance and logs warnings when budget is consumed.
public actor ErrorBudgetTracker {
    private let logger = AppLog.telemetry
    private let measurer: SLOMeasurer

    /// Alert threshold (default 10% of error budget)
    public var alertThreshold: Double = 0.1

    public init(measurer: SLOMeasurer = SLOMeasurer()) async throws {
        self.measurer = measurer
    }

    /// Check all SLOs and log alerts if budgets are low
    public func checkBudgets() async throws -> [String: SLOMeasurement] {
        let report = try await measurer.generateReport()
        var alerts: [String: SLOMeasurement] = [:]

        // Check each SLO's error budget
        if report.crashFreeSessions.shouldAlert {
            alerts["Crash-Free Sessions"] = report.crashFreeSessions
            logAlert(
                slo: report.crashFreeSessions.slo,
                measurement: report.crashFreeSessions
            )
        }

        if report.verifiedInstallSuccess.shouldAlert {
            alerts["Verified Installs"] = report.verifiedInstallSuccess
            logAlert(
                slo: report.verifiedInstallSuccess.slo,
                measurement: report.verifiedInstallSuccess
            )
        }

        if report.syncSuccess.shouldAlert {
            alerts["Sync Success"] = report.syncSuccess
            logAlert(
                slo: report.syncSuccess.slo,
                measurement: report.syncSuccess
            )
        }

        return alerts
    }

    /// Get current budget status for a specific SLO
    public func budgetStatus(for sloType: SLOType) async throws -> SLOMeasurement {
        switch sloType {
        case .crashFreeSessions:
            return try await measurer.crashFreeSessions()
        case .verifiedInstallSuccess:
            return try await measurer.verifiedInstallSuccess()
        case .syncSuccess:
            return try await measurer.syncSuccess()
        }
    }

    /// Calculate remaining error budget as percentage
    public func remainingBudget(for sloType: SLOType) async throws -> Double {
        let measurement = try await budgetStatus(for: sloType)
        return measurement.errorBudgetRemaining
    }

    /// Check if budget is exhausted (0% remaining)
    public func isBudgetExhausted(for sloType: SLOType) async throws -> Bool {
        let remaining = try await remainingBudget(for: sloType)
        return remaining <= 0
    }

    // MARK: - Private

    private func logAlert(slo: SLO, measurement: SLOMeasurement) {
        let budgetPercent = (measurement.errorBudgetRemaining / measurement.errorBudget) * 100

        logger.error(
            """
            SLO Error Budget Alert
            SLO: \(slo.description)
            Target: \(slo.target)%
            Current: \(String(format: "%.1f", measurement.successRate))%
            Error Budget: \(String(format: "%.1f", measurement.errorBudgetRemaining))% remaining (\(String(format: "%.0f", budgetPercent))% of original budget)
            Window: \(slo.window.rawValue)
            """
        )

        #if DEBUG
        print("⚠️ SLO ALERT: \(slo.description) - Budget at \(String(format: "%.1f", budgetPercent))%")
        #endif
    }
}

// MARK: - SLO Type

/// SLO types for tracking
public enum SLOType: Sendable {
    case crashFreeSessions
    case verifiedInstallSuccess
    case syncSuccess
}

// MARK: - Error Budget Calculation

/// Error budget calculation utilities
public enum ErrorBudget {
    /// Calculate allowed failures per period based on SLO
    public static func allowedFailures(totalEvents: Int, sloTarget: Double) -> Int {
        let errorRate = (100.0 - sloTarget) / 100.0
        return Int(Double(totalEvents) * errorRate)
    }

    /// Calculate remaining budget percentage
    public static func remainingBudget(successRate: Double, sloTarget: Double) -> Double {
        let errorBudget = 100.0 - sloTarget
        let errorConsumed = max(0, 100.0 - successRate)
        return max(0, errorBudget - errorConsumed)
    }

    /// Check if budget should trigger alert
    public static func shouldAlert(remainingBudget: Double, totalBudget: Double, threshold: Double = 0.1) -> Bool {
        return remainingBudget <= (totalBudget * threshold)
    }
}

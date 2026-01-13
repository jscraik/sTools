import Foundation

/// Policy wrapper for remote artifact verification.
public struct RemoteVerificationPolicy: Sendable {
    public let mode: RemoteVerificationMode
    public let limits: RemoteVerificationLimits

    public init(mode: RemoteVerificationMode = .strict, limits: RemoteVerificationLimits = .default) {
        self.mode = mode
        self.limits = limits
    }

    public static let `default` = RemoteVerificationPolicy()
    public static let permissive = RemoteVerificationPolicy(mode: .permissive)
}

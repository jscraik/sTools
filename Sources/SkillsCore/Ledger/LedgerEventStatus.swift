import Foundation

public enum LedgerEventStatus: String, Codable, CaseIterable, Sendable {
    case success
    case failure
    case skipped
}

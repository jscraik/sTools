import Foundation

public struct TelemetryEvent: Codable, Sendable {
    public let name: String
    public let timestamp: Date
    public let attributes: [String: String]

    public init(name: String, timestamp: Date = Date(), attributes: [String: String] = [:]) {
        self.name = name
        self.timestamp = timestamp
        self.attributes = attributes
    }
}

public struct TelemetryClient: Sendable {
    public var record: @Sendable (TelemetryEvent) -> Void

    public init(record: @Sendable @escaping (TelemetryEvent) -> Void) {
        self.record = record
    }

    public static let noop = TelemetryClient { _ in }

    public static func file(url: URL) -> TelemetryClient {
        TelemetryClient { event in
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(event)
                if let line = String(data: data, encoding: .utf8) {
                    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    if FileManager.default.fileExists(atPath: url.path) {
                        let handle = try FileHandle(forWritingTo: url)
                        try handle.seekToEnd()
                        if let lineData = (line + "\n").data(using: .utf8) {
                            try handle.write(contentsOf: lineData)
                        }
                        try handle.close()
                    } else {
                        try (line + "\n").write(to: url, atomically: true, encoding: .utf8)
                    }
                }
            } catch {
                // Telemetry failures should never block workflows.
            }
        }
    }
}

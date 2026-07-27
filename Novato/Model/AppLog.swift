import Foundation
import OSLog

final class appLog
{
    // 1. Define a subsystem (usually your bundle ID)
        private static var subsystem = Bundle.main.bundleIdentifier ?? "com.myapp.logs"

        // 2. Create specific loggers for different categories
        // This helps you filter logs in the Console app
        static let cpu = Logger(subsystem: subsystem, category: "CPU")
        static let pio = Logger(subsystem: subsystem, category: "PIO")
        static let sound = Logger(subsystem: subsystem, category: "Sound")

        // Optional: A generic logger for simple use cases
        private static let general = Logger(subsystem: subsystem, category: "General")

        // 3. Helper methods for quick logging
        static func info(_ message: String) {
            general.info("\(message, privacy: .public)")
        }

        static func error(_ message: String) {
            general.error("\(message, privacy: .public)")
        }
        
        static func debug(_ message: String) {
            general.debug("\(message, privacy: .public)")
        }
}

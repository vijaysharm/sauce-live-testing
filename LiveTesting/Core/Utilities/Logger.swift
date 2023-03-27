//
//  Logger.swift
//  LiveTesting
//

import Foundation

protocol LoggerProtocol {
	func i(_ message: String)
	func e(_ message: String)
	func e(_ message: String, _ error: Error?)
	func d(_ message: String)
	func w(_ message: String)
}

private class TaggerLogger: LoggerProtocol {
	private let tag: String
	private let logger: Logger
	
	init(tag: String, logger: Logger) {
		self.tag = tag
		self.logger = logger
	}
	
	func i(_ message: String) {
		logger.i(tag, message: message)
	}
	
	func e(_ message: String) {
		self.e(message, nil)
	}
	
	func e(_ message: String, _ error: Error?) {
		logger.e(tag, message: message, error: error)
	}
	
	func d(_ message: String) {
		logger.d(tag, message: message)
	}
	
	func w(_ message: String) {
		logger.w(tag, message: message)
	}
}

class Logger {
	public static func make(tag: Any) -> LoggerProtocol {
		return TaggerLogger(tag: String(describing: tag), logger: Logger.shared)
	}
	
	enum Level {
		case info
		case debug
		case error
		case warning
	}
	
	struct LogLine {
		let tag: String
		let message: String
		let level: Level
		let timestamp: Date = Date()
	}
	
	fileprivate static let shared = Logger()
	private var lines: [LogLine] = []
	
	fileprivate func i(_ tag: String, message: String) {
		append(line: LogLine(tag: tag, message: message, level: .info))
	}
	
	fileprivate func d(_ tag: String, message: String) {
		append(line: LogLine(tag: tag, message: message, level: .debug))
	}
	
	fileprivate func e(_ tag: String, message: String, error: Error? = nil) {
		append(line: LogLine(tag: tag, message: message, level: .error))
		if let error = error {
			append(line: LogLine(tag: tag, message: "\(error)", level: .error))
		}
	}
	
	fileprivate func w(_ tag: String, message: String) {
		append(line: LogLine(tag: tag, message: message, level: .warning))
	}
	
	private func append(line: LogLine) {
		lines.append(line)
#if DEBUG
		print("\(line.message)")
#endif
	}
}

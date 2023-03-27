//
//  SauceDeviceCompanionConnection.swift
//  LiveTesting
//

import Foundation
import Combine

class SauceDeviceCompanionConnection {
	private let log = Logger.make(tag: SauceDeviceCompanionConnection.self)
	// TODO: Add a bunch of public facing callbacks for specific events from websocket (CompanionMessageType)
	public let statusUpdate = CurrentValueSubject<CompanionStatusUpdateMessage.StateType, Never>(.OFFLINE)
	public let logMessage = PassthroughSubject<CompanionLogMessage, Never>()
	public let sessionClosed = PassthroughSubject<Bool, Never>()
	public let connectionClosed = PassthroughSubject<Bool, Never>()
	
	private let webSocket: SauceWebSocket
	private let delegate: WebSocketConnectionDelegate
	private var subscriptions = Set<AnyCancellable>()
	private var isClosed = false
	
	init(
		socket: SauceWebSocket,
		delegate: WebSocketConnectionDelegate
	) {
		self.webSocket = socket
		self.delegate = delegate
		
		delegate.didOpen.sink {
			guard $0 else { return }
//			self.log.d("urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?)")
			self.log.d("Companion socket opened")
		}.store(in: &subscriptions)
		delegate.didClose.sink {
			// self.log.d("urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)")
			self.isClosed = true
			guard $0 != .normalClosure else { return }
			self.log.d("Companion connection closed because \($0)")
			self.connectionClosed.send(true)
		}.store(in: &subscriptions)
		
		read()
	}
	
	func open() {
		webSocket.socket.resume()
	}
	
	func close() {
		webSocket.socket.cancel(with: .normalClosure, reason: nil)
	}
	
	private func read() {
		webSocket.socket.receive { result in
			switch result {
			case .failure(let error):
				self.log.e("Failed to receive companion message", error)
				self.isClosed = true
				self.connectionClosed.send(true)
			case .success(let message):
				switch message {
				case .string(let text):
					self.handle(string: text)
					break
				case .data(let data):
					self.log.d("Received binary message: \(data)")
					break
				@unknown default:
					fatalError()
				}
			}

			if self.isClosed { return }
			self.read() // Weird qwerk of URLSessionWebSocketTask.. https://appspector.com/blog/websockets-in-ios-using-urlsessionwebsockettask
		}
	}
	
	private func handle(string text: String) {
		guard let messageType: CompanionMessage = try? webSocket.parser.parse(string: text) else {
			log.i("Received unparseable text message: \(text)")
			return
		}

		if messageType.type == CompanionMessageType.statusUpdate.rawValue {
			guard let status: CompanionStatusUpdateMessage = try? webSocket.parser.parse(string: text) else { return }
			statusUpdate.send(status.value.state)
			return
		}

		if messageType.type == CompanionMessageType.logMessage.rawValue {
			guard let log: CompanionLogMessage = try? webSocket.parser.parse(string: text) else { return }
			logMessage.send(log)
			return
		}
		
		if messageType.type == CompanionMessageType.sessionClosed.rawValue {
			sessionClosed.send(true)
			return
		}
		log.i("Received text message: \(text)")
	}
}

enum CompanionMessageType: String {
	case statusUpdate = "device.state.update"
	case rotationStart = "device.orientation.start"
	case rotationFinish = "device.orientation.finish"
	case logMessage = "device.log.message"
	case sessionWillExpire = "session_will_expire"
	case sessionClosed = "session_closed"
}

struct CompanionMessage: Codable {
	let type: String
}

struct CompanionStatusUpdateMessage: Codable {
	enum StateType: String, Codable {
		case FAILED
		case INTERRUPTED
		case OFFLINE
		case LAUNCH
		case VIDEO
		case BOOTED
		case UI
		case INPUT
		case ONLINE
		case CLOSING
	}

	struct VauleType: Codable {
		let state: StateType
	}

	let value: VauleType
}

struct CompanionSessionWillExpireMessage: Codable {
	
}

struct CompanionSessionClosedMessage: Codable {
	
}

struct CompanionRotationStartMessage: Codable {
	
}

struct CompanionRotationFinishMessage: Codable {
	
}

struct CompanionLogMessage: Codable {
	let message: String
}

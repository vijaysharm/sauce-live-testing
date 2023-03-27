//
//  SauceAlternativeIoConnection.swift
//  LiveTesting
//

import Foundation
import Combine

class SauceAlternativeIoConnection {
	private let log = Logger.make(tag: SauceAlternativeIoConnection.self)
	
	public let connectionClosed = PassthroughSubject<Bool, Never>()
	public let screenshot = PassthroughSubject<Data, Never>()
	
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
			self.log.d("AlternativeIo socket opened")
		}.store(in: &subscriptions)
		delegate.didClose.sink {
			// self.log.d("urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)")
			self.isClosed = true
			guard $0 != .normalClosure else { return }
			self.log.d("AlternativeIo connection closed because \($0)")
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
	
	func send(message: String) {
		guard !isClosed else { return }
		webSocket.socket.send(.string(message)) { error in
			if let error = error {
				self.log.e("Failed to send webSocket message: \(error)")
			}
		}
	}
	
	private func read() {
		webSocket.socket.receive { result in
			switch result {
			case .failure(let error):
				self.log.e("Failed to receive AlternativeIo message", error)
				self.isClosed = true
				self.connectionClosed.send(true)
			case .success(let message):
				switch message {
				case .string(let text):
					self.log.d("Received string message: \(text)")
					break
				case .data(let data):
//					self.log.d("Received binary message: \(data.count)")
					self.screenshot.send(data)
					break
				@unknown default:
					fatalError()
				}
			}
			
			if self.isClosed { return }
			self.read() // Weird qwerk of URLSessionWebSocketTask.. https://appspector.com/blog/websockets-in-ios-using-urlsessionwebsockettask
		}
	}
}

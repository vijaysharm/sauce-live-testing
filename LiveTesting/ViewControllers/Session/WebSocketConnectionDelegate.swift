//
//  WebSocketConnectionDelegate.swift
//  LiveTesting
//

import Foundation
import Combine

class WebSocketConnectionDelegate: NSObject {
	public let didOpen = CurrentValueSubject<Bool, Never>(false)
	public let didClose = PassthroughSubject<URLSessionWebSocketTask.CloseCode, Never>()
	
	override init() {
		super.init()
	}
}

extension WebSocketConnectionDelegate: URLSessionWebSocketDelegate {
	func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
		didOpen.send(true)
	}

	func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
		didClose.send(closeCode)
	}
}

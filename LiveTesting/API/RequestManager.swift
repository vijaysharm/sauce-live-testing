//
//  RequestManager.swift
//  LiveTesting
//

import Foundation

struct SauceWebSocket {
	let socket: URLSessionWebSocketTask
	let parser: DataParserProtocol
}

protocol RequestManagerProtocol {
	func perform<T: Decodable>(
		_ request: RequestProtocol,
		_ authentication: AuthenticationData?
	) async -> Result<T, NetworkError>
	
	func authenticate<T: Decodable>(
		_ request: RequestProtocol
	) async -> Result<T, NetworkError>
	
	func makeWebsocket(
		_ request: WebSocketRequestProtocol,
		_ authentication: AuthenticationData?,
		_ delegate: URLSessionWebSocketDelegate
	) -> Result<SauceWebSocket, NetworkError>
}

final class RequestManager: RequestManagerProtocol {
	private let log = Logger.make(tag: RequestManager.self)
	let apiManager: APIManagerProtocol
	let parser: DataParserProtocol
	
	init(
		apiManager: APIManagerProtocol,
		parser: DataParserProtocol
	) {
		self.apiManager = apiManager
		self.parser = parser
	}

	func perform<T: Decodable>(
		_ request: RequestProtocol,
		_ authentication: AuthenticationData?
	) async -> Result<T, NetworkError> {
		guard let authentication = authentication else {
			return .failure(.unauthorized)
		}

		let result = await apiManager.perform(request, authentication)
		switch result {
		case .success(let data):
			if request.debug {
				let text = String(data: data, encoding: .utf8)
				log.d("request (success): \(request)\nresponse:\n\(text ?? "Can't parse")")
			}
			
			do {
				let decoded: T = try parser.parse(data: data)
				return .success(decoded)
			} catch {
				log.e("request (parse failure): \(request)", error)
				return .failure(.parseFailure(error: error))
			}
		case .failure(let error):
			switch error {
			case .requestFailure(let request, let data):
				let text = String(data: data, encoding: .utf8)
				log.d("request (failed): code (\(request.statusCode)\n\(request)\nresponse:\n\(text ?? "Can't parse")")
				break
			default:
				log.e("request (failed): \(request)", error)
				break
			}
			return .failure(error)
		}
	}
	
	func authenticate<T: Decodable>(_ request: RequestProtocol) async -> Result<T, NetworkError> {
		let result = await apiManager.perform(request, nil)
		switch result {
		case .success(let data):
			if request.debug {
				let text = String(data: data, encoding: .utf8)
				log.d("authenticate: \(text ?? "Can't parse")")
			}
			do {
				let decoded: T = try parser.parse(data: data)
				return .success(decoded)
			} catch {
				log.e("authenticate (parse failure): \(request)", error)
				return .failure(.parseFailure(error: error))
			}
		case .failure(let error):
			switch error {
			case .requestFailure(_, let data):
				let text = String(data: data, encoding: .utf8)
				log.e("authenticate (failed): \(request)\nresponse:\n\(text ?? "Can't parse")")
				break
			default:
				log.e("authenticate (failed): \(request)", error)
				break
			}
			return .failure(error)
		}
	}
	
	func makeWebsocket(
		_ request: WebSocketRequestProtocol,
		_ authentication: AuthenticationData?,
		_ delegate: URLSessionWebSocketDelegate
	) -> Result<SauceWebSocket, NetworkError> {
		let result = apiManager.makeWebsocket(request, authentication, delegate)
		switch result {
		case .failure(let error):
			return .failure(error)
		case .success(let websocket):
			return .success(SauceWebSocket(socket: websocket, parser: parser))
		}
	}
}

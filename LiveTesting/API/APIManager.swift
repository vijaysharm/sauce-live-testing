//
//  APIManager.swift
//  LiveTesting
//

import Foundation

protocol APIManagerProtocol {
	func perform(
		_ request: RequestProtocol,
		_ authentication: AuthenticationData?
	) async -> Result<Data, NetworkError>
	
	func makeWebsocket(
		_ request: WebSocketRequestProtocol,
		_ authentication: AuthenticationData?,
		_ delegate: URLSessionWebSocketDelegate
	) -> Result<URLSessionWebSocketTask, NetworkError>
}

class APIManager: APIManagerProtocol {
	private let validSuccessCodes = [200, 201, 204]
	private let urlSession: URLSession

	init(urlSession: URLSession = URLSession.shared) {
		self.urlSession = urlSession
	}

	func perform(
		_ request: RequestProtocol,
		_ authentication: AuthenticationData?
	) async -> Result<Data, NetworkError> {
		do {
			let (data, response) = try await urlSession.data(
				for: request.createURLRequest(authentication: authentication)
			)

			guard let httpResponse = response as? HTTPURLResponse else {
				return .failure(.invalidServerResponse)
			}
			
			guard validSuccessCodes.contains(httpResponse.statusCode) else {
				return .failure(.requestFailure(response: httpResponse, data: data))
			}

			return .success(data)
		} catch {
			return .failure(.unknownFailure(error: error))
		}
	}
	
	func makeWebsocket(
		_ request: WebSocketRequestProtocol,
		_ authentication: AuthenticationData?,
		_ delegate: URLSessionWebSocketDelegate
	) -> Result<URLSessionWebSocketTask, NetworkError> {
		do {
			let urlSession = URLSession(configuration: self.urlSession.configuration, delegate: delegate, delegateQueue: OperationQueue())
			let req = try request.createWebSocketRequest(authentication: authentication)
			return .success(urlSession.webSocketTask(with: req))
		} catch {
			return .failure(.unknownFailure(error: error))
		}
	}
}


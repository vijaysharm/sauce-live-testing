//
//  DeviceWebSocketRequest.swift
//  LiveTesting
//

import Foundation

protocol WebSocketRequestProtocol: RequestProtocol {
	
}

extension WebSocketRequestProtocol {
	func createWebSocketRequest(authentication: AuthenticationData?) throws -> URLRequest {
		var components = URLComponents()
		components.scheme = "wss"
		components.host = host(authentication: authentication)
		components.path = path
		
		guard let url = components.url else { throw  NetworkError.invalidURL }
		
		return URLRequest(url: url)
	}
}

enum DeviceWebSocketRequest: WebSocketRequestProtocol {
	case companion(session: SauceDeviceSession)
	case alternativeIo(session: SauceDeviceSession)
	
	func host(authentication: AuthenticationData?) -> String {
		guard let auth = authentication else { return "" }
		return "api.\(auth.endpoint).saucelabs.com"
	}
	
	var path: String {
		switch self {
		case .companion(let session):
			return "/v1/rdc/socket/companion/\(session.deviceSessionId)"
		case .alternativeIo(let session):
			return "/v1/rdc/socket/alternativeIo/\(session.deviceSessionId)"
		}
	}
	
	var requestType: RequestType {
		.GET
	}
}

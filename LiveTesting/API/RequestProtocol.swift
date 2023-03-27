//
//  RequestProtocol.swift
//  LiveTesting
//

import Foundation

protocol RequestProtocol {
	func host(authentication: AuthenticationData?) -> String
	func urlParams(authentication: AuthenticationData?) -> [(String, String)]
	
	var path: String { get }
	var requestType: RequestType { get }
	var headers: [String: String] { get }
	var params: [String: Any] { get }
	var body: Data? { get }
	
	var addAuthorizationToken: Bool { get }
	var debug: Bool { get }
}

// MARK: - Default RequestProtocol
extension RequestProtocol {
	var debug: Bool {
		false
	}
	
	var addAuthorizationToken: Bool {
		true
	}

	var params: [String: Any] {
		[:]
	}

	func urlParams(authentication: AuthenticationData?) -> [(String, String)] {
		[]
	}

	var headers: [String: String] {
		[:]
	}
	
	var body: Data? {
		if params.isEmpty {
			return nil
		}
		
		return try? JSONSerialization.data(withJSONObject: params)
	}

	func createURLRequest(authentication: AuthenticationData?) throws -> URLRequest {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host(authentication: authentication)
		components.path = path

		let urlParams = urlParams(authentication: authentication)
		if !urlParams.isEmpty {
			components.queryItems = urlParams.map { URLQueryItem(name: $0.0, value: $0.1) }
		}

		guard let url = components.url else { throw  NetworkError.invalidURL }

		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = requestType.rawValue

		if !headers.isEmpty {
		  urlRequest.allHTTPHeaderFields = headers
		}

		if addAuthorizationToken {
			if let authentication = authentication {
				urlRequest.setValue(
					"Bearer \(authentication.token.tokenId)",
					forHTTPHeaderField: "Authorization"
				)
			}
		}

		urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

		if let body = body {
			urlRequest.httpBody = body
		}

		return urlRequest
	}
}

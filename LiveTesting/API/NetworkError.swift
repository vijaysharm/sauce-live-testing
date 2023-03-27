//
//  NetworkError.swift
//  LiveTesting
//

import Foundation

public enum NetworkError: LocalizedError {
	case invalidServerResponse
	case invalidURL
	case unauthorized
	case requestFailure(response: HTTPURLResponse, data: Data)
	case unknownFailure(error: Error)
	case parseFailure(error: Error)
	
	public var errorDescription: String? {
		switch self {
		case .invalidServerResponse:
			return "The server returned an invalid response."
		case .invalidURL:
			return "URL string is malformed."
		case .unauthorized:
			return "This request requires authentication"
		case .unknownFailure(let error):
			return "Request failed for unknown reasons: \(error.localizedDescription)"
		case .requestFailure(_, _):
			return "Request failure"
		case .parseFailure(let error):
			return "Request failed to parse: \(error)"
		}
	}
}

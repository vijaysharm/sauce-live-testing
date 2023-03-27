//
//  AuthTokenRequest.swift
//  LiveTesting
//

import Foundation

enum AuthTokenRequest: RequestProtocol {
	case auth(username: String, password: String)
	case logout
	// case session: https://api.us-west-1.saucelabs.com/v1/auth/session/
	// case me: https://api.us-west-1.saucelabs.com/team-management/v1/users/me/ <-- has allowed_regions  ["us-west-1"]
	
	func host(authentication: AuthenticationData?) -> String {
		switch self {
		case .auth:
			return "accounts.saucelabs.com"
		case .logout:
			guard let auth = authentication else { return "" }
			return "api.\(auth.endpoint).saucelabs.com"
		}
	}
	
	var path: String {
		switch self {
		case .auth:
			return "/am/json/realms/root/realms/authtree/authenticate"
		case .logout:
			return "/encore/api/logout"
		}
	}

	var headers: [String : String] {
		switch self {
		case let .auth(username, password):
			return [
				"X-OpenAM-Username": username,
				"X-OpenAM-Password": password,
				"x-requested-with" : "XMLHttpRequest",
				"Cache-Control": "no-store",
			]
		default:
			return [:]
		}
	}

	var addAuthorizationToken: Bool {
		switch self {
		case .auth:
			return false
		case .logout:
			return true
		}
	}

	var requestType: RequestType {
		.POST
	}
}

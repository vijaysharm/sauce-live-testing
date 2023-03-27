//
//  AppRequest.swift
//  LiveTesting
//

import Foundation

enum AppRequest: RequestProtocol {
	case groups(page: Int, perPage: Int)
	case files(groupId: Int, page: Int, perPage: Int)
	
	func host(authentication: AuthenticationData?) -> String {
		guard let auth = authentication else { return "" }
		return "api.\(auth.endpoint).saucelabs.com"
	}
	
	var path: String {
		switch self {
		case .files:
			return "/v1/storage/files"
		case .groups:
			return "/v1/storage/groups"
		}
	}
	
	var headers: [String : String] {
		[
			"Cache-Control": "no-cache",
			"Content-Type": "application/json;charset=UTF-8",
			"X-Requested-With": "XMLHttpRequest",
		]
	}
	
	func urlParams(authentication: AuthenticationData?) -> [(String, String)] {
		switch self {
		case .files(let groupId, let page, let perPage):
			return [
				("kind", "ios"),
				("kind", "android"),
				("group_id", "\(groupId)"),
				("page", "\(page)"),
				("per_page", "\(perPage)")
			]
		case .groups(let page, let perPage):
			return [
				("kind", "ios"),
				("kind", "android"),
				("page", "\(page)"),
				("per_page", "\(perPage)")
			]
		}
	}
	
	var addAuthorizationToken: Bool {
		true
	}

	var requestType: RequestType {
		.GET
	}
	
	var debug: Bool {
		false
	}
}

//
//  AuthenticationData.swift
//  LiveTesting
//

import Foundation

struct AuthenticationData: Codable {
	let token: AuthenticationToken
	let username: String
	let password: String
}

extension AuthenticationData {
	var location: String {
		// TODO: token.successUrl = https://app.eu-central-1.saucelabs.com
		"US"
	}
	
	var endpoint: String {
		"us-west-1"
	}
	
	var isValid: Bool {
		return
			!username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
			!password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
			!token.tokenId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
}

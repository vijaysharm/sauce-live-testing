//
//  AuthenticationToken.swift
//  LiveTesting
//

import Foundation

struct AuthenticationToken: Codable {
	let tokenId: String
	let successUrl: String
	let realm: String
}

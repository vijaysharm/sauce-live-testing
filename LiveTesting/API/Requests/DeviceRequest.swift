//
//  DeviceRequest.swift
//  LiveTesting
//

import Foundation

enum DeviceRequest: RequestProtocol {
	case devices
	case available
	case metadata
	case setStarred(devices: [String])
	
	func host(authentication: AuthenticationData?) -> String {
		guard let auth = authentication else { return "" }
		return "api.\(auth.endpoint).saucelabs.com"
	}
	
	var path: String {
		switch self {
		case .devices:
			return "/v1/rdc/devices/filtered"
		case .available:
			return "/v1/rdc/devices/availableDescriptors"
		case .metadata:
			return "/encore/api/page_metadata/manual"
		case .setStarred:
			return "/encore/api/page_metadata/manual/real_devices_starred_by_composite_id"
		}
	}
	
	func urlParams(authentication: AuthenticationData?) -> [(String, String)] {
		guard let auth = authentication else { return [] }
		switch self {
		case .devices:
			return [("dataCenterId", auth.location)]
		case .available:
			let ts = Date().timeIntervalSince1970 * 1000
			return [("ts", "\(ts)")]
		default:
			return []
		}
	}
	
	var headers: [String : String] {
		switch self {
		case .setStarred:
			return [
				"Cache-Control": "no-cache",
				"Content-Type": "application/json;charset=UTF-8",
				"X-Requested-With": "XMLHttpRequest",
			]
		default:
			return [:]
		}
	}
	
	var body: Data? {
		switch self {
		case .setStarred(let devices):
			return try? JSONSerialization.data(withJSONObject: devices)
		default:
			if params.isEmpty {
				return nil
			}
			
			return try? JSONSerialization.data(withJSONObject: params)
		}
	}
	
	var addAuthorizationToken: Bool {
		true
	}
	
	var requestType: RequestType {
		switch self {
		case .setStarred:
			return .PUT
		default:
			return .GET
		}
	}
}

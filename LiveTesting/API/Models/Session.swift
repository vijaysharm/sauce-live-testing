//
//  Session.swift
//  LiveTesting
//

import Foundation

struct WebRtcCredentials: Codable {
	let accessToken: String
	let roomName: String
}

struct SauceDeviceSession: Codable {
	let deviceSessionId: String
	let testReportId: String
	let webRtcCredentials: WebRtcCredentials
}

struct SauceDeviceSessionDescriptor: Codable {
	let dataCenterId: String
	let deviceSessionId: String
	let deviceDescriptorId: String
	let host: String
	let os: String
	let resolutionWidth: Int
	let resolutionHeight: Int
	let orientation: String
	let hasOnScreenButtons: Bool
	let hardwareButtonsAvailable: Bool
	let viewOnly: Bool
	let alternativeIoEnabled: Bool
	let multiTouchSupported: Bool
	let phoneNumber: String?
}

enum SauceStatusResponse: String, Codable {
	case SUCCESS
	case ERROR
}

struct SauceSessionDescriptor: Codable {
	let status: SauceStatusResponse
	let error: String?
	let deviceSessionDescriptor: SauceDeviceSessionDescriptor
}

struct SauceOpenUrlOnDeviceResponse: Codable {
	let status: SauceStatusResponse
	let error: String?
	let errorMessage: String?
}

enum SauceInstallationStatus: String, Codable {
	case pending = "PENDING"
	case finished = "FINISHED"
	case error = "ERROR"
}

struct SauceInstallationProgressResponse: Codable {
	let id: String
	let status: SauceInstallationStatus
}

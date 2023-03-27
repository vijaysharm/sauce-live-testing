//
//  SessionRequest.swift
//  LiveTesting
//

import Foundation

enum DeviceOrientation: String {
	case PORTRAIT = "PORTRAIT"
	case LANDSCAPE = "LANDSCAPE"
}

enum SessionRequest: RequestProtocol {
	case open(device: SauceDevice)
	case openWithNativeApp(group: AppGroup, file: AppGroupFile, device: SauceDevice)
	case deviceDescriptor(session: SauceDeviceSession)
	case openUrl(session: SauceDeviceSession, url: URL)
	case install(session: SauceDeviceSession, group: AppGroup, file: AppGroupFile)
	case installationStatus(session: SauceDeviceSession, id: String)
	case orientation(_ orientation: DeviceOrientation, session: SauceDeviceSession)
	case close(session: SauceDeviceSession)
	case paste(text: String, session: SauceDeviceSession)
	case relaunchApp(session: SauceDeviceSession)
	
	func host(authentication: AuthenticationData?) -> String {
		guard let auth = authentication else { return "" }
		return "api.\(auth.endpoint).saucelabs.com"
	}
	
	var path: String {
		switch self {
		case .open(let device):
			return "/v1/rdc/manual/devices/\(device.descriptorId)/open"
		case .openWithNativeApp(_, _, let device):
			return "/v1/rdc/manual/devices/\(device.descriptorId)/openWithNativeApp"
		case .deviceDescriptor(let session):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)"
		case .openUrl(let session, _):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/openUrl"
		case .install(let session, _, _):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/app-storage/installations"
		case .installationStatus(let session, let id):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/app-storage/installations/\(id)"
		case .orientation(_, let session):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/orientation"
		case .close(let session):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/close"
		case .paste(_, let session):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/pasteText"
		case .relaunchApp(let session):
			return "/v1/rdc/manual/sessions/\(session.deviceSessionId)/apps/current/relaunch"
		}
	}
	
	var headers: [String : String] {
		switch self {
		case .open, .openWithNativeApp, .install, .close:
			return [
				"Cache-Control": "no-cache",
				"Content-Type": "application/json;charset=UTF-8",
				"X-Requested-With": "XMLHttpRequest",
			]
		case .openUrl, .paste, .relaunchApp:
			return [
				"Cache-Control": "no-cache",
				"Content-Type": "text/plain",
				"X-Requested-With": "XMLHttpRequest",
			]
		default:
			return [:]
		}
	}
	
	var requestType: RequestType {
		switch self {
		case .deviceDescriptor, .installationStatus:
			return .GET
		default:
			return .POST
		}
	}
	
	var params: [String : Any] {
		switch self {
		case .open:
			return [
				// TODO: Should be based on the OS version. Also, we should filter devices we dont support
				"webRtcEnabled": true
			]
		case .openWithNativeApp(let group, let file, _):
			return [
				"appStorageAppId": file.id,
				"appStorageGroupId": group.id,
				"webRtcEnabled": true
			]
		case .install(_, let group, let file):
			return [
				"appStorageId": file.id,
				"groupId": group.id,
				"launch": true,
			]
		default:
			return [:]
		}
	}
	
	var body: Data? {
		switch self {
		case .orientation(let orientation, _):
			return orientation.rawValue.data(using: .utf8)
		case .paste(let text, _):
			return text.data(using: .utf8)
		case .openUrl(_, let url):
			return url.absoluteString.data(using: .utf8)
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
}

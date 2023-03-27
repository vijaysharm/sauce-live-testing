//
//  AppGroups.swift
//  LiveTesting
//

import Foundation

struct AppSettingProxy: Codable {
	let host: String
	let port: Int
}

struct AppSettingResigning: Codable {
	let imageInjection: Bool
	let groupDirectory: Bool
	let biometrics: Bool
	let sysAlertsDelay: Bool
	let networkCapture: Bool
}

struct AppSettingInstrumentation: Codable {
	let imageInjection: Bool
	let bypassScreenshotRestriction: Bool
	let biometrics: Bool
	let networkCapture: Bool
}

struct AppSettings: Codable {
	let proxy: AppSettingProxy
	let audioCapture: Bool
	let proxyEnabled: Bool
	let lang: String
//	let orientation":null,
	let setupDeviceLock: Bool
	
	// Android specific
	let instrumentationEnabled: Bool?
	let instrumentation: AppSettingInstrumentation?
	
	// iOS specific
	let resigningEnabled: Bool?
	let resigning: AppSettingResigning?
}

struct AppAccess: Codable {
	let teamIds: [String]
	let orgIds: [String]
}

struct AppGroupFileOwner: Codable {
	let id: String
	let orgId: String
}

struct AppGroupFileMetadata: Codable {
	let identifier: String
	let name: String
	let version: String?
	let icon: String?
	let isTestRunner: Bool
	
	// Android Specific
	let versionCode: Int?
	let minSdk: Int?
	let targetSdk: Int?
	let testRunnerClass: String?
	
	// iOS Specific
	let shortVersion: String?
	let isSimulator: Bool?
	let minOs: String?
	let targetOs: String?
	let testRunnerPluginPath: String?
	let deviceFamily: [String]?
	
	var versionString: String {
		if let version = version {
			if let versionCode = versionCode {
				return "\(version) (\(versionCode))"
			} else if let shortVersion = shortVersion {
				return "\(shortVersion) (\(version))"
			} else {
				return "\(version)"
			}
		} else {
			if let versionCode = versionCode {
				return "\(versionCode)"
			} else if let shortVersion = shortVersion {
				return "\(shortVersion)"
			} else {
				return ""
			}
		}
	}
}

struct AppGroup: Codable {
	let id: Int
	let name: String // Usually package name
	let count: Int
	let recent: AppGroupFile
	let access: AppAccess
	let settings: AppSettings
}

extension AppGroup: Hashable {
	static func == (lhs: AppGroup, rhs: AppGroup) -> Bool {
		lhs.id == rhs.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct AppLinks: Codable {
	let prev: String?
	let next: String?
	let `self`: String?
}

struct AppGroups: Codable {
	let items: [AppGroup]
	let links: AppLinks
	let page: Int
	let perPage: Int
	let totalItems: Int
}

struct AppGroupFile: Codable {
	let id: String
	let owner: AppGroupFileOwner
	let name: String // file name
	let uploadTimestamp: Int
	let etag: String
	let kind: String
	let groupId: Int
	let size: Int64
	let description: String?
	let metadata: AppGroupFileMetadata
	
	var isAndroid: Bool {
		get {
			kind == "android"
		}
	}
	
	var isIos: Bool {
		get {
			kind == "ios"
		}
	}
}

extension AppGroupFile: Hashable {
	static func == (lhs: AppGroupFile, rhs: AppGroupFile) -> Bool {
		lhs.id == rhs.id
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct AppGroupFiles: Codable {
	let items: [AppGroupFile]
	let links: AppLinks
	let page: Int
	let perPage: Int
	let totalItems: Int
}

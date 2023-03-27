//
//  FilterableDevices.swift
//  LiveTesting
//

import Foundation

struct RecentConfigurations: Codable {
	/*
	 {
		"virtualDeviceConfiguration":{
		   "browserDisplay":"Android GoogleAPI Emulator",
		   "res":null,
		   "osDisplay":"android",
		   "version":"12.0",
		   "osVersionDisplay":"12.0",
		   "device":"Android GoogleAPI Emulator",
		   "browserVersionDisplay":"",
		   "os":"Linux",
		   "browser":"android"
		},
		"url":"https://www.saucedemo.com/",
		"browserConfiguration":{
		   "os":"Windows 11",
		   "res":"1440x900",
		   "osVersionDisplay":"Windows 11",
		   "version":"109",
		   "osDisplay":"Windows 11",
		   "device":"Windows 11",
		   "browserVersionDisplay":"109",
		   "browserDisplay":"Google Chrome",
		   "browser":"chrome"
		},
		"tunnel":null,
		"realDeviceConfiguration":{
		   "descriptorId":"Google_Pixel_6_pro_13_real_us",
		   "internalStorageSize":128000,
		   "ramSize":12288,
		   "resolutionWidth":1440,
		   "cpuType":"ARM",
		   "apiLevel":33,
		   "formFactor":"PHONE",
		   "cpuFrequency":1803,
		   "resolutionHeight":3120,
		   "compositeId":"US_Google_Pixel_6_pro_13_real_us",
		   "phoneNumber":null,
		   "includedInPlan":true,
		   "isPrivate":null,
		   "dpiName":"xxhdpi",
		   "manufacturers":[
			  "Google"
		   ],
		   "freeOfCharge":false,
		   "abiType":"arm64-v8a",
		   "dataCenterId":"US",
		   "connectivity":[
			  "WIFI"
		   ],
		   "cloudType":"PUBLIC",
		   "osVersion":"13",
		   "hasOnScreenButtons":true,
		   "name":"Google Pixel 6 Pro",
		   "cpuCores":8,
		   "pixelsPerPoint":null,
		   "modelNumber":"Pixel 6 Pro",
		   "screenSize":6.71,
		   "os":"ANDROID",
		   "dpi":512
		},
		"deviceType":"REAL_DEVICE",
		"testType":"WEB",
		"id":"ITxKIKaMz"
	 }
	*/
//	let browserConfiguration: String? /* TODO */
//	let virtualDeviceConfiguration: String? /* TODO */
//	let realDeviceConfiguration: String? /* TODO */
//	let url: String?
//	let tunnel: String? /* TODO */
}

enum MetadataItem: Codable {
	enum CodingKeys: String, CodingKey {
		case key
		case value
	}
	case realDeviceStarredByCompositeId(devices: [String])
	case recentConfigs // ([RecentConfigurations])
	case unknown(key: String)
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let key = try container.decode(String.self, forKey: .key)
		if key == "recent_configs" {
			self = .recentConfigs
		} else if key == "real_devices_starred_by_composite_id" {
			let value = try container.decode([String].self, forKey: .value)
			self = .realDeviceStarredByCompositeId(devices: value)
		} else {
			self = .unknown(key: key)
		}
	}
	
	func encode(to encoder: Encoder) throws {
		fatalError("TODO: encode(to) Not implemented")
	}
}

struct Metadata: Codable {
	let items: [MetadataItem]
}

struct StarredDeviceItem: Codable {
	let key: String
	let value: [String]
}

struct StarredDevice: Codable {
	let item: StarredDeviceItem
}

struct FilterableDevices: Codable {
	let facets: FilterableDeviceFacets
	let entities: [FilterableDevice]
}

struct FilterableDeviceFacets: SearchableFacets, Codable {
	let cloudType: [String: Int]
	let dataCenter: [String: Int]
	let dpi: [String: Int]
	let screenSize: [String: Int]
	let os: [String: Int]
	let osVersion: [String: Int]
	let formFactor: [String: Int]
	let resolution: [String: Int]
	let manufacturer: [String: Int]
}

struct FilterableDevice: Codable {
	let abiType: String
	let apiLevel: Int
	let cloudType: String
	let compositeId: String
	let cpuType: String
	let cpuCores: Int
	let cpuFrequency: Int
	let dataCenterId: String
	let descriptorId: String
	let dpi: Int
	let dpiName: String
	let freeOfCharge: Bool
	let formFactor: String
	let hasOnScreenButtons: Bool
	let includedInPlan: Bool
	let internalStorageSize: Int
	let modelNumber: String
	let name: String
	let os: String
	let osVersion: String
	let ramSize: Int
	let resolutionHeight: Int
	let resolutionWidth: Int
	let screenSize: Float
	let supportsAppiumWebAppTesting: Bool
	let phoneNumber: String?
	let manufacturers: [String]
	let connectivity: [String]
}

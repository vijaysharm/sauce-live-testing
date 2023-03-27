//
//  Copyright (C) 2020 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

protocol SettingOptions: CaseIterable, Codable, Equatable {
	var title: String { get }
}

enum TrackPriority: String, SettingOptions {
	case serverDefault
	case low
	case standard
	case high
	
	var title: String {
		switch self {
		case .serverDefault: return "Server Default"
		case .low: return "Low"
		case .standard: return "Standard"
		case .high: return "High"
		}
	}
}

enum TrackSwitchOffMode: String, SettingOptions {
	case serverDefault
	case disabled
	case detected
	case predicted
	
	var title: String {
		switch self {
		case .serverDefault: return "Server Default"
		case .disabled: return "Disabled"
		case .detected: return "Detected"
		case .predicted: return "Predicted"
		}
	}
}

enum ClientTrackSwitchOffControl: String, SettingOptions {
	case sdkDefault
	case auto
	case manual
	
	var title: String {
		switch self {
		case .sdkDefault: return "SDK Default"
		case .auto: return "Auto"
		case .manual: return "Manual"
		}
	}
}


enum VideoContentPreferencesMode: String, SettingOptions {
	case sdkDefault
	case auto
	case manual
	
	var title: String {
		switch self {
		case .sdkDefault: return "SDK Default"
		case .auto: return "Auto"
		case .manual: return "Manual"
		}
	}
}

enum VideoCodec: String, SettingOptions {
	case auto
	case h264
	case vp8
	case vp8Simulcast

	var title: String {
		switch self {
		case .auto: return "Auto"
		case .h264: return "H.264"
		case .vp8: return "VP8"
		case .vp8Simulcast: return "VP8 Simulcast"
		}
	}
}

enum BandwidthProfileMode: String, SettingOptions {
	case serverDefault
	case collaboration
	case grid
	case presentation
	
	var title: String {
		switch self {
		case .serverDefault: return "Server Default"
		case .collaboration: return "Collaboration"
		case .grid: return "Grid"
		case .presentation: return "Presentation"
		}
	}
}

//
//  Strings.swift
//  LiveTesting
//

import Foundation

public extension String {
	var loc: String {
		return NSLocalizedString(self, tableName: nil, bundle: .main, value: self, comment: "")
	}
}

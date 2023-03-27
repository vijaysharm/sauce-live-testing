//
//  Fonts.swift
//  LiveTesting
//

import UIKit

extension UIFont {
	static func proximaRegular(size: CGFloat) -> UIFont {
		return readFont(name: "ProximaNova-Regular", size: size)
	}
	
	static func proximaSemiBold(size: CGFloat) -> UIFont {
		return readFont(name: "ProximaNova-Semibold", size: size)
	}
	
	static func proximaLight(size: CGFloat) -> UIFont {
		return readFont(name: "ProximaNova-Light", size: size)
	}
	
	private static func readFont(name: String, size: CGFloat) -> UIFont {
		guard let font = UIFont(name: name, size: size) else {
			fatalError()
		}
		
		return font
	}
}

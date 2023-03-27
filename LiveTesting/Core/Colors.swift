//
//  Colors.swift
//  LiveTesting
//

import UIKit

extension UIColor {
	class sauceLabs {
		static var lightGrey: UIColor { UIColor(named: "lightGrey")! }
		static var grey: UIColor { UIColor(named: "grey")! }
		static var white: UIColor { UIColor(named: "white")! }
		static var black: UIColor { UIColor(named: "black")! }
		static var blueGrey: UIColor { UIColor(named: "blueGrey")! }
		static var blue: UIColor { UIColor(named: "blue")! }
		
		static var red: UIColor { UIColor.from(hex: "#a94442")! }
		static var lightRed: UIColor { UIColor.from(hex: "#ebccd1")! }
		static var lightestRed: UIColor { UIColor.from(hex: "#f2dede")! }
		static var darkGrey: UIColor { UIColor.from(hex: "#6d7584")! }
		static var green: UIColor { UIColor.from(hex: "#3DDC91")! }
		static var lightGreen: UIColor { UIColor.from(hex: "#DFEEE9")! }
	}
	
	static func from(hex input: String) -> UIColor? {
		let hex = input.replacingOccurrences(of:"#", with: "")
		switch hex.count {
		case 3: // #RGB
			let alpha = 1.0
			let red = colorComponentFrom(hex, start: 0, length: 1)
			let green = colorComponentFrom(hex, start: 1, length: 1)
			let blue = colorComponentFrom(hex, start: 2, length: 1)
			return UIColor(red: red, green: green, blue: blue, alpha: alpha)
		case 4: // #ARGB
			let alpha = colorComponentFrom(hex, start: 0, length: 1)
			let red = colorComponentFrom(hex, start: 1, length: 1)
			let green = colorComponentFrom(hex, start: 2, length: 1)
			let blue = colorComponentFrom(hex, start: 3, length: 1)
			return UIColor(red: red, green: green, blue: blue, alpha: alpha)
		case 6: // #RRGGBB
			let alpha = 1.0
			let red = colorComponentFrom(hex, start: 0, length: 2)
			let green = colorComponentFrom(hex, start: 2, length: 2)
			let blue = colorComponentFrom(hex, start: 4, length: 2)
			return UIColor(red: red, green: green, blue: blue, alpha: alpha)
		case 8: // #AARRGGBB
			let alpha = colorComponentFrom(hex, start: 0, length: 2)
			let red = colorComponentFrom(hex, start: 2, length: 2)
			let green = colorComponentFrom(hex, start: 4, length: 2)
			let blue = colorComponentFrom(hex, start: 6, length: 2)
			return UIColor(red: red, green: green, blue: blue, alpha: alpha)
		default:
			return nil
		}
	}
	
	private static func colorComponentFrom(_ input: String, start: Int, length: Int) -> CGFloat {
		let startIndex = input.index(input.startIndex, offsetBy: start)
		let endIndex = input.index(input.startIndex, offsetBy: (start + length))
		let range = startIndex..<endIndex

		let substring = String(input[range])
		let fullHex = length == 2 ? substring : "\(input)\(input)"
		
		var rgbValue: UInt64 = 0
		Scanner(string: fullHex).scanHexInt64(&rgbValue)

		return CGFloat(Double(rgbValue) / 255.0)
	}
}

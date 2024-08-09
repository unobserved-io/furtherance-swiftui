//
//  ColorHex.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 19.07.2024.
//

import SwiftUI

public extension Color {
	init?(hex: String?) {
		guard let hexString = hex else { return nil }

		let r, g, b, a: CGFloat
		let cleanedHex = hexString.cleanedHex

		if cleanedHex.count == 8 {
			let scanner = Scanner(string: cleanedHex)
			var hexNumber: UInt64 = 0

			if scanner.scanHexInt64(&hexNumber) {
				r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
				g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
				b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
				a = CGFloat((hexNumber & 0x0000_00FF) >> 0) / 255

				self.init(.sRGB, red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
				return
			} else {
				return nil
			}
		} else if cleanedHex.count == 6 {
			let scanner = Scanner(string: cleanedHex)
			var hexNumber: UInt64 = 0

			if scanner.scanHexInt64(&hexNumber) {
				r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
				g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
				b = CGFloat((hexNumber & 0x0000FF) >> 0) / 255

				self.init(.sRGB, red: Double(r), green: Double(g), blue: Double(b))
				return
			} else {
				return nil
			}
		} else {
			return nil
		}
	}

	var hex: String? {
		let colorString = "\(self)"
		if let colorHex = colorString.isHex() {
			return colorHex.cleanedHex
		} else {
			var colorArray: [String] = colorString.components(separatedBy: " ")
			if colorArray.count < 3 { colorArray = colorString.components(separatedBy: ", ") }
			if colorArray.count < 3 { colorArray = colorString.components(separatedBy: ",") }
			if colorArray.count < 3 { colorArray = colorString.components(separatedBy: " - ") }
			if colorArray.count < 3 { colorArray = colorString.components(separatedBy: "-") }

			colorArray = colorArray.filter { colorElement in
				(!colorElement.isEmpty) && (String(colorElement).replacingOccurrences(of: ".", with: "").rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil)
			}

			if colorArray.count == 3 {
				var r = Float(colorArray[0]) ?? 1
				var g = Float(colorArray[1]) ?? 1
				var b = Float(colorArray[2]) ?? 1

				if r < 0.0 { r = 0.0 }
				if g < 0.0 { g = 0.0 }
				if b < 0.0 { b = 0.0 }

				if r > 1.0 { r = 1.0 }
				if g > 1.0 { g = 1.0 }
				if b > 1.0 { b = 1.0 }

				return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)).cleanedHex
			} else if colorArray.count == 4 {
				var r = Float(colorArray[0]) ?? 1
				var g = Float(colorArray[1]) ?? 1
				var b = Float(colorArray[2]) ?? 1
				var a = Float(colorArray[3]) ?? 1

				if r < 0.0 { r = 0.0 }
				if g < 0.0 { g = 0.0 }
				if b < 0.0 { b = 0.0 }
				if a < 0.0 { a = 0.0 }

				if r > 1.0 { r = 1.0 }
				if g > 1.0 { g = 1.0 }
				if b > 1.0 { b = 1.0 }
				if a > 1.0 { a = 1.0 }

				return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255)).cleanedHex
			} else {
				return nil
			}
		}
	}
}

public extension String {
	func isHex() -> Bool {
		/// Check if the String is a hex.
		if (cleanedHex.count == 6) || (cleanedHex.count == 8), replacingOccurrences(of: "#", with: "").isAlphanumeric() {
			true
		} else {
			false
		}
	}

	func isHex() -> String? {
		/// Check if the String is a hex and return an alphanumeric string of the hex back. This is the hex without special characters.
		if isHex() {
			cleanedHex
		} else {
			nil
		}
	}

	var cleanedHex: String {
		replacingOccurrences(of: "#", with: "").trimmingCharacters(in: CharacterSet.alphanumerics.inverted).cleanedString.uppercased()
	}
}

extension String {
	func isAlphanumeric() -> Bool {
		!isEmpty && (range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil)
	}

	var cleanedString: String {
		var cleanedString = self

		cleanedString = cleanedString.replacingOccurrences(of: "á", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "ä", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "â", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "à", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "æ", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "ã", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "å", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "ā", with: "a")
		cleanedString = cleanedString.replacingOccurrences(of: "ç", with: "c")
		cleanedString = cleanedString.replacingOccurrences(of: "é", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "ë", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "ê", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "è", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "ę", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "ė", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "ē", with: "e")
		cleanedString = cleanedString.replacingOccurrences(of: "í", with: "i")
		cleanedString = cleanedString.replacingOccurrences(of: "ï", with: "i")
		cleanedString = cleanedString.replacingOccurrences(of: "ì", with: "i")
		cleanedString = cleanedString.replacingOccurrences(of: "î", with: "i")
		cleanedString = cleanedString.replacingOccurrences(of: "į", with: "i")
		cleanedString = cleanedString.replacingOccurrences(of: "ī", with: "i")
		cleanedString = cleanedString.replacingOccurrences(of: "j́", with: "j")
		cleanedString = cleanedString.replacingOccurrences(of: "ñ", with: "n")
		cleanedString = cleanedString.replacingOccurrences(of: "ń", with: "n")
		cleanedString = cleanedString.replacingOccurrences(of: "ó", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "ö", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "ô", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "ò", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "õ", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "œ", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "ø", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "ō", with: "o")
		cleanedString = cleanedString.replacingOccurrences(of: "ú", with: "u")
		cleanedString = cleanedString.replacingOccurrences(of: "ü", with: "u")
		cleanedString = cleanedString.replacingOccurrences(of: "û", with: "u")
		cleanedString = cleanedString.replacingOccurrences(of: "ù", with: "u")
		cleanedString = cleanedString.replacingOccurrences(of: "ū", with: "u")

		return cleanedString
	}
}

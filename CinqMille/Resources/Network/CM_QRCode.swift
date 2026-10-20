//
//  CM_QRCode.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import UIKit
import CoreImage.CIFilterBuiltins

enum CM_QRCode {
	
	private static let joinPrefix = "cinqmille://join/"
	
	static func payload(forCode code:String) -> String {
		joinPrefix + code.uppercased()
	}
	
	/// Extrait un code partie depuis un QR (payload app ou code brut à 6 caractères).
	static func code(fromScanned string:String) -> String? {
		
		let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
		
		if trimmed.lowercased().hasPrefix(joinPrefix) {
			let code = String(trimmed.dropFirst(joinPrefix.count))
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.uppercased()
			return isValidCode(code) ? code : nil
		}
		
		let code = trimmed.uppercased()
		return isValidCode(code) ? code : nil
	}
	
	static func isValidCode(_ code:String) -> Bool {
		code.count == 6 && code.allSatisfy { $0.isLetter || $0.isNumber }
	}
	
	static func image(forCode code:String, size:CGFloat = 200) -> UIImage? {
		
		let data = Data(payload(forCode: code).utf8)
		guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
		filter.setValue(data, forKey: "inputMessage")
		filter.setValue("M", forKey: "inputCorrectionLevel")
		
		guard let output = filter.outputImage else { return nil }
		
		let scale = size / output.extent.width
		let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
		let context = CIContext()
		
		guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
		return UIImage(cgImage: cgImage)
	}
}

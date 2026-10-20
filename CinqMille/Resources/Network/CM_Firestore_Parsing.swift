//
//  CM_Firestore_Parsing.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import Foundation
import FirebaseFirestore

enum CM_Firestore_Parsing {
	
	/// Firestore renvoie souvent des NSNumber / Int64 : `as? Int` échoue silencieusement.
	static func int(_ value:Any?) -> Int? {
		
		if let value = value as? Int { return value }
		if let value = value as? Int64 { return Int(value) }
		if let value = value as? Double { return Int(value) }
		if let value = value as? NSNumber { return value.intValue }
		return nil
	}
	
	static func int(_ value:Any?, default defaultValue:Int) -> Int {
		int(value) ?? defaultValue
	}
	
	static func intArray(_ value:Any?) -> [Int] {
		
		guard let array = value as? [Any] else { return [] }
		return array.compactMap { int($0) }
	}
	
	static func bool(_ value:Any?, default defaultValue:Bool = false) -> Bool {
		
		if let value = value as? Bool { return value }
		if let value = value as? NSNumber { return value.boolValue }
		return defaultValue
	}
	
	static func double(_ value:Any?) -> Double? {
		
		if let value = value as? Double { return value }
		if let value = value as? Int { return Double(value) }
		if let value = value as? Int64 { return Double(value) }
		if let value = value as? NSNumber { return value.doubleValue }
		return nil
	}
}

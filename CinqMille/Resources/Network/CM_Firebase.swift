//
//  CM_Firebase.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import Foundation
import FirebaseCore

public enum CM_Firebase {
	
	private(set) static var isConfigured:Bool = false
	
	/// Configure Firebase si `GoogleService-Info.plist` est présent dans le bundle.
	@discardableResult
	public static func configure() -> Bool {
		
		guard !isConfigured else { return true }
		
		guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
			
			print("[CM_Firebase] GoogleService-Info.plist introuvable — multijoueur réseau désactivé.")
			return false
		}
		
		FirebaseApp.configure()
		isConfigured = true
		return true
	}
}

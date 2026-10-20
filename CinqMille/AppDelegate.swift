//
//  AppDelegate.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import UserMessagingPlatform

@main
public class AppDelegate: UIResponder, UIApplicationDelegate {
	
	public var window: UIWindow?
	
	public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		CM_Firebase.configure()
		CM_Ads.shared.start()
		CM_Audio.shared.playMusic()
		
		return true
	}
	
	public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		
		let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
		configuration.delegateClass = SceneDelegate.self
		return configuration
	}
	
	func startConsentFlow() {
		
		let parameters = RequestParameters()
		parameters.isTaggedForUnderAgeOfConsent = false
		
		ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
			
			ConsentForm.load { [weak self] form, _ in
				
				if ConsentInformation.shared.consentStatus == .required, let form = form {
					
					form.present(from: UI.MainController) { [weak self] _ in
						
						self?.afterConsentFlow()
					}
				}
				else {
					
					self?.afterConsentFlow()
				}
			}
		}
	}
	
	/// Après le consentement : pub d'ouverture si obtenu, puis demande du nom si besoin
	func afterConsentFlow() {
		
		if ConsentInformation.shared.consentStatus == .obtained {
			
			NotificationCenter.post(.updateAds)
			presentAdAppOpening()
		}
		else {
			
			askPlayerNameIfNeeded()
		}
	}
	
	private func presentAdAppOpening() {
		
		CM_Ads.shared.presentAppOpening { [weak self] in
			
			self?.askPlayerNameIfNeeded()
		}
	}
	
	private func askPlayerNameIfNeeded() {
		
		guard CM_Player.current.name == nil else { return }
		
		let alertController:CM_Player_Name_Alert_ViewController = .init()
		alertController.backgroundView.isUserInteractionEnabled = false
		alertController.present()
	}
}

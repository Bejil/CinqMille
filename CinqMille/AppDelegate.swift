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
		
		CM_Ads.shared.start()
		
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.backgroundColor = Colors.Background.Application
		
		let navigationController:CM_NavigationController = .init(rootViewController: CM_Menu_ViewController())
		navigationController.navigationBar.prefersLargeTitles = false
		window?.rootViewController = navigationController
		
		window?.makeKeyAndVisible()
		
		CM_Audio.shared.playMusic()
		
		let parameters = RequestParameters()
		parameters.isTaggedForUnderAgeOfConsent = false
		
		ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] _ in
			
			ConsentForm.load { [weak self] form, _ in
				
				if ConsentInformation.shared.consentStatus == .required {
					
					form?.present(from: UI.MainController)
				}
				else if ConsentInformation.shared.consentStatus == .obtained {
					
					self?.afterLaunch()
					NotificationCenter.post(.updateAds)
				}
			}
		}
		
		return true
	}
	
	public func applicationWillEnterForeground(_ application: UIApplication) {
		
		afterLaunch()
	}
	
	private func presentAdAppOpening() {
		
		CM_Ads.shared.presentAppOpening {
			
			let currentPlayer:CM_Player = .current
			if currentPlayer.name == nil {
				
				let alertController:CM_Player_Name_Alert_ViewController = .init()
				alertController.backgroundView.isUserInteractionEnabled = false
				alertController.present()
			}
		}
	}
	
	private func afterLaunch() {
		
		presentAdAppOpening()
	}
}

//
//  SceneDelegate.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	
	public var window: UIWindow?
	
	public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let window = UIWindow(windowScene: windowScene)
		window.backgroundColor = Colors.Background.Application
		
		let splashscreenViewController:CM_Splashscreen_ViewController = .init()
		splashscreenViewController.completion = { [weak self] in
			
			let navigationController:CM_NavigationController = .init(rootViewController: CM_Menu_ViewController())
			navigationController.navigationBar.prefersLargeTitles = false
			self?.window?.rootViewController = navigationController
			
			(UIApplication.shared.delegate as? AppDelegate)?.startConsentFlow()
		}
		
		window.rootViewController = splashscreenViewController
		window.makeKeyAndVisible()
		
		self.window = window
		
		if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
			appDelegate.window = window
		}
	}
	
	public func sceneWillEnterForeground(_ scene: UIScene) {
		
		(UIApplication.shared.delegate as? AppDelegate)?.afterConsentFlow()
	}
}

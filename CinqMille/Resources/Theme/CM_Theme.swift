//
//  CM_Theme.swift
//  CinqMille
//
//  Created by BLIN Michael on 11/01/2026.
//

import UIKit

public enum CM_ThemeType: Int, CaseIterable {
	
	case classic = 0
	case ocean = 1
	case sunset = 2
	case forest = 3
	case neon = 4
	
	public var name: String {
		
		switch self {
		case .classic:
			return String(key: "settings.theme.classic")
		case .ocean:
			return String(key: "settings.theme.ocean")
		case .sunset:
			return String(key: "settings.theme.sunset")
		case .forest:
			return String(key: "settings.theme.forest")
		case .neon:
			return String(key: "settings.theme.neon")
		}
	}
}

public class CM_Theme {
	
	// MARK: - Singleton
	
	public static let shared: CM_Theme = .init()
	
	// MARK: - Properties
	
	public var current: CM_ThemeType {
		
		didSet {
			UserDefaults.set(current.rawValue, .theme)
			NotificationCenter.post(.themeDidChange)
		}
	}
	
	// MARK: - Colors
	
	public var primary: UIColor {
		
		switch current {
		case .classic:
			return UIColor(red: 0xEF/255, green: 0x44/255, blue: 0x44/255, alpha: 1.0) // Rouge vif
		case .ocean:
			return UIColor(red: 0x00/255, green: 0x96/255, blue: 0xC7/255, alpha: 1.0) // Bleu océan
		case .sunset:
			return UIColor(red: 0xFF/255, green: 0x6B/255, blue: 0x35/255, alpha: 1.0) // Orange coucher de soleil
		case .forest:
			return UIColor(red: 0x2D/255, green: 0x6A/255, blue: 0x4F/255, alpha: 1.0) // Vert forêt
		case .neon:
			return UIColor(red: 0x8B/255, green: 0x5C/255, blue: 0xF6/255, alpha: 1.0) // Violet néon
		}
	}
	
	public var secondary: UIColor {
		
		switch current {
		case .classic:
			return UIColor(red: 0x10/255, green: 0xB9/255, blue: 0x81/255, alpha: 1.0) // Vert émeraude
		case .ocean:
			return UIColor(red: 0x48/255, green: 0xCA/255, blue: 0xE4/255, alpha: 1.0) // Turquoise
		case .sunset:
			return UIColor(red: 0xE8/255, green: 0x3F/255, blue: 0x6F/255, alpha: 1.0) // Rose fuchsia
		case .forest:
			return UIColor(red: 0x52/255, green: 0xB7/255, blue: 0x88/255, alpha: 1.0) // Vert menthe
		case .neon:
			return UIColor(red: 0x06/255, green: 0xD6/255, blue: 0xA0/255, alpha: 1.0) // Cyan néon
		}
	}
	
	public var tertiary: UIColor {
		
		switch current {
		case .classic:
			return UIColor(red: 0xD4/255, green: 0xAF/255, blue: 0x37/255, alpha: 1.0) // Or
		case .ocean:
			return UIColor(red: 0xFF/255, green: 0x85/255, blue: 0x5E/255, alpha: 1.0) // Corail
		case .sunset:
			return UIColor(red: 0xFF/255, green: 0xC1/255, blue: 0x07/255, alpha: 1.0) // Jaune doré
		case .forest:
			return UIColor(red: 0xF4/255, green: 0xA2/255, blue: 0x61/255, alpha: 1.0) // Ambre
		case .neon:
			return UIColor(red: 0xFF/255, green: 0x00/255, blue: 0x80/255, alpha: 1.0) // Magenta néon
		}
	}
	
	// MARK: - Background Colors
	
	public var applicationBackground: UIColor {
		
		switch current {
		case .classic:
			return dynamicColor(light: UIColor(red: 0xFE/255, green: 0xFF/255, blue: 0xFF/255, alpha: 1.0),
								dark: UIColor(red: 0x21/255, green: 0x21/255, blue: 0x21/255, alpha: 1.0))
		case .ocean:
			return dynamicColor(light: UIColor(red: 0xE8/255, green: 0xF4/255, blue: 0xF8/255, alpha: 1.0),
								dark: UIColor(red: 0x0A/255, green: 0x1A/255, blue: 0x2E/255, alpha: 1.0))
		case .sunset:
			return dynamicColor(light: UIColor(red: 0xFF/255, green: 0xF5/255, blue: 0xEB/255, alpha: 1.0),
								dark: UIColor(red: 0x1A/255, green: 0x0A/255, blue: 0x1E/255, alpha: 1.0))
		case .forest:
			return dynamicColor(light: UIColor(red: 0xF0/255, green: 0xF7/255, blue: 0xF4/255, alpha: 1.0),
								dark: UIColor(red: 0x0F/255, green: 0x1F/255, blue: 0x17/255, alpha: 1.0))
		case .neon:
			return dynamicColor(light: UIColor(red: 0xF5/255, green: 0xF0/255, blue: 0xFF/255, alpha: 1.0),
								dark: UIColor(red: 0x0D/255, green: 0x0D/255, blue: 0x1A/255, alpha: 1.0))
		}
	}
	
	public var viewBackground: UIColor {
		
		switch current {
		case .classic:
			return dynamicColor(light: UIColor(red: 0xFE/255, green: 0xFF/255, blue: 0xFF/255, alpha: 1.0),
								dark: UIColor(red: 0x21/255, green: 0x21/255, blue: 0x21/255, alpha: 1.0))
		case .ocean:
			return dynamicColor(light: UIColor(red: 0xF0/255, green: 0xF9/255, blue: 0xFF/255, alpha: 1.0),
								dark: UIColor(red: 0x12/255, green: 0x2A/255, blue: 0x40/255, alpha: 1.0))
		case .sunset:
			return dynamicColor(light: UIColor(red: 0xFF/255, green: 0xFA/255, blue: 0xF5/255, alpha: 1.0),
								dark: UIColor(red: 0x25/255, green: 0x12/255, blue: 0x2A/255, alpha: 1.0))
		case .forest:
			return dynamicColor(light: UIColor(red: 0xF5/255, green: 0xFB/255, blue: 0xF8/255, alpha: 1.0),
								dark: UIColor(red: 0x15/255, green: 0x2A/255, blue: 0x20/255, alpha: 1.0))
		case .neon:
			return dynamicColor(light: UIColor(red: 0xFA/255, green: 0xF5/255, blue: 0xFF/255, alpha: 1.0),
								dark: UIColor(red: 0x12/255, green: 0x12/255, blue: 0x20/255, alpha: 1.0))
		}
	}
	
	// MARK: - Navigation Colors
	
	public var navigationTitle: UIColor {
		
		return dynamicColor(light: UIColor(red: 0x21/255, green: 0x21/255, blue: 0x21/255, alpha: 1.0),
							dark: UIColor.white)
	}
	
	public var navigationButton: UIColor {
		
		return dynamicColor(light: UIColor(red: 0x21/255, green: 0x21/255, blue: 0x21/255, alpha: 1.0),
							dark: UIColor.white)
	}
	
	// MARK: - Content Colors
	
	public var contentTitle: UIColor {
		
		return primary
	}
	
	public var contentText: UIColor {
		
		return dynamicColor(light: UIColor(red: 0x21/255, green: 0x21/255, blue: 0x21/255, alpha: 1.0),
							dark: UIColor.white)
	}
	
	// MARK: - Button Colors
	
	public var buttonBadge: UIColor {
		
		return UIColor(red: 0xFF/255, green: 0x3B/255, blue: 0x30/255, alpha: 1.0)
	}
	
	public var buttonPrimaryBackground: UIColor { return primary }
	public var buttonPrimaryContent: UIColor { return .white }
	
	public var buttonSecondaryBackground: UIColor { return secondary }
	public var buttonSecondaryContent: UIColor { return .white }
	
	public var buttonTertiaryBackground: UIColor { return tertiary }
	public var buttonTertiaryContent: UIColor { return .white }
	
	public var buttonDeleteBackground: UIColor {
		return UIColor(red: 0xE6/255, green: 0x39/255, blue: 0x46/255, alpha: 1.0)
	}
	public var buttonDeleteContent: UIColor { return .white }
	
	public var buttonNavigationBackground: UIColor { return .clear }
	public var buttonNavigationContent: UIColor { return primary }
	
	public var buttonTextBackground: UIColor { return .clear }
	public var buttonTextContent: UIColor {
		return dynamicColor(light: UIColor(red: 0x21/255, green: 0x21/255, blue: 0x21/255, alpha: 1.0),
							dark: UIColor.white)
	}
	
	// MARK: - Init
	
	private init() {
		
		if let savedTheme = UserDefaults.get(.theme) as? Int,
		   let theme = CM_ThemeType(rawValue: savedTheme) {
			current = theme
		} else {
			current = .classic
		}
	}
	
	// MARK: - Helpers
	
	private func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
		
		return UIColor { traitCollection in
			return traitCollection.userInterfaceStyle == .dark ? dark : light
		}
	}
}

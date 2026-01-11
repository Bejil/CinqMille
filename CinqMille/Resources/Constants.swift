//
//  Constants.swift
//  CurseCounter
//
//  Created by BLIN Michael on 28/11/2025.
//

import UIKit

public struct InAppPurchase {
	
	static let AlertCapping:Int = 5
	static let Identifiers:[String] = [RemoveAds]
	static let RemoveAds:String = "com.michaelblin.cinqmille.removeAds"
}

public struct UI {
	
	static var MainController :UIViewController {
		
		return UIApplication.shared.topMostViewController()!
	}
	
	public static let Margins:CGFloat = 15.0
	public static let CornerRadius:CGFloat = 18.0
}

public struct Colors {
	
	public static var Primary:UIColor { CM_Theme.shared.primary }
	public static var Secondary:UIColor { CM_Theme.shared.secondary }
	public static var Tertiary:UIColor { CM_Theme.shared.tertiary }
	
	public struct Background {
		
		public static var Application:UIColor { CM_Theme.shared.applicationBackground }
		public static var View:UIColor { CM_Theme.shared.viewBackground }
	}
	
	public struct Navigation {
		
		public static var Title:UIColor { CM_Theme.shared.navigationTitle }
		public static var Button:UIColor { CM_Theme.shared.navigationButton }
	}
	
	public struct Content {
		
		public static var Title:UIColor { CM_Theme.shared.contentTitle }
		public static var Text:UIColor { CM_Theme.shared.contentText }
	}
	
	public struct Button {
		
		public static var Badge:UIColor { CM_Theme.shared.buttonBadge }
		
		public struct Primary {
			
			public static var Background:UIColor { CM_Theme.shared.buttonPrimaryBackground }
			public static var Content:UIColor { CM_Theme.shared.buttonPrimaryContent }
		}
		
		public struct Secondary {
			
			public static var Background:UIColor { CM_Theme.shared.buttonSecondaryBackground }
			public static var Content:UIColor { CM_Theme.shared.buttonSecondaryContent }
		}
		
		public struct Tertiary {
			
			public static var Background:UIColor { CM_Theme.shared.buttonTertiaryBackground }
			public static var Content:UIColor { CM_Theme.shared.buttonTertiaryContent }
		}
		
		public struct Delete {
			
			public static var Background:UIColor { CM_Theme.shared.buttonDeleteBackground }
			public static var Content:UIColor { CM_Theme.shared.buttonDeleteContent }
		}
		
		public struct Navigation {
			
			public static var Background:UIColor { CM_Theme.shared.buttonNavigationBackground }
			public static var Content:UIColor { CM_Theme.shared.buttonNavigationContent }
		}
		
		public struct Text {
			
			public static var Background:UIColor { CM_Theme.shared.buttonTextBackground }
			public static var Content:UIColor { CM_Theme.shared.buttonTextContent }
		}
	}
}

public struct Fonts {
	
	private struct Name {
		
		static let Regular:String = "TTInterphasesProTrl-Rg"
		static let Bold:String = "TTInterphasesProTrl-Bd"
		static let Black:String = "GROBOLD"
	}
	
	public static let Size:CGFloat = 13
	
	public struct Navigation {
		
		public struct Title {
			
			public static let Large:UIFont = UIFont(name: Name.Black, size: Fonts.Size+25)!
			public static let Small:UIFont = UIFont(name: Name.Black, size: Fonts.Size+12)!
		}
		
		public static let Button:UIFont = UIFont(name: Name.Black, size: Fonts.Size)!
	}
	
	public struct Content {
		
		public struct Text {
			
			public static let Regular:UIFont = UIFont(name: Name.Regular, size: Fonts.Size)!
			public static let Bold:UIFont = UIFont(name: Name.Bold, size: Fonts.Size)!
		}
		
		public struct Button {
			
			public static let Title:UIFont = UIFont(name: Name.Black, size: Fonts.Size+4)!
			public static let Subtitle:UIFont = UIFont(name: Name.Regular, size: Fonts.Size)!
		}
		
		public struct Title {
			
			public static let H1:UIFont = UIFont(name: Name.Black, size: Fonts.Size+30)!
			public static let H2:UIFont = UIFont(name: Name.Black, size: Fonts.Size+11)!
			public static let H3:UIFont = UIFont(name: Name.Black, size: Fonts.Size+8)!
			public static let H4:UIFont = UIFont(name: Name.Black, size: Fonts.Size+5)!
		}
	}
}

public struct Ads {
	
	public struct FullScreen {
		
		static let AppOpening:String = "ca-app-pub-9540216894729209/9198157494"
		
		public struct Game {
			
			static let Start:String = "ca-app-pub-9540216894729209/4332843627"
			static let End:String = "ca-app-pub-9540216894729209/6393381823"
		}
	}
	
	public struct Banner {
		
		static let Menu:String = "ca-app-pub-9540216894729209/2936001476"
		static let Game:String = "ca-app-pub-9540216894729209/8747565504"
	}
}

//
//  CM_Switch.swift
//  CinqMille
//
//  Created by BLIN Michael on 03/01/2026.
//

import UIKit

public class CM_Switch: UISwitch {
	
	private var themeObserver: NSObjectProtocol?
	
	public override init(frame: CGRect) {
		
		super.init(frame: frame)
		
		applyTheme()
		
		themeObserver = NotificationCenter.default.addObserver(forName: .themeDidChange, object: nil, queue: .main) { [weak self] _ in
			self?.applyTheme()
		}
	}
	
	required init?(coder: NSCoder) {
		
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		
		if let observer = themeObserver {
			NotificationCenter.default.removeObserver(observer)
		}
	}
	
	private func applyTheme() {
		
		UIView.animate(withDuration: 0.3) {
			self.onTintColor = Colors.Primary
		}
	}
}

//
//  CM_SegmentedControl.swift
//  CinqMille
//
//  Created by BLIN Michael on 03/01/2026.
//

import UIKit
import SnapKit

public class CM_SegmentedControl : UISegmentedControl {
	
	private var themeObserver: NSObjectProtocol?
	
	public override init(frame: CGRect) {
		
		super.init(frame: frame)
		self.configure()
	}
	
	public override init(items: [Any]?) {
		
		super.init(items: items)
		self.configure()
	}
	
	required init?(coder: NSCoder) {
		
		super.init(coder: coder)
		self.configure()
	}
	
	deinit {
		
		if let observer = themeObserver {
			NotificationCenter.default.removeObserver(observer)
		}
	}
	
	private func configure() {
		
		applyTheme()
		
		snp.makeConstraints { make in
			make.height.equalTo(3*UI.Margins)
		}
		
		themeObserver = NotificationCenter.default.addObserver(forName: .themeDidChange, object: nil, queue: .main) { [weak self] _ in
			self?.applyTheme()
		}
	}
	
	private func applyTheme() {
		
		UIView.animate(withDuration: 0.3) {
			self.selectedSegmentTintColor = Colors.Primary
			self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Content.Text], for: .normal)
			self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: Fonts.Content.Text.Bold], for: .selected)
		}
	}
}

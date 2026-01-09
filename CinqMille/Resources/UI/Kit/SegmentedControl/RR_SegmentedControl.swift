//
//  CM_SegmentedControl.swift
//  CinqMille
//
//  Created by BLIN Michael on 03/01/2026.
//

import UIKit
import SnapKit

public class CM_SegmentedControl : UISegmentedControl {
	
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
	
	private func configure() {
		
		selectedSegmentTintColor = Colors.Primary
		setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Colors.Content.Text], for: .normal)
		setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: Fonts.Content.Text.Bold], for: .selected)
		
		snp.makeConstraints { make in
			make.height.equalTo(3*UI.Margins)
		}
	}
}

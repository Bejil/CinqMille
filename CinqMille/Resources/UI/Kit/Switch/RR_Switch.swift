//
//  CM_Switch.swift
//  CinqMille
//
//  Created by BLIN Michael on 03/01/2026.
//

import UIKit

public class CM_Switch: UISwitch {
	
	public override init(frame: CGRect) {
		
		super.init(frame: frame)
		
		onTintColor = Colors.Primary
	}
	
	required init?(coder: NSCoder) {
		
		fatalError("init(coder:) has not been implemented")
	}
}

//
//  RR_Player_Name_Alert_ViewController.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class RR_Player_Name_Alert_ViewController : RR_Alert_ViewController {
	
	public var completion:(()->Void)?
	private lazy var textField:RR_TextField = {
		
		$0.placeholder = String(key: "settings.playerName.alert.placeholder")
		$0.autocorrectionType = .no
		$0.autocapitalizationType = .words
		return $0
		
	}(RR_TextField())
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		let currentPlayer:RR_Player = .current
		
		title = String(key: "settings.playerName.alert.title")
		add(String(key: "settings.playerName.alert.content"))
		
		textField.text = currentPlayer.name
		add(textField)
		
		let confirmButton = addButton(title: String(key: "settings.playerName.alert.button")) { [weak self] _ in
			
			let name = self?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
			
			if let name = name, !name.isEmpty {
				
				currentPlayer.name = name
				currentPlayer.save()
				
				self?.close(self?.completion)
			}
		}
		confirmButton.isEnabled = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
		
		textField.addAction(.init(handler: { [weak self] _ in
			
			let text = self?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			confirmButton.isEnabled = !text.isEmpty
			
		}), for: .editingChanged)
	}
	
	@MainActor required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func present(as style: RR_Alert_ViewController.Style = .Alert, withAnimation animated: Bool = true, _ completion: (() -> Void)? = nil) {
		
		super.present(as: style, withAnimation: animated, completion)
		
		UIApplication.wait { [weak self] in
		
			self?.textField.becomeFirstResponder()
		}
	}
}

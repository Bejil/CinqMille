//
//  CM_Label.swift
//  LettroLine
//
//  Created by BLIN Michael on 12/02/2025.
//

import Foundation
import UIKit

public class CM_Label : UILabel {
	
	public enum ThemeColorType {
		case text
		case title
		case custom
	}
	
	private var themeObserver: NSObjectProtocol?
	private var themeColorType: ThemeColorType = .text
	
	public var contentInsets:UIEdgeInsets = .zero {
		
		didSet {
			
			layoutIfNeeded()
		}
	}
	public override var intrinsicContentSize: CGSize {
		
		get {
			
			var size: CGSize = super.intrinsicContentSize
			size.width += contentInsets.left + contentInsets.right
			size.height += contentInsets.top + contentInsets.bottom
			return size
		}
	}
	
	public override var textColor: UIColor! {
		
		didSet {
			
			// Détecter automatiquement le type de couleur du thème utilisée
			if textColor == Colors.Content.Title {
				themeColorType = .title
			} else if textColor == Colors.Content.Text {
				themeColorType = .text
			} else {
				themeColorType = .custom
			}
		}
	}
	
	convenience init(_ string:String?) {
		
		self.init(frame: .zero)
		
		text = string
	}
	
	public override init(frame: CGRect) {
		
		super.init(frame: frame)
		
		numberOfLines = 0
		font = Fonts.Content.Text.Regular
		textColor = Colors.Content.Text
		themeColorType = .text
		
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
		
		let currentType = themeColorType
		
		UIView.animate(withDuration: 0.3) {
			switch currentType {
			case .text:
				self.textColor = Colors.Content.Text
			case .title:
				self.textColor = Colors.Content.Title
			case .custom:
				break // Ne pas changer les couleurs personnalisées
			}
		}
		
		// Restaurer le type après l'animation (car le didSet l'a changé)
		themeColorType = currentType
	}
	
	public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
		
		let insetRect = bounds.inset(by: contentInsets)
		let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
		let invertedInsets = UIEdgeInsets(top: -contentInsets.top, left: -contentInsets.left, bottom: -contentInsets.bottom, right: -contentInsets.right)
		return textRect.inset(by: invertedInsets)
	}
	
	public override func drawText(in rect: CGRect) {
		
		super.drawText(in: rect.inset(by: contentInsets))
	}
	
	public func set(font:UIFont? = nil, color:UIColor? = nil, string:String) {
		
		if let text = text {
			
			var attributes:[NSAttributedString.Key : Any] = .init()
			
			if let font = font {
				
				attributes[.font] = font
			}
			
			if let color = color {
				
				attributes[.foregroundColor] = color
			}
			
			let attributedString:NSMutableAttributedString = .init(attributedString: attributedText ?? .init(string: text))
			
			text.ranges(of: string).forEach({ range in
				
				attributedString.addAttributes(attributes, range: NSRange(range, in: text))
			})
			
			attributedText = attributedString
		}
	}
}

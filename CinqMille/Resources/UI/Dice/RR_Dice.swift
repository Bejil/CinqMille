//
//  CM_Dice.swift
//  CinqMille
//
//  Created by BLIN Michael on 04/01/2026.
//

import UIKit
import SnapKit

public class CM_Dice : UIView {
	
	// MARK: - Properties
	
	public var value:Int = 1 {
		didSet {
			updateDots()
		}
	}
	
	public var isLocked:Bool = false
	
	/// Le numéro du lancer où ce dé a été verrouillé (nil si pas encore verrouillé)
	public var lockedAtRoll:Int? = nil
	
	/// Position originale du dé dans le conteneur (pour la restaurer lors de la désélection)
	public var originalPosition:CGPoint? = nil
	
	private let dotsContainer:UIView = .init()
	private var dotViews:[UIView] = []
	
	// MARK: - Init
	
	public override init(frame: CGRect) {
		
		super.init(frame: frame)
		
		setupUI()
	}
	
	required init?(coder: NSCoder) {
		
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Setup
	
	private func setupUI() {
		
		backgroundColor = .white
		layer.cornerRadius = UI.CornerRadius
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = .init(width: 0, height: -UI.Margins/3)
		layer.shadowOpacity = 0.35
		layer.shadowRadius = UI.CornerRadius/3
		
		addSubview(dotsContainer)
		dotsContainer.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(UI.Margins/2)
		}
		
		snp.makeConstraints { make in
			make.size.equalTo(4*UI.Margins)
		}
		
		updateDots()
	}
	
	// MARK: - Update
	
	private func updateDots() {
		
		dotViews.forEach { $0.removeFromSuperview() }
		dotViews.removeAll()
		
		let dotSize:CGFloat = 8
		let dotColor:UIColor = .black
		
		let positions = dotPositions(for: value)
		
		for position in positions {
			
			let dot = UIView()
			dot.backgroundColor = dotColor
			dot.layer.cornerRadius = dotSize / 2
			dotsContainer.addSubview(dot)
			dot.snp.makeConstraints { make in
				make.width.height.equalTo(dotSize)
				make.centerX.equalToSuperview().multipliedBy(position.x)
				make.centerY.equalToSuperview().multipliedBy(position.y)
			}
			dotViews.append(dot)
		}
	}
	
	private func dotPositions(for value:Int) -> [(x:CGFloat, y:CGFloat)] {
		
		switch value {
		case 1:
			return [(1.0, 1.0)]
		case 2:
			return [(0.5, 0.5), (1.5, 1.5)]
		case 3:
			return [(0.5, 0.5), (1.0, 1.0), (1.5, 1.5)]
		case 4:
			return [(0.5, 0.5), (1.5, 0.5), (0.5, 1.5), (1.5, 1.5)]
		case 5:
			return [(0.5, 0.5), (1.5, 0.5), (1.0, 1.0), (0.5, 1.5), (1.5, 1.5)]
		case 6:
			return [(0.5, 0.5), (1.5, 0.5), (0.5, 1.0), (1.5, 1.0), (0.5, 1.5), (1.5, 1.5)]
		default:
			return [(1.0, 1.0)]
		}
	}
	
	// MARK: - Roll Animation
	
	public func roll(_ feedback:Bool = true, completion: (() -> Void)? = nil) {
		
		guard !isLocked else {
			completion?()
			return
		}
		
		let duration:TimeInterval = 0.5
		let rotations:Int = Int.random(in: 3...5)
		let finalValue = Int.random(in: 1...6)
		
		// Animation de rotation avec changement de valeurs
		let animationSteps = rotations * 4
		let stepDuration = duration / Double(animationSteps)
		
		for step in 0..<animationSteps {
			
			DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) { [weak self] in
				
				if feedback {
					
					CM_Feedback.shared.make(.On)
				}
				
				guard let self = self else { return }
				
				// Valeurs aléatoires pendant le roulement
				if step < animationSteps - 1 {
					self.value = Int.random(in: 1...6)
				} else {
					self.value = finalValue
				}
				
				// Animation de rebond
				UIView.animate(withDuration: stepDuration * 0.5, delay: 0, options: [.curveEaseInOut]) {
					
					self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).rotated(by: .pi * CGFloat(step) / 3)
					
				} completion: { _ in
					
					UIView.animate(withDuration: stepDuration * 0.5, delay: 0, options: [.curveEaseInOut]) {
						
						self.transform = .identity
					}
				}
				
				if step == animationSteps - 1 {
					
					DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration) {
						completion?()
					}
				}
			}
		}
	}
}


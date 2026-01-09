//
//  CM_Splashscreen_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 09/01/2026.
//

import UIKit
import SnapKit

public class CM_Splashscreen_ViewController : CM_ViewController {
	
	public var completion:(()->Void)?
	private lazy var stackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 2*UI.Margins
		
		let firstDice:CM_Dice = .init()
		firstDice.transform = .init(rotationAngle: .pi/3)
		firstDice.roll()
		
		let secondDice:CM_Dice = .init()
		secondDice.transform = .init(rotationAngle: .pi/3)
		secondDice.roll()
		
		let dicesView:UIView = .init()
		dicesView.addSubview(secondDice)
		dicesView.addSubview(firstDice)
		
		secondDice.snp.makeConstraints { make in
			make.top.right.equalToSuperview()
		}
		
		firstDice.snp.makeConstraints { make in
			make.left.bottom.equalToSuperview()
			make.top.equalTo(secondDice.snp.centerY)
			make.right.equalTo(secondDice.snp.centerX)
		}
		
		let dicesContainerView:UIView = .init()
		dicesContainerView.addSubview(dicesView)
		dicesView.snp.makeConstraints { make in
			make.top.bottom.centerX.equalToSuperview()
		}
		$0.addArrangedSubview(dicesContainerView)
		
		let titleLabel:CM_Label = .init([String(key: "menu.title.0"),String(key: "menu.title.1")].joined(separator: " "))
		titleLabel.font = Fonts.Content.Title.H1
		titleLabel.textColor = Colors.Content.Title
		titleLabel.set(color: Colors.Content.Text, string: String(key: "menu.title.1"))
		titleLabel.textAlignment = .center
		$0.addArrangedSubview(titleLabel)
		
		let subtitleLabel:CM_Label = .init(String(key: "menu.subtitle"))
		subtitleLabel.textAlignment = .center
		$0.addArrangedSubview(subtitleLabel)
		
		return $0
		
	}(UIStackView())
	
	public override func loadView() {
		
		super.loadView()
		
		let containerStackView:UIStackView = .init(arrangedSubviews: [stackView])
		containerStackView.axis = .horizontal
		containerStackView.alignment = .center
		view.addSubview(containerStackView)
		containerStackView.snp.makeConstraints { make in
			make.edges.equalTo(view.safeAreaLayoutGuide).inset(UI.Margins)
		}
	}
	
	public override func viewDidAppear(_ animated: Bool) {
		
		super.viewDidAppear(animated)
		
		stackView.animate()
		
		UIApplication.wait(3.0) { [weak self] in
			
			self?.dismiss(self?.completion)
		}
	}
}

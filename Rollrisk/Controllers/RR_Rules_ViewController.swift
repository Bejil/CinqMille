//
//  RR_Rules_ViewController.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class RR_Rules_ViewController : RR_ViewController {
	
	private let rules = RR_Rules.shared
	
	private lazy var stackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 2.5*UI.Margins
		return $0
		
	}(UIStackView())
	
	public override func loadView() {
		
		super.loadView()
		
		isModal = true
		title = String(key: "rules.title")
		
		let scrollView:RR_ScrollView = .init()
		scrollView.showsVerticalScrollIndicator = false
		scrollView.isCentered = true
		scrollView.addSubview(stackView)
		stackView.snp.makeConstraints { make in
			make.top.bottom.left.equalToSuperview()
			make.right.width.equalToSuperview().inset(UI.Margins/5)
		}
		
		view.addSubview(scrollView)
		scrollView.snp.makeConstraints { make in
			make.edges.equalTo(view.safeAreaLayoutGuide).inset(UI.Margins)
		}
		
		buildRules()
	}
	
	private func buildRules() {
		
		let objectiveKey = rules.targetScore == 5000 ? "rules.objective.content.5000" : "rules.objective.content.10000"
		stackView.addArrangedSubview(section(with: String(key: "rules.objective.title"), and: String(key: objectiveKey)))
		
		let materialKey = rules.diceCount == 5 ? "rules.material.content.5" : "rules.material.content.6"
		stackView.addArrangedSubview(section(with: String(key: "rules.material.title"), and: String(key: materialKey)))
		
		if rules.openingRequired {
			
			let openingKey: String
			switch rules.openingScore {
			case 300: openingKey = "rules.start.content.300"
			case 1000: openingKey = "rules.start.content.1000"
			default: openingKey = "rules.start.content.500"
			}
			stackView.addArrangedSubview(section(with: String(key: "rules.start.title"), and: String(key: openingKey)))
		}
		
		stackView.addArrangedSubview(section(with: String(key: "rules.turn.title"), and: String(key: "rules.turn.content")))
		stackView.addArrangedSubview(section(with: String(key: "rules.scoring.title"), and: String(key: "rules.scoring.content")))
		
		var specialContent = String(key: "rules.special.content.base")
		
		if rules.fullEnabled {
			
			specialContent += "\n" + String(key: "rules.special.content.full")
		}
		
		if rules.fiveOnesWin {
			
			specialContent += "\n" + String(key: "rules.special.content.fiveOnes")
		}
		
		if rules.fiveFivesWin {
			
			specialContent += "\n" + String(key: "rules.special.content.fiveFives")
		}
		
		stackView.addArrangedSubview(section(with: String(key: "rules.special.title"), and: specialContent))
		
		if rules.exactScore {
			
			let exactKey = rules.targetScore == 5000 ? "rules.exact.content.5000" : "rules.exact.content.10000"
			stackView.addArrangedSubview(section(with: String(key: "rules.exact.title"), and: String(key: exactKey)))
		}
		
		if rules.last1000InOneTurn {
			
			stackView.addArrangedSubview(section(with: String(key: "rules.last1000.title"), and: String(key: "rules.last1000.content")))
		}
		
		if rules.equalityKnockback {
			
			stackView.addArrangedSubview(section(with: String(key: "rules.tie.title"), and: String(key: "rules.tie.content")))
		}
		
		if rules.threeBallotsPenalty || rules.multipleOf100Only {
			
			var penaltiesContent = ""
			
			if rules.threeBallotsPenalty {
				
				penaltiesContent += String(key: "rules.penalties.threeBallots")
			}
			
			if rules.multipleOf100Only {
				
				if !penaltiesContent.isEmpty { penaltiesContent += "\n" }
				penaltiesContent += String(key: "rules.penalties.multipleOf100")
			}
			
			stackView.addArrangedSubview(section(with: String(key: "rules.penalties.title"), and: penaltiesContent))
		}
		
		stackView.addArrangedSubview(section(with: String(key: "rules.endgame.title"), and: String(key: "rules.endgame.content")))
	}
	
	private func section(with title:String, and content:String) -> UIStackView {
		
		let titleLabel:RR_Label = .init(title)
		titleLabel.font = Fonts.Content.Title.H2
		titleLabel.textColor = Colors.Content.Title
		
		let contentLabel:RR_Label = .init(content)
		
		let stackView:UIStackView = .init(arrangedSubviews: [titleLabel,contentLabel])
		stackView.axis = .vertical
		stackView.spacing = UI.Margins/2
		return stackView
	}
}

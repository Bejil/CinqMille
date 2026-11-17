//
//  CM_Network_Ready_Rules_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 22/10/2026.
//

import UIKit
import SnapKit

/// Écran de règles simplifié affiché à l'arrivée en lobby, avec confirmation « Je suis prêt ».
public class CM_Network_Ready_Rules_ViewController: CM_ViewController {
	
	private let rules:CM_Rules_Snapshot
	private let onReady:(()->Void)
	
	private lazy var scrollView:CM_ScrollView = {
		
		$0.showsVerticalScrollIndicator = false
		return $0
		
	}(CM_ScrollView())
	
	private lazy var contentStack:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 1.5 * UI.Margins
		$0.isLayoutMarginsRelativeArrangement = true
		$0.layoutMargins = .init(UI.Margins)
		return $0
		
	}(UIStackView())
	
	private lazy var headerIconContainer:UIView = {
		
		$0.backgroundColor = Colors.Primary.withAlphaComponent(0.12)
		$0.layer.cornerRadius = 28
		$0.clipsToBounds = true
		$0.snp.makeConstraints { make in
			make.width.height.equalTo(56)
		}
		
		let icon = UIImageView()
		let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
		icon.image = UIImage(systemName: "list.clipboard.fill", withConfiguration: config)
		icon.tintColor = Colors.Primary
		icon.contentMode = .scaleAspectFit
		$0.addSubview(icon)
		icon.snp.makeConstraints { make in
			make.center.equalToSuperview()
			make.width.height.equalTo(28)
		}
		return $0
		
	}(UIView())
	
	private lazy var headerTitleLabel:CM_Label = {
		
		$0.text = String(key: "network.lobby.ready.title")
		$0.font = Fonts.Content.Title.H2
		$0.textColor = Colors.Content.Title
		$0.textAlignment = .center
		$0.numberOfLines = 0
		return $0
		
	}(CM_Label())
	
	private lazy var subtitleLabel:CM_Label = {
		
		$0.text = String(key: "network.lobby.ready.subtitle")
		$0.font = Fonts.Content.Text.Regular
		$0.textColor = Colors.Content.Text
		$0.textAlignment = .center
		$0.numberOfLines = 0
		return $0
		
	}(CM_Label())
	
	private lazy var rulesCard:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 0
		$0.backgroundColor = Colors.Content.Title.withAlphaComponent(0.05)
		$0.layer.cornerRadius = UI.CornerRadius
		$0.layer.borderWidth = 1
		$0.layer.borderColor = Colors.Content.Text.withAlphaComponent(0.1).cgColor
		$0.clipsToBounds = true
		$0.isLayoutMarginsRelativeArrangement = true
		$0.layoutMargins = .init(horizontal: UI.Margins, vertical: UI.Margins / 2)
		return $0
		
	}(UIStackView())
	
	private lazy var footerContainer:UIView = {
		
		$0.backgroundColor = Colors.Background.View
		return $0
		
	}(UIView())
	
	private lazy var readyButton:CM_Button = .init(String(key: "network.lobby.ready")) { [weak self] _ in
		self?.readyButton.isLoading = true
		self?.onReady()
	}
	
	public init(snapshot:CM_Rules_Snapshot, onReady:@escaping ()->Void) {
		
		self.rules = snapshot
		self.onReady = onReady
		super.init(nibName: nil, bundle: nil)
	}
	
	@MainActor required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func loadView() {
		
		super.loadView()
		
		isModal = true
		title = nil
		navigationItem.largeTitleDisplayMode = .never
		
		view.addSubview(scrollView)
		view.addSubview(footerContainer)
		footerContainer.addSubview(readyButton)
		
		footerContainer.snp.makeConstraints { make in
			make.left.right.bottom.equalToSuperview()
		}
		
		readyButton.snp.makeConstraints { make in
			make.top.equalToSuperview().inset(UI.Margins)
			make.left.right.equalToSuperview().inset(UI.Margins)
			make.bottom.equalTo(view.safeAreaLayoutGuide).inset(UI.Margins)
		}
		
		scrollView.snp.makeConstraints { make in
			make.top.left.right.equalTo(view.safeAreaLayoutGuide)
			make.bottom.equalTo(footerContainer.snp.top)
		}
		
		scrollView.addSubview(contentStack)
		contentStack.snp.makeConstraints { make in
			make.top.bottom.equalToSuperview()
			make.left.right.width.equalToSuperview()
		}
		
		let headerStack = UIStackView(arrangedSubviews: [headerIconContainer, headerTitleLabel, subtitleLabel])
		headerStack.axis = .vertical
		headerStack.alignment = .center
		headerStack.spacing = UI.Margins / 2
		
		contentStack.addArrangedSubview(headerStack)
		contentStack.addArrangedSubview(rulesCard)
		
		buildCompactRules()
		addTopBorder(to: footerContainer)
	}
	
	public func stopReadyLoading() {
		readyButton.isLoading = false
	}
	
	private func buildCompactRules() {
		
		appendRuleRow(
			icon: "flag.fill",
			title: String(key: "network.lobby.ready.row.objective"),
			value: rules.targetScore == 10000
				? String(key: "settings.rules.objective.targetScore.10000")
				: String(key: "settings.rules.objective.targetScore.5000"),
			emphasized: true
		)
		
		appendRuleRow(
			icon: "cube.fill",
			title: String(key: "network.lobby.ready.row.dice"),
			value: rules.diceCount == 6
				? String(key: "settings.rules.material.diceCount.6")
				: String(key: "settings.rules.material.diceCount.5"),
			emphasized: true
		)
		
		let openingValue:String
		if rules.openingRequired {
			switch rules.openingScore {
			case 300: openingValue = String(key: "settings.rules.opening.minumumScore.300")
			case 1000: openingValue = String(key: "settings.rules.opening.minumumScore.1000")
			default: openingValue = String(key: "settings.rules.opening.minumumScore.500")
			}
		} else {
			openingValue = String(key: "network.lobby.ready.value.off")
		}
		appendRuleRow(
			icon: "play.circle.fill",
			title: String(key: "network.lobby.ready.row.opening"),
			value: openingValue,
			isOn: rules.openingRequired
		)
		
		appendRuleRow(
			icon: "scope",
			title: String(key: "network.lobby.ready.row.exact"),
			value: rules.exactScore
				? String(key: "network.lobby.ready.value.on")
				: String(key: "network.lobby.ready.value.off"),
			isOn: rules.exactScore
		)
		
		if rules.last1000InOneTurn {
			appendRuleRow(
				icon: "bolt.fill",
				title: String(key: "network.lobby.ready.row.last1000"),
				value: String(key: "network.lobby.ready.value.on"),
				isOn: true
			)
		}
		
		if rules.equalityKnockback {
			appendRuleRow(
				icon: "arrow.left.arrow.right",
				title: String(key: "network.lobby.ready.row.equality"),
				value: String(key: "network.lobby.ready.value.on"),
				isOn: true
			)
		}
		
		var specials:[String] = []
		if rules.fullEnabled { specials.append(String(key: "network.lobby.ready.special.full")) }
		if rules.fiveOnesWin { specials.append(String(key: "network.lobby.ready.special.fiveOnes")) }
		if rules.fiveFivesWin { specials.append(String(key: "network.lobby.ready.special.fiveFives")) }
		if !specials.isEmpty {
			appendRuleRow(
				icon: "star.fill",
				title: String(key: "network.lobby.ready.row.special"),
				value: specials.joined(separator: " · "),
				isOn: true
			)
		}
		
		var penalties:[String] = []
		if rules.threeBallotsPenalty { penalties.append(String(key: "network.lobby.ready.penalty.threeBallots")) }
		if rules.multipleOf100Only { penalties.append(String(key: "network.lobby.ready.penalty.multipleOf100")) }
		if !penalties.isEmpty {
			appendRuleRow(
				icon: "exclamationmark.triangle.fill",
				title: String(key: "network.lobby.ready.row.penalties"),
				value: penalties.joined(separator: " · "),
				isOn: false,
				danger: true
			)
		}
	}
	
	private func appendRuleRow(icon:String,
							   title:String,
							   value:String,
							   emphasized:Bool = false,
							   isOn:Bool? = nil,
							   danger:Bool = false) {
		
		if !rulesCard.arrangedSubviews.isEmpty {
			rulesCard.addArrangedSubview(separatorLine())
		}
		
		let iconView = UIImageView(image: UIImage(systemName: icon))
		iconView.tintColor = danger ? Colors.Primary : Colors.Secondary
		iconView.contentMode = .scaleAspectFit
		iconView.snp.makeConstraints { make in
			make.width.height.equalTo(22)
		}
		
		let titleLabel = CM_Label(title)
		titleLabel.font = Fonts.Content.Text.Bold
		titleLabel.textColor = Colors.Content.Title
		titleLabel.numberOfLines = 1
		
		let valueLabel = CM_Label(value)
		valueLabel.font = emphasized ? Fonts.Content.Text.Bold : Fonts.Content.Text.Regular
		valueLabel.numberOfLines = 0
		valueLabel.textAlignment = .right
		
		if let isOn {
			valueLabel.textColor = .white
			valueLabel.contentInsets = .init(top: 4, left: 10, bottom: 4, right: 10)
			valueLabel.backgroundColor = isOn
				? Colors.Secondary
				: Colors.Content.Text.withAlphaComponent(0.35)
			valueLabel.layer.cornerRadius = 10
			valueLabel.clipsToBounds = true
			valueLabel.setContentHuggingPriority(.required, for: .horizontal)
		} else if emphasized {
			valueLabel.textColor = Colors.Primary
		} else if danger {
			valueLabel.textColor = Colors.Primary
		} else {
			valueLabel.textColor = Colors.Content.Text
		}
		
		let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
		textStack.axis = .horizontal
		textStack.alignment = .center
		textStack.spacing = UI.Margins / 2
		textStack.distribution = .fill
		
		titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
		titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
		
		let row = UIStackView(arrangedSubviews: [iconView, textStack])
		row.axis = .horizontal
		row.alignment = .center
		row.spacing = UI.Margins
		row.isLayoutMarginsRelativeArrangement = true
		row.layoutMargins = .init(top: UI.Margins * 0.85, left: 0, bottom: UI.Margins * 0.85, right: 0)
		
		rulesCard.addArrangedSubview(row)
	}
	
	private func separatorLine() -> UIView {
		
		let line = UIView()
		line.backgroundColor = Colors.Content.Text.withAlphaComponent(0.12)
		line.snp.makeConstraints { make in
			make.height.equalTo(1)
		}
		return line
	}
	
	private func addTopBorder(to container:UIView) {
		
		let line = UIView()
		line.backgroundColor = Colors.Content.Text.withAlphaComponent(0.12)
		container.addSubview(line)
		line.snp.makeConstraints { make in
			make.top.left.right.equalToSuperview()
			make.height.equalTo(1)
		}
	}
}

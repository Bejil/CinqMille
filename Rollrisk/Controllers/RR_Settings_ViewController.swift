//
//  RR_Settings_ViewController.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class RR_Settings_ViewController : RR_ViewController {
	
	private lazy var playerButton:RR_Button = {
		
		$0.image = UIImage(systemName: "person.fill")
		return $0
		
	}(RR_Button(){ [weak self] _ in
		
		let controller:RR_Player_Name_Alert_ViewController = .init()
		controller.completion = { [weak self] in
			
			self?.updatePlayerButton()
		}
		controller.addCancelButton()
		controller.present()
	})
	private lazy var musicToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			UserDefaults.set(!RR_Audio.shared.isMusicEnabled, .musicEnabled)
			RR_Audio.shared.playSound(.Button)
			RR_Audio.shared.isMusicEnabled ? RR_Audio.shared.playMusic() : RR_Audio.shared.stopMusic()
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var soundsToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { _ in
			
			UserDefaults.set(!RR_Audio.shared.isSoundsEnabled, .soundsEnabled)
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var vibrationsToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { _ in
			
			UserDefaults.set(!RR_Feedback.shared.isVibrationsEnabled, .vibrationsEnabled)
			RR_Feedback.shared.make(.On)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var targetScoreSegment:RR_SegmentedControl = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.targetScore = self?.targetScoreSegment.selectedSegmentIndex == 0 ? 5000 : 10000
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_SegmentedControl(items: [
		String(key: "settings.rules.objective.targetScore.5000"),
		String(key: "settings.rules.objective.targetScore.10000")
	]))
	private lazy var diceCountSegment:RR_SegmentedControl = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.diceCount = self?.diceCountSegment.selectedSegmentIndex == 0 ? 5 : 6
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_SegmentedControl(items: [
		String(key: "settings.rules.material.diceCount.5"),
		String(key: "settings.rules.material.diceCount.6")
	]))
	private lazy var openingScoreSegment:RR_SegmentedControl = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			let scores = [300, 500, 1000]
			RR_Rules.shared.openingScore = scores[self?.openingScoreSegment.selectedSegmentIndex ?? RR_Rules.shared.openingScore]
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_SegmentedControl(items: [
		String(key: "settings.rules.opening.minumumScore.300"),
		String(key: "settings.rules.opening.minumumScore.500"),
		String(key: "settings.rules.opening.minumumScore.1000")
	]))
	private lazy var exactScoreToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.exactScore = self?.exactScoreToggle.isOn ?? RR_Rules.shared.exactScore
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var last1000Toggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.last1000InOneTurn = self?.last1000Toggle.isOn ?? RR_Rules.shared.last1000InOneTurn
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var openingToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.openingRequired = self?.openingToggle.isOn ?? RR_Rules.shared.openingRequired
			self?.updateOpeningScoreVisibility()
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var equalityToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.equalityKnockback = self?.equalityToggle.isOn ?? RR_Rules.shared.equalityKnockback
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var fiveOnesToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.fiveOnesWin = self?.fiveOnesToggle.isOn ?? RR_Rules.shared.fiveOnesWin
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var fiveFivesToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.fiveFivesWin = self?.fiveFivesToggle.isOn ?? RR_Rules.shared.fiveFivesWin
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var fullToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.fullEnabled = self?.fullToggle.isOn ?? RR_Rules.shared.fullEnabled
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var threeBallotToggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.threeBallotsPenalty = self?.threeBallotToggle.isOn ?? RR_Rules.shared.threeBallotsPenalty
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var multipleOf100Toggle:RR_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			RR_Rules.shared.multipleOf100Only = self?.multipleOf100Toggle.isOn ?? RR_Rules.shared.multipleOf100Only
			RR_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(RR_Switch())
	private lazy var openingScoreRow:UIStackView = settingRow(title: String(key: "settings.rules.opening.minumumScore"), description: String(key: "settings.rules.opening.minumumScore.description"), control: openingScoreSegment)
	private lazy var stackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 2.5*UI.Margins
		$0.addArrangedSubview(playerButton)
		$0.addArrangedSubview(sectionStackView(with: [
			sectionTitle(String(key: "settings.audio.title")),
			settingRow(title: String(key: "settings.audio.music"), description: String(key: "settings.audio.music.description"), control: musicToggle),
			settingRow(title: String(key: "settings.audio.sounds"), description: String(key: "settings.audio.sounds.description"), control: soundsToggle),
			settingRow(title: String(key: "settings.audio.vibrations"), description: String(key: "settings.audio.vibrations.description"), control: vibrationsToggle)
		]))
		$0.addArrangedSubview(sectionStackView(with: [
			sectionTitle(String(key: "settings.rules.objective.title")),
			settingRow(title: String(key: "settings.rules.objective.targetScore"), description: String(key: "settings.rules.objective.targetScore.description"), control: targetScoreSegment),
			settingRow(title: String(key: "settings.rules.objective.exactScore"), description: String(key: "settings.rules.objective.exactScore.description"), control: exactScoreToggle),
			settingRow(title: String(key: "settings.rules.objective.last1000"), description: String(key: "settings.rules.objective.last1000.description"), control: last1000Toggle)
		]))
		$0.addArrangedSubview(sectionStackView(with: [
			sectionTitle(String(key: "settings.rules.opening.title")),
			settingRow(title: String(key: "settings.rules.opening.minumum"), description: String(key: "settings.rules.opening.minumum.description"), control: openingToggle),
			openingScoreRow
		]))
		$0.addArrangedSubview(sectionStackView(with: [
			sectionTitle(String(key: "settings.rules.material.title")),
			settingRow(title: String(key: "settings.rules.material.diceCount"), description: String(key: "settings.rules.material.diceCount.description"), control: diceCountSegment)
		]))
		$0.addArrangedSubview(sectionStackView(with: [
			sectionTitle(String(key: "settings.rules.special.title")),
			settingRow(title: String(key: "settings.rules.special.fiveOnesWin"), description: String(key: "settings.rules.special.fiveOnesWin.description"), control: fiveOnesToggle),
			settingRow(title: String(key: "settings.rules.special.fiveFivesWin"), description: String(key: "settings.rules.special.fiveFivesWin.description"), control: fiveFivesToggle),
			settingRow(title: String(key: "settings.rules.special.full"), description: String(key: "settings.rules.special.full.description"), control: fullToggle),
			settingRow(title: String(key: "settings.rules.special.equality"), description: String(key: "settings.rules.special.equality.description"), control: equalityToggle)
		]))
		$0.addArrangedSubview(sectionStackView(with: [
			sectionTitle(String(key: "settings.rules.penalties.title")),
			settingRow(title: String(key: "settings.rules.penalties.threeBallots"), description: String(key: "settings.rules.penalties.threeBallots.description"), control: threeBallotToggle),
			settingRow(title: String(key: "settings.rules.penalties.multipleOf100"), description: String(key: "settings.rules.penalties.multipleOf100.description"), control: multipleOf100Toggle)
		]))
		
		let resetButton:RR_Button = .init(String(key: "settings.rules.reset")) { [weak self] _ in
			
			RR_Rules.shared.reset()
			self?.updateRulesControls()
		}
		resetButton.type = .delete
		$0.addArrangedSubview(resetButton)
		return $0
		
	}(UIStackView())
	
	public override func loadView() {
		
		super.loadView()
		
		isModal = true
		title = String(key: "settings.title")
		
		let scrollView:RR_ScrollView = .init()
		scrollView.isCentered = false
		scrollView.showsVerticalScrollIndicator = false
		scrollView.addSubview(stackView)
		stackView.snp.makeConstraints { make in
			make.top.bottom.left.equalToSuperview()
			make.right.width.equalToSuperview().inset(UI.Margins/5)
		}
		view.addSubview(scrollView)
		scrollView.snp.makeConstraints { make in
			make.edges.equalTo(view.safeAreaLayoutGuide).inset(UI.Margins)
		}
		
		stackView.animate()
		
		updatePlayerButton()
		updateAudioToggles()
		updateRulesControls()
	}
	
	private func sectionStackView(with arrangedSubviews:[UIView] = []) -> UIStackView {
		
		let stackView:UIStackView = .init(arrangedSubviews: arrangedSubviews)
		stackView.axis = .vertical
		stackView.spacing = UI.Margins
		return stackView
	}
	
	private func sectionTitle(_ title:String) -> RR_Label {
		
		let label:RR_Label = .init(title)
		label.font = Fonts.Content.Title.H2
		label.textColor = Colors.Content.Title
		return label
	}
	
	private func settingRow(title:String, description:String, control:UIView) -> UIStackView {
		
		let titleLabel:RR_Label = .init(title)
		titleLabel.font = Fonts.Content.Title.H4
		titleLabel.textColor = Colors.Content.Text
		
		let descriptionLabel:RR_Label = .init(description)
		
		let textStackView:UIStackView = .init(arrangedSubviews: [titleLabel, descriptionLabel])
		textStackView.axis = .vertical
		
		let rowStackView:UIStackView = .init(arrangedSubviews: [textStackView, control])
		rowStackView.axis = .horizontal
		rowStackView.alignment = .center
		rowStackView.spacing = UI.Margins
		
		if control is UISegmentedControl {
			
			rowStackView.axis = .vertical
			rowStackView.alignment = .fill
		}
		
		return rowStackView
	}
	
	private func updatePlayerButton() {
		
		let player = RR_Player.current
		playerButton.title = String(key: "settings.name")
		playerButton.subtitle = player.name
	}
	
	private func updateAudioToggles() {
		
		musicToggle.isOn = RR_Audio.shared.isMusicEnabled
		soundsToggle.isOn = RR_Audio.shared.isSoundsEnabled
		vibrationsToggle.isOn = RR_Feedback.shared.isVibrationsEnabled
	}
	
	private func updateRulesControls() {
		
		targetScoreSegment.selectedSegmentIndex = RR_Rules.shared.targetScore == 5000 ? 0 : 1
		diceCountSegment.selectedSegmentIndex = RR_Rules.shared.diceCount == 5 ? 0 : 1
		
		let openingScores = [300, 500, 1000]
		openingScoreSegment.selectedSegmentIndex = openingScores.firstIndex(of: RR_Rules.shared.openingScore) ?? 1
		
		exactScoreToggle.isOn = RR_Rules.shared.exactScore
		last1000Toggle.isOn = RR_Rules.shared.last1000InOneTurn
		openingToggle.isOn = RR_Rules.shared.openingRequired
		equalityToggle.isOn = RR_Rules.shared.equalityKnockback
		fiveOnesToggle.isOn = RR_Rules.shared.fiveOnesWin
		fiveFivesToggle.isOn = RR_Rules.shared.fiveFivesWin
		fullToggle.isOn = RR_Rules.shared.fullEnabled
		threeBallotToggle.isOn = RR_Rules.shared.threeBallotsPenalty
		multipleOf100Toggle.isOn = RR_Rules.shared.multipleOf100Only
		
		updateOpeningScoreVisibility()
	}
	
	private func updateOpeningScoreVisibility() {
		
		UIView.animate(withDuration: 0.3) {
			
			self.openingScoreRow.isHidden = !RR_Rules.shared.openingRequired
			self.openingScoreRow.alpha = RR_Rules.shared.openingRequired ? 1.0 : 0.0
		}
	}
}

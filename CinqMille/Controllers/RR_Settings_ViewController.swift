//
//  CM_Settings_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class CM_Settings_ViewController : CM_ViewController {
	
	private lazy var playerButton:CM_Button = {
		
		$0.image = UIImage(systemName: "person.fill")
		return $0
		
	}(CM_Button(){ [weak self] _ in
		
		let controller:CM_Player_Name_Alert_ViewController = .init()
		controller.completion = { [weak self] in
			
			self?.updatePlayerButton()
		}
		controller.addCancelButton()
		controller.present()
	})
	private lazy var musicToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			UserDefaults.set(!CM_Audio.shared.isMusicEnabled, .musicEnabled)
			CM_Audio.shared.playSound(.Button)
			CM_Audio.shared.isMusicEnabled ? CM_Audio.shared.playMusic() : CM_Audio.shared.stopMusic()
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var soundsToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { _ in
			
			UserDefaults.set(!CM_Audio.shared.isSoundsEnabled, .soundsEnabled)
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var vibrationsToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { _ in
			
			UserDefaults.set(!CM_Feedback.shared.isVibrationsEnabled, .vibrationsEnabled)
			CM_Feedback.shared.make(.On)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var targetScoreSegment:CM_SegmentedControl = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.targetScore = self?.targetScoreSegment.selectedSegmentIndex == 0 ? 5000 : 10000
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_SegmentedControl(items: [
		String(key: "settings.rules.objective.targetScore.5000"),
		String(key: "settings.rules.objective.targetScore.10000")
	]))
	private lazy var diceCountSegment:CM_SegmentedControl = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.diceCount = self?.diceCountSegment.selectedSegmentIndex == 0 ? 5 : 6
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_SegmentedControl(items: [
		String(key: "settings.rules.material.diceCount.5"),
		String(key: "settings.rules.material.diceCount.6")
	]))
	private lazy var openingScoreSegment:CM_SegmentedControl = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			let scores = [300, 500, 1000]
			CM_Rules.shared.openingScore = scores[self?.openingScoreSegment.selectedSegmentIndex ?? CM_Rules.shared.openingScore]
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_SegmentedControl(items: [
		String(key: "settings.rules.opening.minumumScore.300"),
		String(key: "settings.rules.opening.minumumScore.500"),
		String(key: "settings.rules.opening.minumumScore.1000")
	]))
	private lazy var exactScoreToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.exactScore = self?.exactScoreToggle.isOn ?? CM_Rules.shared.exactScore
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var last1000Toggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.last1000InOneTurn = self?.last1000Toggle.isOn ?? CM_Rules.shared.last1000InOneTurn
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var openingToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.openingRequired = self?.openingToggle.isOn ?? CM_Rules.shared.openingRequired
			self?.updateOpeningScoreVisibility()
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var equalityToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.equalityKnockback = self?.equalityToggle.isOn ?? CM_Rules.shared.equalityKnockback
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var fiveOnesToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.fiveOnesWin = self?.fiveOnesToggle.isOn ?? CM_Rules.shared.fiveOnesWin
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var fiveFivesToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.fiveFivesWin = self?.fiveFivesToggle.isOn ?? CM_Rules.shared.fiveFivesWin
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var fullToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.fullEnabled = self?.fullToggle.isOn ?? CM_Rules.shared.fullEnabled
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var threeBallotToggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.threeBallotsPenalty = self?.threeBallotToggle.isOn ?? CM_Rules.shared.threeBallotsPenalty
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
	private lazy var multipleOf100Toggle:CM_Switch = {
		
		$0.addAction(.init(handler: { [weak self] _ in
			
			CM_Rules.shared.multipleOf100Only = self?.multipleOf100Toggle.isOn ?? CM_Rules.shared.multipleOf100Only
			CM_Audio.shared.playSound(.Button)
			
		}), for: .valueChanged)
		return $0
		
	}(CM_Switch())
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
		
		let resetButton:CM_Button = .init(String(key: "settings.rules.reset")) { [weak self] _ in
			
			CM_Rules.shared.reset()
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
		
		let scrollView:CM_ScrollView = .init()
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
	
	private func sectionTitle(_ title:String) -> CM_Label {
		
		let label:CM_Label = .init(title)
		label.font = Fonts.Content.Title.H2
		label.textColor = Colors.Content.Title
		return label
	}
	
	private func settingRow(title:String, description:String, control:UIView) -> UIStackView {
		
		let titleLabel:CM_Label = .init(title)
		titleLabel.font = Fonts.Content.Title.H4
		titleLabel.textColor = Colors.Content.Text
		
		let descriptionLabel:CM_Label = .init(description)
		
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
		
		let player = CM_Player.current
		playerButton.title = String(key: "settings.name")
		playerButton.subtitle = player.name
	}
	
	private func updateAudioToggles() {
		
		musicToggle.isOn = CM_Audio.shared.isMusicEnabled
		soundsToggle.isOn = CM_Audio.shared.isSoundsEnabled
		vibrationsToggle.isOn = CM_Feedback.shared.isVibrationsEnabled
	}
	
	private func updateRulesControls() {
		
		targetScoreSegment.selectedSegmentIndex = CM_Rules.shared.targetScore == 5000 ? 0 : 1
		diceCountSegment.selectedSegmentIndex = CM_Rules.shared.diceCount == 5 ? 0 : 1
		
		let openingScores = [300, 500, 1000]
		openingScoreSegment.selectedSegmentIndex = openingScores.firstIndex(of: CM_Rules.shared.openingScore) ?? 1
		
		exactScoreToggle.isOn = CM_Rules.shared.exactScore
		last1000Toggle.isOn = CM_Rules.shared.last1000InOneTurn
		openingToggle.isOn = CM_Rules.shared.openingRequired
		equalityToggle.isOn = CM_Rules.shared.equalityKnockback
		fiveOnesToggle.isOn = CM_Rules.shared.fiveOnesWin
		fiveFivesToggle.isOn = CM_Rules.shared.fiveFivesWin
		fullToggle.isOn = CM_Rules.shared.fullEnabled
		threeBallotToggle.isOn = CM_Rules.shared.threeBallotsPenalty
		multipleOf100Toggle.isOn = CM_Rules.shared.multipleOf100Only
		
		updateOpeningScoreVisibility()
	}
	
	private func updateOpeningScoreVisibility() {
		
		UIView.animate(withDuration: 0.3) {
			
			self.openingScoreRow.isHidden = !CM_Rules.shared.openingRequired
			self.openingScoreRow.alpha = CM_Rules.shared.openingRequired ? 1.0 : 0.0
		}
	}
}

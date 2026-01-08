//
//  RR_Menu_ViewController.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class RR_Menu_ViewController : RR_ViewController {
	
	private lazy var bannerView = RR_Ads.shared.presentBanner(Ads.Banner.Menu, self)
	private lazy var stackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 1.5*UI.Margins
		
		let titleLabel0:RR_Label = .init(String(key: "menu.title.0"))
		titleLabel0.font = Fonts.Content.Title.H1
		titleLabel0.textColor = Colors.Content.Title
		titleLabel0.textAlignment = .center
		
		let titleLabel1:RR_Label = .init(String(key: "menu.title.1"))
		titleLabel1.font = Fonts.Content.Title.H1
		titleLabel1.textColor = Colors.Content.Title
		titleLabel1.textAlignment = .center
		
		let titleLabelSeparator:RR_Label = .init(String(key: "menu.title.separator"))
		titleLabelSeparator.font = Fonts.Content.Title.H1.withSize(Fonts.Content.Title.H1.pointSize+40)
		titleLabelSeparator.textColor = Colors.Content.Text
		titleLabelSeparator.textAlignment = .center
		
		let titleStackView:UIStackView = .init(arrangedSubviews: [titleLabel0,titleLabelSeparator,titleLabel1])
		titleStackView.axis = .horizontal
		titleStackView.spacing = UI.Margins/2
		titleStackView.alignment = .center
		
		let titleContainerStackView:UIStackView = .init(arrangedSubviews: [titleStackView])
		titleContainerStackView.axis = .vertical
		titleContainerStackView.alignment = .center
		$0.addArrangedSubview(titleContainerStackView)
		
		let subtitleLabel:RR_Label = .init(String(key: "menu.subtitle"))
		subtitleLabel.textAlignment = .center
		$0.addArrangedSubview(subtitleLabel)
		$0.setCustomSpacing(1.5*$0.spacing, after: subtitleLabel)
		
		let newGameButton:RR_Button = .init(String(key: "menu.button.newGame")) { _ in
			
			let alertController:RR_Alert_ViewController = .init()
			alertController.title = String(key: "newGame.alert.title")
			alertController.addButton(title: String(key: "newGame.alert.solo")) { _ in
				
				alertController.close {
					
					UI.MainController.present(RR_NavigationController(rootViewController: RR_Game_ViewController()), animated: true)
				}
			}
			alertController.addButton(title: String(key: "newGame.alert.dices")) { _ in
				
				alertController.close {
					
					UI.MainController.present(RR_NavigationController(rootViewController: RR_Dices_ViewController()), animated: true)
				}
			}
			alertController.addCancelButton()
			alertController.present()
		}
		newGameButton.image = UIImage(systemName: "dice.fill")
		$0.addArrangedSubview(newGameButton)
		
		let rulesButton:RR_Button = .init(String(key: "menu.button.rules")) { _ in
			
			UI.MainController.present(RR_NavigationController(rootViewController: RR_Rules_ViewController()), animated: true)
		}
		rulesButton.image = UIImage(systemName: "list.clipboard.fill")
		rulesButton.type = .secondary
		$0.addArrangedSubview(rulesButton)
		
		let settingsButton:RR_Button = .init(String(key: "menu.button.settings")) { _ in
			
			UI.MainController.present(RR_NavigationController(rootViewController: RR_Settings_ViewController()), animated: true)
		}
		settingsButton.image = UIImage(systemName: "slider.vertical.3")
		settingsButton.type = .tertiary
		$0.addArrangedSubview(settingsButton)
		
		$0.setCustomSpacing(1.5*$0.spacing, after: settingsButton)
		
		$0.addArrangedSubview(bannerView)
		
		return $0
		
	}(UIStackView())
	
	public override func loadView() {
		
		super.loadView()
		
		let statsButton:RR_Button = .init(String(key: "menu.button.stats")) { _ in
			
			let alertController:RR_Alert_ViewController = .init()
			alertController.title = String(key: "stats.alert.title")
			alertController.add(String(key: "stats.alert.wins") + "\(RR_Player.current.stats.wins)")
			alertController.add(String(key: "stats.alert.losses") + "\(RR_Player.current.stats.losses)")
			alertController.add(String(key: "stats.alert.abandonments") + "\(RR_Player.current.stats.abandonments)")
			alertController.addDismissButton()
			alertController.present()
		}
		statsButton.image = UIImage(systemName: "list.number")?.applyingSymbolConfiguration(.init(scale: .small))
		statsButton.configuration?.imagePadding = UI.Margins/2
		statsButton.type = .navigation
		navigationItem.leftBarButtonItem = .init(customView: statsButton)
		
		let scrollView:RR_ScrollView = .init()
		scrollView.showsVerticalScrollIndicator = false
		scrollView.isCentered = true
		scrollView.addSubview(stackView)
		stackView.snp.makeConstraints { make in
			make.top.bottom.left.equalToSuperview()
			make.right.width.equalToSuperview().inset(UI.Margins)
		}
		
		view.addSubview(scrollView)
		scrollView.snp.makeConstraints { make in
			make.edges.equalTo(view.safeAreaLayoutGuide).inset(UI.Margins)
		}
		
		stackView.animate()
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		
		super.viewWillAppear(animated)
		
		bannerView.refresh()
	}
}

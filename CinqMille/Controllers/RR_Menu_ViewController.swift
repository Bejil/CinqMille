//
//  CM_Menu_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import UIKit
import SnapKit

public class CM_Menu_ViewController : CM_ViewController {
	
	private lazy var bannerView = CM_Ads.shared.presentBanner(Ads.Banner.Menu, self)
	private var rollTimer:Timer?
	private lazy var stackView:UIStackView = {
		
		$0.axis = .vertical
		$0.spacing = 2*UI.Margins
		
		let firstDice:CM_Dice = .init()
		firstDice.transform = .init(rotationAngle: .pi/3)
		firstDice.roll(false)
		
		let secondDice:CM_Dice = .init()
		secondDice.transform = .init(rotationAngle: .pi/3)
		secondDice.roll(false)
		
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
		
		rollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
			
			firstDice.roll()
			secondDice.roll()
		})
		
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
		
		let subtitleLabel:CM_Label = .init(String(key: "menu.subtitle"))
		subtitleLabel.textAlignment = .center
		
		let headerStackView:UIStackView = .init(arrangedSubviews: [titleLabel,subtitleLabel])
		headerStackView.axis = .vertical
		headerStackView.spacing = UI.Margins
		$0.addArrangedSubview(headerStackView)
		
		let newGameButton:CM_Button = .init(String(key: "menu.button.newGame")) { [weak self] _ in
			
			let alertController:CM_Alert_ViewController = .init()
			alertController.title = String(key: "newGame.alert.title")
			alertController.addButton(title: String(key: "newGame.alert.solo")) { [weak self] _ in
				
				alertController.close { [weak self] in
					
					self?.presentGameStartAd {
						
						UI.MainController.present(CM_NavigationController(rootViewController: CM_Game_ViewController()), animated: true)
					}
				}
			}
			alertController.addButton(title: String(key: "newGame.alert.dices")) { [weak self] _ in
				
				alertController.close { [weak self] in
					
					self?.presentGameStartAd {
						
						UI.MainController.present(CM_NavigationController(rootViewController: CM_Dices_ViewController()), animated: true)
					}
				}
			}
			alertController.addCancelButton()
			alertController.present()
		}
		newGameButton.image = UIImage(systemName: "dice.fill")
		
		let rulesButton:CM_Button = .init(String(key: "menu.button.rules")) { _ in
			
			UI.MainController.present(CM_NavigationController(rootViewController: CM_Rules_ViewController()), animated: true)
		}
		rulesButton.image = UIImage(systemName: "list.clipboard.fill")
		rulesButton.type = .secondary
		
		let buttonsStackView:UIStackView = .init(arrangedSubviews: [newGameButton,rulesButton])
		buttonsStackView.axis = .vertical
		buttonsStackView.spacing = UI.Margins
		$0.addArrangedSubview(buttonsStackView)
		
		let inAppButton:CM_Button = .init(String(key: "menu.button.inApp")) { _ in
			
			CM_InAppPurchase.shared.promptInAppPurchaseAlert(withCapping: false)
		}
		inAppButton.type = .navigation
		inAppButton.titleFont = Fonts.Content.Button.Title
		
		let adsStackView:UIStackView = .init(arrangedSubviews: [inAppButton,bannerView])
		adsStackView.axis = .vertical
		adsStackView.spacing = UI.Margins
		$0.addArrangedSubview(adsStackView)
		
		NotificationCenter.add(.updateAds) { [weak self] _ in
			
			let state = !(UserDefaults.get(.shouldDisplayAds) as? Bool ?? true)
			adsStackView.isHidden = state
		}
		
		return $0
		
	}(UIStackView())
	
	isolated deinit {
		
		rollTimer?.invalidate()
		rollTimer = nil
	}
	
	public override func loadView() {
		
		super.loadView()
		
		let statsButton:CM_Button = .init(String(key: "menu.button.stats")) { _ in
			
			let alertController:CM_Alert_ViewController = .init()
			alertController.title = String(key: "stats.alert.title")
			alertController.add(String(key: "stats.alert.wins") + "\(CM_Player.current.stats.wins)")
			alertController.add(String(key: "stats.alert.losses") + "\(CM_Player.current.stats.losses)")
			alertController.add(String(key: "stats.alert.abandonments") + "\(CM_Player.current.stats.abandonments)")
			alertController.addDismissButton()
			alertController.present()
		}
		statsButton.image = UIImage(systemName: "list.number")?.applyingSymbolConfiguration(.init(scale: .small))
		statsButton.configuration?.imagePadding = UI.Margins/2
		statsButton.type = .navigation
		navigationItem.leftBarButtonItem = .init(customView: statsButton)
		
		let settingsButton:CM_Button = .init(String(key: "menu.button.settings")) { _ in
			
			UI.MainController.present(CM_NavigationController(rootViewController: CM_Settings_ViewController()), animated: true)
		}
		settingsButton.image = UIImage(systemName: "slider.vertical.3")?.applyingSymbolConfiguration(.init(scale: .small))
		settingsButton.configuration?.imagePadding = UI.Margins/2
		settingsButton.type = .navigation
		navigationItem.rightBarButtonItem = .init(customView: settingsButton)
		
		let scrollView:CM_ScrollView = .init()
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
	
	private func presentGameStartAd(_ completion:(()->Void)?) {
		
		CM_Alert_ViewController.presentLoading({ [weak self] alertController in
			
			CM_Ads.shared.presentInterstitial(Ads.FullScreen.Game.Start, nil, { [weak self] in
				
				alertController?.close(completion)
			})
		})
	}
}

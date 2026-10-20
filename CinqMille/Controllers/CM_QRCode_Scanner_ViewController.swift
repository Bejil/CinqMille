//
//  CM_QRCode_Scanner_ViewController.swift
//  CinqMille
//
//  Created by BLIN Michael on 16/10/2026.
//

import UIKit
import AVFoundation
import SnapKit

public class CM_QRCode_Scanner_ViewController: CM_ViewController {
	
	public var onCodeScanned:((String)->Void)?
	
	private let session = AVCaptureSession()
	private var previewLayer:AVCaptureVideoPreviewLayer?
	private var hasScanned:Bool = false
	private var previousNavAppearance:(standard:UINavigationBarAppearance, scroll:UINavigationBarAppearance?, compact:UINavigationBarAppearance?, tint:UIColor?)?
	
	private lazy var topFadeView:UIView = {
		
		$0.isUserInteractionEnabled = false
		$0.backgroundColor = .clear
		return $0
		
	}(UIView())
	
	private lazy var bottomFadeView:UIView = {
		
		$0.isUserInteractionEnabled = false
		$0.backgroundColor = .clear
		return $0
		
	}(UIView())
	
	private lazy var topGradientLayer:CAGradientLayer = {
		
		$0.colors = [
			UIColor.black.withAlphaComponent(0.75).cgColor,
			UIColor.black.withAlphaComponent(0.0).cgColor
		]
		$0.locations = [0, 1]
		return $0
		
	}(CAGradientLayer())
	
	private lazy var bottomGradientLayer:CAGradientLayer = {
		
		$0.colors = [
			UIColor.black.withAlphaComponent(0.0).cgColor,
			UIColor.black.withAlphaComponent(0.75).cgColor
		]
		$0.locations = [0, 1]
		return $0
		
	}(CAGradientLayer())
	
	private lazy var hintLabel:CM_Label = {
		
		$0.text = String(key: "network.lobby.scan.hint")
		$0.textColor = .white
		$0.textAlignment = .center
		$0.numberOfLines = 0
		return $0
		
	}(CM_Label())
	
	public override func loadView() {
		
		super.loadView()
		
		title = String(key: "network.lobby.scan.title")
		view.backgroundColor = .black
		navigationItem.largeTitleDisplayMode = .never
		
		view.addSubview(topFadeView)
		view.addSubview(bottomFadeView)
		view.addSubview(hintLabel)
		
		topFadeView.layer.addSublayer(topGradientLayer)
		bottomFadeView.layer.addSublayer(bottomGradientLayer)
		
		topFadeView.snp.makeConstraints { make in
			make.top.left.right.equalToSuperview()
			make.height.equalToSuperview().multipliedBy(0.22)
		}
		
		bottomFadeView.snp.makeConstraints { make in
			make.bottom.left.right.equalToSuperview()
			make.height.equalToSuperview().multipliedBy(0.28)
		}
		
		hintLabel.snp.makeConstraints { make in
			make.left.right.equalToSuperview().inset(UI.Margins)
			make.bottom.equalTo(view.safeAreaLayoutGuide).inset(UI.Margins)
		}
	}
	
	public override func viewDidLoad() {
		
		super.viewDidLoad()
		isModal = true
		navigationItem.leftBarButtonItem?.tintColor = .white
		requestCameraAndStart()
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		
		super.viewWillAppear(animated)
		applyLightNavigationChrome()
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
		
		super.viewWillDisappear(animated)
		
		restoreNavigationChrome()
		
		if session.isRunning {
			session.stopRunning()
		}
	}
	
	public override func viewDidLayoutSubviews() {
		
		super.viewDidLayoutSubviews()
		previewLayer?.frame = view.bounds
		topGradientLayer.frame = topFadeView.bounds
		bottomGradientLayer.frame = bottomFadeView.bounds
	}
	
	private func applyLightNavigationChrome() {
		
		guard let navigationBar = navigationController?.navigationBar else { return }
		
		previousNavAppearance = (
			navigationBar.standardAppearance,
			navigationBar.scrollEdgeAppearance,
			navigationBar.compactAppearance,
			navigationBar.tintColor
		)
		
		let appearance = UINavigationBarAppearance()
		appearance.configureWithTransparentBackground()
		appearance.titleTextAttributes = [
			.font: Fonts.Navigation.Title.Small as Any,
			.foregroundColor: UIColor.white
		]
		appearance.largeTitleTextAttributes = [
			.font: Fonts.Navigation.Title.Large as Any,
			.foregroundColor: UIColor.white
		]
		appearance.buttonAppearance.normal.titleTextAttributes = [
			.font: Fonts.Navigation.Button as Any,
			.foregroundColor: UIColor.white
		]
		
		navigationBar.standardAppearance = appearance
		navigationBar.scrollEdgeAppearance = appearance
		navigationBar.compactAppearance = appearance
		navigationBar.tintColor = .white
		navigationItem.leftBarButtonItem?.tintColor = .white
	}
	
	private func restoreNavigationChrome() {
		
		guard let navigationBar = navigationController?.navigationBar,
			  let previous = previousNavAppearance else { return }
		
		navigationBar.standardAppearance = previous.standard
		navigationBar.scrollEdgeAppearance = previous.scroll
		navigationBar.compactAppearance = previous.compact
		navigationBar.tintColor = previous.tint
	}
	
	private func requestCameraAndStart() {
		
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			setupCamera()
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
				DispatchQueue.main.async {
					if granted {
						self?.setupCamera()
					} else {
						self?.presentCameraDenied()
					}
				}
			}
		default:
			presentCameraDenied()
		}
	}
	
	private func presentCameraDenied() {
		
		CM_Alert_ViewController.present(CM_Multiplayer_Error.unknown(String(key: "network.lobby.scan.cameraDenied"))) { [weak self] in
			self?.dismiss()
		}
	}
	
	private func setupCamera() {
		
		guard let device = AVCaptureDevice.default(for: .video),
			  let input = try? AVCaptureDeviceInput(device: device),
			  session.canAddInput(input) else {
			presentCameraDenied()
			return
		}
		
		session.beginConfiguration()
		session.addInput(input)
		
		let output = AVCaptureMetadataOutput()
		guard session.canAddOutput(output) else {
			session.commitConfiguration()
			presentCameraDenied()
			return
		}
		
		session.addOutput(output)
		output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
		output.metadataObjectTypes = [.qr]
		session.commitConfiguration()
		
		let preview = AVCaptureVideoPreviewLayer(session: session)
		preview.videoGravity = .resizeAspectFill
		preview.frame = view.bounds
		view.layer.insertSublayer(preview, at: 0)
		previewLayer = preview
		
		view.bringSubviewToFront(topFadeView)
		view.bringSubviewToFront(bottomFadeView)
		view.bringSubviewToFront(hintLabel)
		
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			self?.session.startRunning()
		}
	}
}

extension CM_QRCode_Scanner_ViewController: AVCaptureMetadataOutputObjectsDelegate {
	
	public func metadataOutput(_ output:AVCaptureMetadataOutput,
							   didOutput metadataObjects:[AVMetadataObject],
							   from connection:AVCaptureConnection) {
		
		guard !hasScanned,
			  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
			  object.type == .qr,
			  let value = object.stringValue,
			  let code = CM_QRCode.code(fromScanned: value) else { return }
		
		hasScanned = true
		session.stopRunning()
		CM_Audio.shared.playSound(.Success)
		CM_Feedback.shared.make(.On)
		
		let scannedCode = code
		
		if let navigationController, navigationController.viewControllers.count > 1 {
			navigationController.popViewController(animated: true)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
				self?.onCodeScanned?(scannedCode)
			}
		} else {
			dismiss { [weak self] in
				self?.onCodeScanned?(scannedCode)
			}
		}
	}
}

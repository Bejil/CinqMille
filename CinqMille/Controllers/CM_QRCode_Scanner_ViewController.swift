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
	
	private let scanHoleSize:CGFloat = 240
	private let overlayMaskLayer = CAShapeLayer()
	
	private lazy var overlayView:UIView = {
		
		$0.isUserInteractionEnabled = false
		$0.backgroundColor = UIColor.black.withAlphaComponent(0.65)
		return $0
		
	}(UIView())
	
	private lazy var scanFrameView:UIView = {
		
		$0.isUserInteractionEnabled = false
		$0.backgroundColor = .clear
		$0.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
		$0.layer.borderWidth = 2
		$0.layer.cornerRadius = 12
		$0.clipsToBounds = true
		return $0
		
	}(UIView())
	
	private lazy var laserView:UIView = {
		
		$0.backgroundColor = UIColor.systemRed
		$0.layer.shadowColor = UIColor.systemRed.cgColor
		$0.layer.shadowOpacity = 0.9
		$0.layer.shadowRadius = 6
		$0.layer.shadowOffset = .zero
		return $0
		
	}(UIView())
	
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
		
		view.addSubview(overlayView)
		view.addSubview(scanFrameView)
		scanFrameView.addSubview(laserView)
		view.addSubview(hintLabel)
		
		overlayView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
		
		scanFrameView.snp.makeConstraints { make in
			make.center.equalToSuperview()
			make.width.height.equalTo(scanHoleSize)
		}
		
		laserView.snp.makeConstraints { make in
			make.left.right.equalToSuperview().inset(4)
			make.top.equalToSuperview()
			make.height.equalTo(2)
		}
		
		hintLabel.snp.makeConstraints { make in
			make.left.right.equalToSuperview().inset(UI.Margins)
			make.top.equalTo(scanFrameView.snp.bottom).offset(UI.Margins * 1.5)
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
	
	public override func viewDidAppear(_ animated: Bool) {
		
		super.viewDidAppear(animated)
		startLaserAnimation()
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
		
		super.viewWillDisappear(animated)
		
		restoreNavigationChrome()
		stopLaserAnimation()
		
		if session.isRunning {
			session.stopRunning()
		}
	}
	
	public override func viewDidLayoutSubviews() {
		
		super.viewDidLayoutSubviews()
		previewLayer?.frame = view.bounds
		updateOverlayMask()
	}
	
	private func updateOverlayMask() {
		
		let holeRect = scanFrameView.convert(scanFrameView.bounds, to: overlayView)
		let path = UIBezierPath(rect: overlayView.bounds)
		let holePath = UIBezierPath(roundedRect: holeRect, cornerRadius: 12)
		path.append(holePath)
		path.usesEvenOddFillRule = true
		
		overlayMaskLayer.path = path.cgPath
		overlayMaskLayer.fillRule = .evenOdd
		overlayView.layer.mask = overlayMaskLayer
	}
	
	/// Accepte le QR s'il intersecte le cadre de scan (filtre UI, sans restreindre AVFoundation).
	private func isQRInsideScanFrame(_ object:AVMetadataMachineReadableCodeObject) -> Bool {
		
		guard let previewLayer,
			  let transformed = previewLayer.transformedMetadataObject(for: object) else {
			return true
		}
		
		let holeRect = scanFrameView.convert(scanFrameView.bounds, to: view).insetBy(dx: -12, dy: -12)
		return holeRect.intersects(transformed.bounds)
	}
	
	private func startLaserAnimation() {
		
		stopLaserAnimation()
		
		scanFrameView.layoutIfNeeded()
		let travel = max(0, scanFrameView.bounds.height - 2)
		
		laserView.transform = .identity
		laserView.layer.removeAllAnimations()
		
		UIView.animate(
			withDuration: 1.6,
			delay: 0,
			options: [.repeat, .curveEaseInOut, .allowUserInteraction]
		) { [weak self] in
			self?.laserView.transform = CGAffineTransform(translationX: 0, y: travel)
		}
	}
	
	private func stopLaserAnimation() {
		
		laserView.layer.removeAllAnimations()
		laserView.transform = .identity
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
		if output.availableMetadataObjectTypes.contains(.qr) {
			output.metadataObjectTypes = [.qr]
		}
		// Détection sur tout le flux ; le cadre est filtré ensuite dans le delegate
		output.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
		session.commitConfiguration()
		
		let preview = AVCaptureVideoPreviewLayer(session: session)
		preview.videoGravity = .resizeAspectFill
		preview.frame = view.bounds
		view.layer.insertSublayer(preview, at: 0)
		previewLayer = preview
		
		view.bringSubviewToFront(overlayView)
		view.bringSubviewToFront(scanFrameView)
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
		
		guard !hasScanned else { return }
		
		for metadata in metadataObjects {
			
			guard let object = metadata as? AVMetadataMachineReadableCodeObject,
				  object.type == .qr,
				  let value = object.stringValue,
				  let code = CM_QRCode.code(fromScanned: value),
				  isQRInsideScanFrame(object) else { continue }
			
			hasScanned = true
			session.stopRunning()
			stopLaserAnimation()
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
			return
		}
	}
}

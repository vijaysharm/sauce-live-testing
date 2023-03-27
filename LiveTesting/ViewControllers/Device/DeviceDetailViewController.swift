//
//  DeviceDetailViewController.swift
//  LiveTesting
//

import UIKit
import Combine
import Nuke
import NukeExtensions

class DeviceDetailViewController: ViewController {
	private var subscriptions = Set<AnyCancellable>()
	
	private let busy = SauceDeviceInUseView()
	private let imageView: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleAspectFit
		
		return view
	}()
	
	init(device: SauceDevice) {
		super.init(nibName: nil, bundle: nil)
		
		let deviceImageContainer = View()
		deviceImageContainer.addSubview(imageView)
		NSLayoutConstraint.activate([
			imageView.centerXAnchor.constraint(equalTo: deviceImageContainer.centerXAnchor),
			imageView.centerYAnchor.constraint(equalTo: deviceImageContainer.centerYAnchor),
			imageView.heightAnchor.constraint(equalTo: deviceImageContainer.heightAnchor, multiplier: 0.9),
			imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
			
			deviceImageContainer.heightAnchor.constraint(equalToConstant: 200)
		])
		
		if device.inUse {
			deviceImageContainer.addSubview(busy)
			NSLayoutConstraint.activate([
				busy.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
				busy.topAnchor.constraint(equalTo: deviceImageContainer.topAnchor),
			])
		}
		
		var options = ImageLoadingOptions()
		options.processors = device.inUse ? [
			ImageProcessors.CoreImageFilter(
				name: "CIColorMonochrome",
				parameters: [
					"inputIntensity": 1,
					"inputColor": CIColor(color: .white)
				],
				identifier: "live.testing.monochrome"
			)
		] : []
		NukeExtensions.loadImage(
			with: device.imageUrl,
			options: options,
			into: imageView
		)
		
		view.backgroundColor = UIColor.sauceLabs.lightGrey
		title = device.name
		
		let scrollView = ScrollableStackView(padding: 0, spacing: 0)
		scrollView.addView(Spacer(height: 8))
		scrollView.addView(deviceImageContainer)
		scrollView.addView(Spacer(height: 8))
		scrollView.addView(makeRow(key: "OS".loc, value: device.os))
		scrollView.addView(makeRow(key: "API Level".loc, value: device.osVersion))
		scrollView.addView(makeRow(key: "Screen".loc, value: "\(device.screenSize)\" | \(device.resolutionWidth)x\(device.resolutionHeight)"))
		scrollView.addView(makeRow(key: "CPU".loc, value: "\(device.cpuType) | \(device.cpuCores) cores | \(device.cpuFrequency) MHz"))
		scrollView.addView(makeRow(key: "RAM".loc, value: "\(device.ramSize) MB"))
		scrollView.addView(makeRow(key: "Internal Storage".loc, value: "\(device.internalStorageSize) MB"))
		scrollView.addView(makeRow(key: "Model Number".loc, value: device.modelNumber))
		scrollView.addView(makeRow(key: "ID".loc, value: device.descriptorId))
		scrollView.addView(makeRow(key: "Location".loc, value: device.dataCenterId))
//		scrollView.addView(makeRow(key: "Carrier Connectivity".loc, value: "Disabled".loc))
		
		view.addSubview(scrollView)
		fill(with: scrollView, useSafeArea: true)
		
		let cancelButton = SauceBarButtonItem(title: "Close".loc)
		cancelButton.onClicked.sink { [weak self] in
			self?.dismiss(animated: true)
		}.store(in: &subscriptions)
		self.navigationItem.leftBarButtonItem = cancelButton
	}
	
	func makeRow(key: String, value: String) -> View {
		let keyLabel = Label(text: key, textColor: .sauceLabs.darkGrey)
		keyLabel.font = .proximaSemiBold(size: UIFont.labelFontSize)
		
		let valueLabel = Label(text: value, textColor: .sauceLabs.darkGrey)
		valueLabel.font = .proximaLight(size: UIFont.labelFontSize)
		valueLabel.numberOfLines = 3
		
		let view = View()
		view.addSubview(keyLabel)
		view.addSubview(valueLabel)
		NSLayoutConstraint.activate([
			keyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
			keyLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
			keyLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
			keyLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
			
			valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 8),
			valueLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
			valueLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
			valueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
		])
		return view
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

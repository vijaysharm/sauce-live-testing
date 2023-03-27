//
//  CrossBrowserViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class CrossBrowserViewController: TabViewController<CrossBrowserModel, Void, CrossBrowserError>, RefreshableViewController {
	class ContentView: View {
		private let urlInput = SauceInput()
		private let devices: SauceSearchableListView<SauceDevice>
		
		init(model: CrossBrowserModel) {
			devices = SauceSearchableListView(
				model: model,
				configuration: SauceSearchableListCongiuration(
					maxHeight: 150,
					configureView: { list in
						list.register(SauceDeviceCell.self, forCellWithReuseIdentifier: "cell")
					},
					configureCell: { _, cell, _, device in
						guard let cell = cell as? SauceDeviceCell else { return }
						cell.set(device: device)
						cell.more = {
							model.showDeviceDetails.send(device)
						}
						cell.pin = {
							model.starDevice.send(device)
						}
					},
					configureLayout: nil,
					action: { _, device in
						guard let device = device, !device.inUse else { return }
						model.openSession.send(device)
					}
				)
			)
			super.init()
			
			let urlContainer = HStack()
			urlContainer.addArrangedSubview(SauceLabel(
				text: "\("URL".loc):"
			))
			urlContainer.addArrangedSubview(urlInput)
			urlContainer.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
			urlContainer.isLayoutMarginsRelativeArrangement = true
			
			urlInput.bind(to: model.url)
			urlInput.backgroundColor = UIColor.sauceLabs.white
			urlInput.placeholder = "URL you want to test!".loc
			urlInput.keyboardType = .URL
			urlInput.autocorrectionType = .no
			urlInput.autocapitalizationType = .none
			urlInput.textColor = .sauceLabs.black
			
			addSubview(urlContainer)
			addSubview(devices)
			pin(urlContainer, to: [.top(), .leading(), .trailing()], useSafeArea: true)
			pin(devices, to: [.bottom(), .leading(), .trailing()])
			NSLayoutConstraint.activate([
				devices.topAnchor.constraint(equalTo: urlContainer.bottomAnchor)
			])
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let model: CrossBrowserViewModel
	private let factory: CrossBrowserViewFactory
	
	private var contentView: ContentView?
	
	init(
		model: CrossBrowserViewModel,
		factory: CrossBrowserViewFactory
	) {
		self.model = model
		self.factory = factory
		super.init(
			title: "Cross Browser".loc,
			image: UIImage(systemName: "globe")!,
			state: model.state
		)
	}
	
	override func show(content: CrossBrowserModel) {
		self.contentView?.removeFromSuperview()
		self.contentView = self.fill(
			view: ContentView(model: content)
		)
		content.filters.showFilterView.sink { [weak self] in
			self?.showFilterView(model: content)
		}.store(in: &self.subscriptions)
		content.showDeviceDetails.sink { [weak self] in
			self?.showDetails(device: $0)
		}.store(in: &self.subscriptions)
		content.openSession.sink { [weak self] in
			self?.openSession(url: content.url.value, device: $0)
		}.store(in: &self.subscriptions)
		content.starDevice.sink {
			content.star(device: $0)
		}.store(in: &self.subscriptions)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		model.refresh()
	}
	
	func refresh() {
		model.refresh()
	}
	
	func showFilterView(model: CrossBrowserModel) {
		let vc = factory.makeFilterView(
			config: model.filterConfiguration
		)
		self.present(vc, animated: true)
	}
	
	func showDetails(device: SauceDevice) {
		let vc = factory.makeDeviceDetailsView(device: device)
		self.present(vc, animated: true)
	}
	
	func openSession(url: String, device: SauceDevice) {
		guard let url = URL(string: url) else {
			// TODO: Show error?
			return
		}
		
		let vc = factory.makeUrlSessionView(url: url, device: device)
		self.present(vc, animated: true)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


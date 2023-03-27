//
//  MobileAppViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class MobileAppViewController: TabViewController<MobileAppModel, Void, MobileAppError>, RefreshableViewController {
	class ContentView: View {
		private let apps: SauceSearchableListView<AppGroup>
		
		init(model: MobileAppModel) {
			apps = SauceSearchableListView(
				model: model,
				configuration: SauceSearchableListCongiuration(
					maxHeight: 150,
					configureView: { list in
						list.register(SauceAppGroupCell.self, forCellWithReuseIdentifier: "cell")
					},
					configureCell: { _, cell, _, group in
						guard let cell = cell as? SauceAppGroupCell else { return }
						cell.set(group: group)
						cell.settings = {
							model.showAppGroupSettings.send(group)
						}
						cell.files = {
							model.showAppGroupFiles.send(group)
						}
					},
					configureLayout: nil,
					action: { _, group in
						guard let group = group else { return }
						model.app.send(group)
					}
				)
			)
			super.init()
			
			addSubview(apps)
			fill(with: apps)
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let model: MobileAppViewModel
	private let factory: MobileAppViewFactory
	private var contentView: ContentView?
	
	init(
		model: MobileAppViewModel,
		factory: MobileAppViewFactory
	) {
		self.model = model
		self.factory = factory
		super.init(
			title: "Mobile App".loc,
			image: UIImage(systemName: "iphone")!,
			state: model.state
		)
	}
	
	override func show(content: MobileAppModel) {
		self.contentView?.removeFromSuperview()
		self.contentView = self.fill(
			view: ContentView(model: content)
		)
		
		content.showAppGroupSettings.sink { _ in
			print("TODO: showAppGroupSettings")
		}.store(in: &self.subscriptions)
		
		content.showAppGroupFiles.sink { [weak self] group in
			self?.showAppFileSelection(group: group, model: content)
		}.store(in: &self.subscriptions)
		content.app.sink { [weak self] group in
			self?.showDeviceSelection(group: group)
		}.store(in: &self.subscriptions)
		content.filters.showFilterView.sink { [weak self] in
			self?.showFilterView(model: content)
		}.store(in: &self.subscriptions)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
		self.tabBarController?.tabBar.isHidden = false
		super.viewWillAppear(animated)
	}
	
	func refresh() {
		model.refresh()
	}
	
	func showDeviceSelection(group: AppGroup) {
		let vc = factory.makeDeviceSelectionView(group: group, file: group.recent)
		vc.modalPresentationStyle = .fullScreen
		self.present(vc, animated: true)
	}
	
	func showAppFileSelection(group: AppGroup, model: MobileAppModel) {
		let vc = factory.makeAppFileSelectionView(model: model, group: group)
		self.present(vc, animated: true)
	}
	
	func showFilterView(model: MobileAppModel) {
		let config = SauceFilterViewConfig(
			sections: [
				SauceFilterTableSectionBuilder(
					title: "Platform".loc,
					keys: model.facets.platforms,
					values: model.filters.os.value,
					mapping: ["android": "Android", "ios": "iOS"],
					apply: model.filters.os.send
				)
			],
			apply: model.filters.filterCount.send
		)
		
		let vc = factory.makeFilterView(config: config)
		self.present(vc, animated: true)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

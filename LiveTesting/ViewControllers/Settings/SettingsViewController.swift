//
//  SettingsViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class SettingsViewController: TabViewController<SettingsModel, Void, SettingsError>, RefreshableViewController {
	private let model: SettingsViewModel
	private var contentView: SauceTableView?
	
	init(
		model: SettingsViewModel
	) {
		self.model = model
		super.init(
			title: "Settings".loc,
			image: UIImage(systemName: "gear")!,
			state: model.state
		)
	}
	
	override func show(content: SettingsModel) {
		contentView?.removeFromSuperview()

		let region: [(title: String, endpoint: String, location: String)] = [
			(title: "US West 1".loc, endpoint: "us-west-1", location: "US"),
//			(title: "US East 4".loc, endpoint: "us-east-1", location: "US"),
//			(title: "EU Central 1".loc, endpoint: "eu-central-1", location: "EU")
		]
		
		let regionSection = SauceTableSection(
			title: "Data Center",
			rows: Array.init(repeating: DefaultTableRow(), count: region.count),
			configure: { cell, row in
				let dataCenter = region[row]
				cell.textLabel?.text = dataCenter.title
				if content.dataCenter.value.endpoint == dataCenter.endpoint {
					cell.accessoryType = .checkmark
				} else {
					cell.accessoryType = .none
				}
			},
			action: { row, _, _ in
				let dataCenter = region[row]
				content.dataCenter.send((location: dataCenter.location, endpoint: dataCenter.endpoint))
			}
		)
		
		let help: [(title: String, url: String)] = [
			(title: "Support Portal".loc, url: "https://support.saucelabs.com"),
			(title: "Documentation".loc, url: "https://docs.saucelabs.com"),
			(title: "Status Page".loc, url: "https://status.saucelabs.com")
		]
		let helpSection = SauceTableSection(
			title: "Help and Support".loc,
			rows: Array.init(repeating: DefaultTableRow(), count: help.count),
			configure: { cell, row in
				cell.textLabel?.text = help[row].title
			},
			action: { row, _, _ in
				guard let url = URL(string: help[row].url) else { return }
				
				let controller = WebContentViewController(url: url)
				controller.title = help[row].title

				self.tabBarController?.tabBar.isHidden = true
				self.navigationController?.setNavigationBarHidden(false, animated: true)
				self.navigationController?.pushViewController(
					controller,
					animated: true
				)
			}
		)
		let aboutSection = SauceTableSection(
			title: "About".loc,
			rows: [
				DefaultTableRow(
					configure: { cell in
						let bundle = Bundle.main
						let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
						let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
						cell.textLabel?.text = "\("Version".loc) \(version) (\(buildVersion))"
					}
				)
			]
		)
		let logoutSection = SauceTableSection(
			title: nil,
			rows: [
				DefaultTableRow(
					configure: { cell in
						cell.textLabel?.text = "Logout".loc
						cell.textLabel?.textColor = .sauceLabs.red
					},
					action: { _, _ in
						self.model.logout()
					}
				)
			]
		)
		contentView = fill(view: SauceTableView(model: SauceTableConfig(
			data: SauceTableData(
				sections: [
					regionSection,
					helpSection,
					aboutSection,
					logoutSection
				]
			),
			style: .grouped
		)))
		
		// Make sure content view is in the view hierarchy before asking it to reload
		content.dataCenter.sink { _ in
			self.contentView?.reloadSections(IndexSet(integer: 0), with: .automatic)
		}.store(in: &subscriptions)
	}

	override func viewWillAppear(_ animated: Bool) {
		self.navigationController?.setNavigationBarHidden(true, animated: animated)
		self.tabBarController?.tabBar.isHidden = false
		super.viewWillAppear(animated)
		refresh()
	}
	
	func refresh() {
		model.refresh()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

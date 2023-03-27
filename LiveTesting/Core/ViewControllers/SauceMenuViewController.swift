//
//  SauceMenuViewController.swift
//  LiveTesting
//

import UIKit
import Combine


class SauceMenuViewController: ViewController {
	private var subscriptions = Set<AnyCancellable>()
	
	init(config: SauceTableConfig) {
		super.init(nibName: nil, bundle: nil)

		self.view.backgroundColor = UIColor.sauceLabs.lightGrey
		
		let tableView = SauceTableView(model: config)
		self.view.addSubview(tableView)
		self.fill(with: tableView)
		
		let cancelButton = SauceBarButtonItem(title: "Cancel".loc)
		cancelButton.onClicked.sink { [weak self] in
			self?.dismiss(animated: true)
		}.store(in: &subscriptions)
		self.navigationItem.leftBarButtonItem = cancelButton
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

//
//  FilterViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class FilterViewController: ViewController {
	private let filterView: SauceTableView
	private let config: SauceFilterViewConfig
	private let apply = SauceActionButton(title: "Apply Filter")

	private var subscriptions = Set<AnyCancellable>()
	
	init(config: SauceFilterViewConfig) {
		self.config = config
		self.filterView = SauceTableView(model: config)
		
		super.init(nibName: nil, bundle: nil)
		
		let applyContainer = View()
		applyContainer.addSubview(apply)
		
		self.view.backgroundColor = UIColor.sauceLabs.lightGrey
		self.title = "All filters".loc
		self.view.addSubview(filterView)
		self.view.addSubview(applyContainer)
		
		NSLayoutConstraint.activate([
			filterView.topAnchor.constraint(equalTo: view.topAnchor),
			filterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			filterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			
			applyContainer.topAnchor.constraint(equalTo: filterView.bottomAnchor),
			applyContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			applyContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			applyContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			
			apply.centerXAnchor.constraint(equalTo: applyContainer.centerXAnchor),
			apply.centerYAnchor.constraint(equalTo: applyContainer.centerYAnchor),
			applyContainer.heightAnchor.constraint(equalTo: apply.heightAnchor, constant: 4),
			apply.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
		])
		
		config.filterCountChanged.sink { [weak self] in
			self?.set(count: $0)
		}.store(in: &subscriptions)
		
		apply.onClicked.sink { [weak self] in
			self?.config.apply()
			self?.dismiss(animated: true)
		}.store(in: &subscriptions)
		
		let cancelButton = SauceBarButtonItem(title: "Cancel".loc)
		cancelButton.onClicked.sink { [weak self] in
			self?.dismiss(animated: true)
		}.store(in: &subscriptions)
		self.navigationItem.leftBarButtonItem = cancelButton
		
		let resetButton = SauceBarButtonItem(title: "Reset".loc)
		resetButton.onClicked.sink { [weak self] in
			self?.config.reset()
			self?.filterView.reloadData()
			self?.set(count: config.filterCountChanged.value)
		}.store(in: &subscriptions)
		self.navigationItem.rightBarButtonItem = resetButton
	}
	
	private func set(count: Int) {
		apply.setTitle("\("Apply".loc) \(count) \(count == 1 ? "Filter".loc : "Filters".loc)", for: .normal)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

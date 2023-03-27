//
//  RootViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class RootViewController: TabBarController {
	private let model: RootViewModel
	private let authenticationView: UIViewController
	
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		model: RootViewModel,
		controllers: [UIViewController],
		factory: AuthenticationFactory
	) {
		self.model = model
		self.authenticationView = factory.makeAuthenticationView()
		
		super.init(nibName: nil, bundle: nil)
		
		let appearance = UITabBarAppearance()
		appearance.backgroundColor = UIColor.sauceLabs.lightGreen
		setTabBarItemColors(appearance.stackedLayoutAppearance)
		setTabBarItemColors(appearance.inlineLayoutAppearance)
		setTabBarItemColors(appearance.compactInlineLayoutAppearance)
		self.tabBar.standardAppearance = appearance
		
		self.viewControllers = controllers
		self.title = "Live Testing"
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		authenticate(model.isAuthenticated.value)
		model.isAuthenticated.receive(on: DispatchQueue.main).sink { [weak self] in
			self?.authenticate($0)
		}.store(in: &subscriptions)
	}
	
	override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		let controller = self.viewControllers?.first {
			guard let tabBarItem = $0.tabBarItem, tabBarItem == item else {
				return false
			}
			return true
		}
		
		
		if let refreshable = controller as? RefreshableViewController {
			refreshable.refresh()
		}
		
		if let controller = controller as? UINavigationController {
			if let refreshable = controller.topViewController as? RefreshableViewController {
				refreshable.refresh()
			}
		}
	}
	
	private func authenticate(_ isAuthenticated: Bool) {
		// TODO: Should we instead hold on to an optional version of the view
		// and use the factory to create a new one each time?
		if isAuthenticated {
			authenticationView.dismiss(animated: true)
		} else {
			if authenticationView.view.superview != nil || authenticationView.isBeingPresented {
				return
			}
			self.present(authenticationView, animated: true)
		}
	}
	
	private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance) {
		itemAppearance.normal.iconColor = UIColor.sauceLabs.grey
		itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.sauceLabs.grey]
		
		itemAppearance.selected.iconColor = UIColor.sauceLabs.green
		itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.sauceLabs.black]
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

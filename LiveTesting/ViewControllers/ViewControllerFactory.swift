//
//  ViewControllerFactory.swift
//  LiveTesting
//

import UIKit

protocol AuthenticationFactory {
	func makeAuthenticationView() -> UIViewController
}

protocol CrossBrowserViewFactory {
	func makeFilterView(config: SauceFilterViewConfig) -> UIViewController
	func makeDeviceDetailsView(device: SauceDevice) -> UIViewController
	func makeUrlSessionView(url: URL, device: SauceDevice) -> UIViewController
}

protocol MobileAppViewFactory {
	func makeFilterView(config: SauceFilterViewConfig) -> UIViewController
	func makeDeviceSelectionView(group: AppGroup, file: AppGroupFile) -> UIViewController
	func makeAppFileSelectionView(model: MobileAppModel, group: AppGroup) -> UIViewController
}

protocol AppGroupFileViewFactory {
	func makeDeviceSelectionView(group: AppGroup, file: AppGroupFile) -> UIViewController
}

protocol SessionViewFactory {
	func makeSessionMenu(config: SauceTableConfig) -> UIViewController
}

protocol DeviceSelectionViewFactory {
	func makeDeviceDetailsView(device: SauceDevice) -> UIViewController
	func makeAppSessionView(group: AppGroup, file: AppGroupFile, device: SauceDevice) -> UIViewController
	func makeFilterView(config: SauceFilterViewConfig) -> UIViewController
}

class ViewControllerFactory {
	private let model: AppModel
	private let parser = DataParser()
	private let requestManager: RequestManager
	private let deviceService: DeviceService
	private let appService: AppService
	
	init(model: AppModel) {
		self.requestManager = RequestManager(
			apiManager: APIManager(
				urlSession: URLSession.shared
			),
			parser: self.parser
		)
		self.model = model
		self.deviceService = DeviceService(requestManager: self.requestManager, model: model)
		self.appService = AppService(requestManager: self.requestManager, model: model)
	}
	
	func makeRootView() -> UIViewController {
		let crossBrowser = CrossBrowserViewController(
			model: CrossBrowserViewModel(
				model: model,
				service: CrossBrowserService(
					requestManager: requestManager,
					deviceService: deviceService
				)
			),
			factory: self
		)
		let mobileApp = wrapInNavigationViewController(
			controller: MobileAppViewController(
				model: MobileAppViewModel(
					model: model,
					service: MobileAppService(
						requestManager: requestManager,
						service: appService
					)
				),
				factory: self
			)
		)
		let settings = wrapInNavigationViewController(
			controller: SettingsViewController(
				model: SettingsViewModel(
					model: model,
					service: SettingsService(
						requestManager: requestManager
					)
				)
			)
		)
		
		return RootViewController(
			model: RootViewModel(model: model),
			controllers: [crossBrowser, mobileApp, settings],
			factory: self
		)
	}
	
	func makeUrlSessionView(url: URL, device: SauceDevice) -> UIViewController {
		return SessionViewController(model: SessionViewModel(
			model: model,
			device: device,
			service: SessionViewService(
				requestManager: requestManager,
				startDeviceRequest: .open(device: device),
				startApplicationRequest: UrlSessionStartApplication(
					url: url,
					requestManager: requestManager
				)
			)
		), factory: self)
	}
	
	func makeAppSessionView(
		group: AppGroup,
		file: AppGroupFile,
		device: SauceDevice
	) -> UIViewController {
		return SessionViewController(model: SessionViewModel(
			model: model,
			device: device,
			service: SessionViewService(
				requestManager: requestManager,
				startDeviceRequest: .openWithNativeApp(group: group, file: file, device: device),
				startApplicationRequest: AppGroupSessionStartApplication(
					group: group,
					file: file,
					requestManager: requestManager
				)
			)
		), factory: self)
	}
	
	func makeFilterView(config: SauceFilterViewConfig) -> UIViewController {
		return wrapInNavigationViewController(controller: FilterViewController(
			config: config
		))
	}
	
	func makeDeviceDetailsView(device: SauceDevice) -> UIViewController {
		return wrapInNavigationViewController(controller: DeviceDetailViewController(device: device))
	}
	
	func makeSessionMenu(config: SauceTableConfig) -> UIViewController {
		let controller = SauceMenuViewController(config: config)
		controller.title = "Session Menu".loc
		
		return wrapInNavigationViewController(controller: controller)
	}
	
	func makeDeviceSelectionView(group: AppGroup, file: AppGroupFile) -> UIViewController {
		return wrapInNavigationViewController(controller:
			DeviceSelectionViewController(
				model: DeviceSelectionViewModel(
					model: self.model,
					factory: DeviceSelectionModelFactory(
						group: group,
						file: file
					),
					service: deviceService
				),
				factory: self
			)
		)
	}
	
	func makeAppFileSelectionView(model: MobileAppModel, group: AppGroup) -> UIViewController {
		return wrapInNavigationViewController(
			controller: AppGroupFileViewController(
				model: AppGroupFileViewModel(
					group: group,
					model: model,
					appModel: self.model,
					service: MobileAppService(
						requestManager: requestManager,
						service: appService
					)
				),
				factory: self
			)
		)
	}
	
	private func wrapInNavigationViewController(controller: UIViewController) -> UINavigationController {
		let navigation = NavigationController(
			rootViewController: controller
		)
		navigation.navigationBar.prefersLargeTitles = false
		
		navigation.navigationBar.barStyle = .black
		navigation.navigationBar.barTintColor = .sauceLabs.lightGreen;
		navigation.navigationBar.tintColor = .sauceLabs.green;
		navigation.navigationBar.titleTextAttributes = [
			.foregroundColor: UIColor.sauceLabs.darkGrey,
			.font: UIFont.proximaRegular(size: UIFont.systemFontSize)
		]
		
		return navigation
	}
}

extension ViewControllerFactory: AuthenticationFactory {
	func makeAuthenticationView() -> UIViewController {
		return AuthenticationViewController(
			model: AuthenticationViewModel(
				service: AuthenticationService(
					requestManager: requestManager
				),
				model: model
			)
		)
	}
}

extension ViewControllerFactory: DeviceSelectionViewFactory {}
extension ViewControllerFactory: AppGroupFileViewFactory {}
extension ViewControllerFactory: MobileAppViewFactory {}
extension ViewControllerFactory: CrossBrowserViewFactory {}
extension ViewControllerFactory: SessionViewFactory {}

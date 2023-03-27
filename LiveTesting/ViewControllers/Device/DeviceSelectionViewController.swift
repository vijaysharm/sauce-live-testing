//
//  DeviceSelectionViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class DeviceSelectionModel: SearchableItemModel {
	public let items: CurrentValueSubject<[SauceDevice], Never>
	public var facets: FilterableDeviceFacets {
		get {
			model.facets
		}
	}
	public let filters: AppliedDeviceFilters
	public let filterConfiguration: SauceFilterViewConfig

	public let showDeviceDetails = PassthroughSubject<SauceDevice, Never>()
	public let starDevice = PassthroughSubject<SauceDevice, Never>()
	public let openSession = PassthroughSubject<SauceDevice, Never>()
	public let group: AppGroup
	public let file: AppGroupFile
	
	private let model: DeviceModel
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		model: DeviceModel,
		group: AppGroup,
		file: AppGroupFile,
		filters: AppliedDeviceFilters,
		config: SauceFilterViewConfig
	) {
		self.filters = filters
		let initialValue = model.devices.value
			.filter(self.filters.filter)
			.sorted(by: self.filters.sort)
		self.items = CurrentValueSubject(initialValue)
		self.model = model
		self.group = group
		self.file = file
		
		self.filterConfiguration = config
		self.filters.onFiltersChanged.sink { [weak self] _ in
			self?.notify()
		}.store(in: &subscriptions)
		
		model.devices.receive(on: DispatchQueue.main).sink { [weak self] _ in
			self?.notify()
		}.store(in: &subscriptions)
	}
	
	func star(device: SauceDevice) {
		model.star(device: device)
	}
	
	private func notify() {
		items.send(
			model.devices.value
				.filter(filters.filter)
				.sorted(by: filters.sort)
		)
	}
}

class DeviceSelectionModelFactory {
	private let group: AppGroup
	private let file: AppGroupFile
	
	init(
		group: AppGroup,
		file: AppGroupFile
	) {
		self.group = group
		self.file = file
	}
	
	func create(from model: DeviceModel) -> DeviceSelectionModel {
		// from isAppStorageFileCompatibleWithRealDeviceDescriptor / filterFacetsByOs / prepareFacets
		var filters: [SauceFilter] = []
		var sections: [SauceFilterTableSectionBuilder] = []
		
		let os = CurrentValueSubject<[String], Never>([])
		let osVersion = CurrentValueSubject<[String], Never>([])
		let formFactor = CurrentValueSubject<[String], Never>([])
		let resolution = CurrentValueSubject<[String], Never>([])
		let manufacturer = CurrentValueSubject<[String], Never>([])
		let sort = CurrentValueSubject<DeviceSortOrder, Never>(.starredFirst)
		let compatibleDevices = model.devices.value
			.filter { $0.os.lowercased() == file.kind.lowercased() }
			.filter { device in
				if let minSdk = file.metadata.minSdk {
					return minSdk <= device.apiLevel
				}

				if let minOs = file.metadata.minOs {
					if let deviceFamily = file.metadata.deviceFamily {
						if !deviceFamily.isEmpty && !deviceFamily.contains(device.formFactor) {
//							return false
						}
					}
					return minOs.compare(device.osVersion, options: .numeric) != .orderedDescending
				}

				return true
			}
		
		// Sort
		sections.append(SauceFilterTableSectionBuilder(
			title: "Sort".loc,
			keys: [
				DeviceSortOrder.starredFirst.rawValue,
				DeviceSortOrder.aToZ.rawValue,
				DeviceSortOrder.zToA.rawValue
			],
			values: [sort.value.rawValue],
			mapping: [
				DeviceSortOrder.starredFirst.rawValue: "Pinned First".loc,
				DeviceSortOrder.aToZ.rawValue: "A to Z".loc,
				DeviceSortOrder.zToA.rawValue: "Z to A".loc
			],
			apply: {
				guard let first = $0.first, let sortValue = DeviceSortOrder(rawValue: first) else { return }
				sort.send(sortValue)
			},
			type: .exclusive,
			original: [sort.value.rawValue],
			count: 0
		))

		// OS
		if file.isAndroid {
			os.send(["ANDROID"])
		}

		if file.isIos {
			os.send(["IOS"])
		}
		
		filters.append(SauceFilter(
			applied: os,
			count: 0,
			strategy: { $0.contains($1.os) }
		))
		
		// Form Factor
		if UIDevice.current.userInterfaceIdiom == .phone {
			formFactor.send(["PHONE"])
			filters.append(SauceFilter(
				applied: formFactor,
				count: 0,
				strategy: { $0.contains($1.formFactor) }
			))
		} else {
			let availableFormFactors = compatibleDevices.map { $0.formFactor }
			let formFactors = ["PHONE", "TABLET"].filter { availableFormFactors.contains($0) }
			if !formFactors.isEmpty {
				if formFactors.count == 1 {
					formFactor.send(formFactors)
					filters.append(SauceFilter(
						applied: formFactor,
						count: 0,
						strategy: { $0.contains($1.formFactor) }
					))
				} else {
					filters.append(SauceFilter(
						applied: formFactor,
						strategy: { $0.contains($1.formFactor) }
					))
					if formFactors.count > 1 {
						sections.append(SauceFilterTableSectionBuilder(
							title: "Type".loc,
							keys: formFactors,
							values: formFactor.value,
							mapping: [
								"PHONE": "Phones only".loc,
								"TABLET": "Tablets only".loc
							],
							apply: formFactor.send
						))
					}
				}
			}
		}

		// OS Version
		let availableOsVersions = compatibleDevices.map { $0.osVersion }
		let osVersions = Array(model.facets.osVersion.keys)
			.filter { availableOsVersions.contains($0) }
		if !osVersions.isEmpty {
			if osVersions.count == 1 {
				osVersion.send(osVersions)
				filters.append(SauceFilter(
					applied: osVersion,
					count: 1,
					strategy: { $0.contains($1.osVersion) }
				))
			} else {
				filters.append(SauceFilter(
					applied: osVersion,
					strategy: { $0.contains($1.osVersion) }
				))
				sections.append(SauceFilterTableSectionBuilder(
					title: "OS Version".loc,
					keys: osVersions,
					values: osVersion.value,
					mapping: nil,
					apply: osVersion.send
				))
			}
		}

		// Manufacturer
		let availableManufacturers = compatibleDevices.flatMap { $0.manufacturers }
		let manufacturers = Array(model.facets.manufacturer.keys)
			.filter { availableManufacturers.contains($0) }
		if !manufacturers.isEmpty {
			if manufacturers.count == 1 {
				manufacturer.send(manufacturers)
				filters.append(SauceFilter(
					applied: manufacturer,
					count: 0,
					strategy: { manufacturers, device in
						let intersection = Array(Set(manufacturers).intersection(device.manufacturers))
						return !intersection.isEmpty
					}
				))
			} else {
				filters.append(SauceFilter(
					applied: manufacturer,
					strategy: { manufacturers, device in
						let intersection = Array(Set(manufacturers).intersection(device.manufacturers))
						return !intersection.isEmpty
					}
				))
				sections.append(SauceFilterTableSectionBuilder(
					title: "Brand".loc,
					keys: manufacturers,
					values: manufacturer.value,
					mapping: nil,
					apply: manufacturer.send
				))
			}
		}

		// Resolution
		let availbleResolutions = compatibleDevices.map { "\($0.resolutionWidth)x\($0.resolutionHeight)" }
		let resolutions = Array(model.facets.resolution.keys)
			.filter { availbleResolutions.contains($0) }
		if !resolutions.isEmpty {
			if resolutions.count == 1 {
				filters.append(SauceFilter(
					applied: resolution,
					count: 0,
					strategy: { $0.contains("\($1.resolutionWidth)x\($1.resolutionHeight)") }
				))
				resolution.send(resolutions)
			} else {
				filters.append(SauceFilter(
					applied: resolution,
					strategy: { $0.contains("\($1.resolutionWidth)x\($1.resolutionHeight)") }
				))
				sections.append(SauceFilterTableSectionBuilder(
					title: "Resolution".loc,
					keys: resolutions,
					values: resolution.value,
					mapping: nil,
					apply: resolution.send
				))
			}
		}
		
		return DeviceSelectionModel(
			model: model,
			group: group,
			file: file,
			filters: AppliedDeviceFilters(
				filters: filters,
				sort: sort
			),
			config: SauceFilterViewConfig(sections: sections)
		)
	}
}

class DeviceSelectionViewModel {
	public let state: CurrentValueSubject<ViewState<DeviceSelectionModel, Void, DeviceServiceError>, Never>
	
	private let service: DeviceService
	private let model: AppModel
	private let factory: DeviceSelectionModelFactory
	
	init(
		model: AppModel,
		factory: DeviceSelectionModelFactory,
		service: DeviceService
	) {
		self.state = CurrentValueSubject(.loading(()))
		self.model = model
		self.service = service
		self.factory = factory
	}
	
	func refresh() {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		Task {
			let deviceResult = await service.fetch(authentication: auth)
			switch deviceResult {
			case .failure(let error):
				state.send(.error(.unknown(error: error)))
				return
			case .success(let data):
				let model = self.factory.create(from: data)
				state.send(.content(data: model))
				break
			}
		}
	}
}

class DeviceSelectionViewController: ViewStateTabViewController<DeviceSelectionModel, Void, DeviceServiceError> {
	class ContentView: View {
		private let devices: SauceSearchableListView<SauceDevice>
		init(model: DeviceSelectionModel) {
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
			
			let header = SauceAppSelectionHeader(
				file: model.file,
				showVersion: true
			)
			addSubview(header)
			addSubview(devices)
			
			pin(header, to: [.top(), .leading(), .trailing()])
			pin(devices, to: [.bottom(), .leading(), .trailing()])
			
			NSLayoutConstraint.activate([
				devices.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4)
			])
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let mode: DeviceSelectionViewModel
	private let factory: DeviceSelectionViewFactory
	private var contentView: ContentView?
	
	init(
		model: DeviceSelectionViewModel,
		factory: DeviceSelectionViewFactory
	) {
		self.mode = model
		self.factory = factory
		super.init(state: model.state)
		
		self.title = "Select a Device".loc
		
		let cancelButton = SauceBarButtonItem(title: "Close".loc)
		cancelButton.onClicked.sink { [weak self] in
			self?.dismiss(animated: true)
		}.store(in: &subscriptions)
		self.navigationItem.leftBarButtonItem = cancelButton
		
		model.refresh()
	}
	
	override func show(content: DeviceSelectionModel) {
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
			self?.openSession(
				group: content.group,
				file: content.file,
				device: $0
			)
		}.store(in: &self.subscriptions)
		content.starDevice.sink {
			content.star(device: $0)
		}.store(in: &self.subscriptions)
	}
	
	func showFilterView(model: DeviceSelectionModel) {
		let vc = factory.makeFilterView(
			config: model.filterConfiguration
		)
		self.present(vc, animated: true)
	}
	
	func showDetails(device: SauceDevice) {
		let vc = factory.makeDeviceDetailsView(device: device)
		self.present(vc, animated: true)
	}
	
	func openSession(group: AppGroup, file: AppGroupFile, device: SauceDevice) {
		let vc = factory.makeAppSessionView(
			group: group,
			file: file,
			device: device
		)
		self.present(vc, animated: true)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

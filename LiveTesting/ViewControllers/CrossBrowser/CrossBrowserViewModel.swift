//
//  CrossBrowserViewModel.swift
//  LiveTesting
//

import Foundation
import Combine
import UIKit

enum CrossBrowserError: Error {
	case unknown(error: LocalizedError)
	case unauthorized
}

enum DeviceSortOrder: String {
	case aToZ = "aToZ"
	case zToA = "zToA"
	case starredFirst = "starredFirst"
}

class AppliedDeviceFilters: AppliedFacets {
	let textType = CurrentValueSubject<String, Never>("")
	let filters: [SauceFilter]
	let sort: CurrentValueSubject<DeviceSortOrder, Never>
	
	let filterCount = CurrentValueSubject<Int, Never>(0)
	let showFilterView = PassthroughSubject<Void, Never>()
	
	let onFiltersChanged = PassthroughSubject<Void, Never>()
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		filters: [SauceFilter],
		sort: CurrentValueSubject<DeviceSortOrder, Never>
	) {
		self.filters = filters
		self.sort = sort
		textType.receive(on: DispatchQueue.main).sink(receiveValue: self.notify).store(in: &subscriptions)
		filters.forEach { $0.applied.receive(on: DispatchQueue.main).sink(receiveValue: self.notify).store(in: &subscriptions) }
		sort.receive(on: DispatchQueue.main).sink(receiveValue: self.notify).store(in: &subscriptions)
		self.notify(nil)
	}
	
	func sort(_ a: SauceDevice, _ b: SauceDevice) -> Bool {
		switch sort.value {
		case .zToA:
			return a.name.lowercased() > b.name.lowercased()
		case .aToZ:
			return b.name.lowercased() > a.name.lowercased()
		case .starredFirst:
			if a.starred && !b.starred {
				return true
			}
			if b.starred && !a.starred {
				return false
			}
			return a.name.lowercased() < b.name.lowercased()
		}
	}
	
	func filter(_ device: SauceDevice) -> Bool {
		var isTrue = true
		if !textType.value.isEmpty {
			isTrue = isTrue && (device.name.lowercased().contains(textType.value.lowercased()) || device.descriptorId.lowercased().contains(textType.value.lowercased()))
		}
		
		return filters.reduce(isTrue, { $0 && $1.filter(device) })
	}
	
	private func notify(_ : Any?) {
		let count = filters.reduce(0, { $0 + $1.count })
		filterCount.send(count)
		onFiltersChanged.send()
	}
}

class CrossBrowserModel: SearchableItemModel {
	public let items: CurrentValueSubject<[SauceDevice], Never>
	public let filters: AppliedDeviceFilters
	public var facets: FilterableDeviceFacets {
		get {
			model.facets
		}
	}

	public let url = CurrentValueSubject<String, Never>("https://www.saucedemo.com/")
	public let showDeviceDetails = PassthroughSubject<SauceDevice, Never>()
	public let starDevice = PassthroughSubject<SauceDevice, Never>()
	public let openSession = PassthroughSubject<SauceDevice, Never>()
	public let filterConfiguration: SauceFilterViewConfig
	
	private var subscriptions = Set<AnyCancellable>()
	
	private let model: DeviceModel
	private let log = Logger.make(tag: CrossBrowserModel.self)
	
	init(
		model: DeviceModel,
		filters: AppliedDeviceFilters,
		config: SauceFilterViewConfig
	) {
		self.filters = filters
		let initialValue = model.devices.value
			.filter(self.filters.filter)
			.sorted(by: self.filters.sort)
		self.items = CurrentValueSubject(initialValue)
		self.model = model
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

class CrossBrowserViewModel {
	public let state: CurrentValueSubject<ViewState<CrossBrowserModel, Void, CrossBrowserError>, Never>
	
	private let service: CrossBrowserService
	private let model: AppModel
	
	init(
		model: AppModel,
		service: CrossBrowserService
	) {
		self.state = CurrentValueSubject(.loading(()))
		self.model = model
		self.service = service
	}
	
	func refresh() {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		state.send(.loading(()))
		service.devices(
			authentication: auth,
			progress: state
		)
	}
}

class CrossBrowserModelFactory {
	func create(from model: DeviceModel) -> CrossBrowserModel {
		var filters: [SauceFilter] = []
		var sections: [SauceFilterTableSectionBuilder] = []
		
		let os = CurrentValueSubject<[String], Never>([])
		let osVersion = CurrentValueSubject<[String], Never>([])
		let formFactor = CurrentValueSubject<[String], Never>([])
		let resolution = CurrentValueSubject<[String], Never>([])
		let manufacturer = CurrentValueSubject<[String], Never>([])
		let sort = CurrentValueSubject<DeviceSortOrder, Never>(.starredFirst)
		
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
		filters.append(SauceFilter(
			applied: os,
			strategy: { $0.contains($1.os) }
		))
		sections.append(SauceFilterTableSectionBuilder(
			title: "Platform".loc,
			keys: Array(model.facets.os.keys),
			values: os.value,
			mapping: ["IOS": "iOS", "ANDROID": "Android"],
			apply: os.send
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
			filters.append(SauceFilter(
				applied: formFactor,
				strategy: { $0.contains($1.formFactor) }
			))
			sections.append(SauceFilterTableSectionBuilder(
				title: "Type".loc,
				keys: ["PHONE", "TABLET"],
				values: formFactor.value,
				mapping: [
					"PHONE": "Phones only".loc,
					"TABLET": "Tablets only".loc
				],
				apply: formFactor.send
			))
		}

		// OS Version
		filters.append(SauceFilter(
			applied: osVersion,
			strategy: { $0.contains($1.osVersion) }
		))
		sections.append(SauceFilterTableSectionBuilder(
			title: "OS Version".loc,
			keys: Array(model.facets.osVersion.keys),
			values: osVersion.value,
			mapping: nil,
			apply: osVersion.send
		))
		
		// Manufacturer
		filters.append(SauceFilter(
			applied: manufacturer,
			strategy: { manufacturers, device in
				let intersection = Array(Set(manufacturers).intersection(device.manufacturers))
				return !intersection.isEmpty
			}
		))
		sections.append(SauceFilterTableSectionBuilder(
			title: "Brand".loc,
			keys: Array(model.facets.manufacturer.keys),
			values: manufacturer.value,
			mapping: nil,
			apply: manufacturer.send
		))
		
		// Resolution
		filters.append(SauceFilter(
			applied: resolution,
			strategy: { $0.contains("\($1.resolutionWidth)x\($1.resolutionHeight)") }
		))
		sections.append(SauceFilterTableSectionBuilder(
			title: "Resolution".loc,
			keys: Array(model.facets.resolution.keys),
			values: resolution.value,
			mapping: nil,
			apply: resolution.send
		))
		
		return CrossBrowserModel(
			model: model,
			filters: AppliedDeviceFilters(
				filters: filters,
				sort: sort
			),
			config: SauceFilterViewConfig(sections: sections)
		)
	}
}

struct CrossBrowserService {
	let requestManager: RequestManagerProtocol
	let deviceService: DeviceService
	let factory = CrossBrowserModelFactory()
}

extension CrossBrowserService {
	func devices(
		authentication: AuthenticationData,
		progress: CurrentValueSubject<ViewState<CrossBrowserModel, Void, CrossBrowserError>, Never>
	) {
		Task {
			let deviceResult = await deviceService.fetch(authentication: authentication)
			switch deviceResult {
			case .failure(let error):
				progress.send(.error(.unknown(error: error)))
				return
			case .success(let model):
				progress.send(.content(
					data: factory.create(from: model)
				))
				break
			}
		}
	}
}

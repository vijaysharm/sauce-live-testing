//
//  DeviceService.swift
//  LiveTesting
//

import Foundation
import Combine

class DeviceModel {
	public let devices = CurrentValueSubject<[SauceDevice], Never>([])
	public let facets: FilterableDeviceFacets
	
	private var starred: [String]
	private var availableDevices: [String]
	
	private let service: DeviceService
	private let allDevices: [FilterableDevice]
	private let appModel: AppModel
	private let log = Logger.make(tag: CrossBrowserModel.self)
	
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		devices: [FilterableDevice],
		availableDevices: [String],
		starred: [String],
		facets: FilterableDeviceFacets,
		service: DeviceService,
		appModel: AppModel
	) {
		self.allDevices = devices
		self.facets = facets
		self.availableDevices = availableDevices
		self.starred = starred
		self.service = service
		self.appModel = appModel
		
		let timer = Timer.TimerPublisher(
			interval: 30.0,
			runLoop: .main,
			mode: .default
		)
		timer.sink {_ in self.refreshAvailability()}.store(in: &subscriptions)
		timer.connect().store(in: &subscriptions)
		appModel.credentials.sink { [weak self] in
			if $0 == nil {
				self?.subscriptions.forEach { $0.cancel() }
			}
		}.store(in: &subscriptions)
		
		self.notify()
	}
	
	func star(device: SauceDevice) {
		guard let auth = appModel.credentials.value else {
			log.e("Not authorized to get device availability")
			return
		}
		
		if starred.contains(device.compositeId) {
			starred = starred.filter { $0 != device.compositeId }
		} else {
			starred.append(device.compositeId)
		}
		
		service.star(devices: starred, authentication: auth) { [weak self] result in
			switch result {
			case .success(let starred):
				self?.starred = starred
				self?.notify()
				break
			default:
				return
			}
		}
	}
	
	func refreshAvailability() {
		guard let auth = appModel.credentials.value else {
			log.e("Not authorized to get device availability")
			return
		}
		
		service.available(authentication: auth) { [weak self] result in
			switch result {
			case .success(let availability):
				self?.availableDevices = availability
				self?.notify()
				break
			default:
				return
			}
		}
	}
	
	private func notify() {
		self.devices.send(allDevices.map {
			SauceDevice(
				device: $0,
				inUse: !availableDevices.contains($0.descriptorId),
				starred: starred.contains($0.compositeId)
			)
		})
	}
}

enum DeviceServiceError: LocalizedError {
	case unauthorized
	case unknown(error: LocalizedError)
}

struct DeviceService {
	let requestManager: RequestManagerProtocol
	let model: AppModel
}

extension DeviceService {
	func fetch(authentication: AuthenticationData) async -> Result<DeviceModel, DeviceServiceError> {
		let deviceResult: Result<FilterableDevices, NetworkError> = await requestManager.perform(
			DeviceRequest.devices,
			authentication
		)
		var filterableDevices: FilterableDevices? = nil
		switch deviceResult {
		case .failure(let error):
			return .failure(.unknown(error: error))
		case .success(let model):
			filterableDevices = model
			break
		}
		
		guard let filterableDevices = filterableDevices else {
			return .failure(.unknown(error: NetworkError.invalidServerResponse))
		}
		
		let availabilityResult: Result<[String], NetworkError> = await requestManager.perform(
			DeviceRequest.available,
			authentication
		)
		
		var availability: [String] = []
		switch availabilityResult {
		case .failure(let error):
			return .failure(.unknown(error: error))
		case .success(let model):
			availability = model
			break
		}
		
		let metaDataResult: Result<Metadata, NetworkError> = await requestManager.perform(
			DeviceRequest.metadata,
			authentication
		)
		
		var starredDevices: [String] = []
		switch metaDataResult {
		case .failure(let error):
			return .failure(.unknown(error: error))
		case .success(let model):
			model.items.forEach {
				switch $0 {
				case .realDeviceStarredByCompositeId(let devices):
					starredDevices = devices
					break
				default:
					break
				}
			}
			break
		}
		
		// TODO: Should we cache the results?
		return .success(DeviceModel(
			devices: filterableDevices.entities,
			availableDevices: availability,
			starred: starredDevices,
			facets: filterableDevices.facets,
			service: self,
			appModel: model
		))
	}
	
	func available(
		authentication: AuthenticationData,
		_ queue: DispatchQueue = .main,
		callback: @escaping (Result<[String], DeviceServiceError>) -> Void
	) {
		Task {
			let result: Result<[String], NetworkError> = await requestManager.perform(
				DeviceRequest.available,
				authentication
			)
			queue.async {
				switch result {
				case .success(let model):
					callback(.success(model))
					break
				case .failure(let error):
					callback(.failure(.unknown(error: error)))
					break
				}
			}
		}
	}
	
	func star(
		devices: [String],
		authentication: AuthenticationData,
		_ queue: DispatchQueue = .main,
		callback: @escaping (Result<[String], DeviceServiceError>) -> Void
	) {
		Task {
			let result: Result<StarredDevice, NetworkError> = await requestManager.perform(
				DeviceRequest.setStarred(devices: devices),
				authentication
			)
			
			queue.async {
				switch result {
				case .success(let model):
					callback(.success(model.item.value))
					break
				case .failure(let error):
					callback(.failure(.unknown(error: error)))
					break
				}
			}
		}
	}
}

//
//  MobileAppViewModel.swift
//  LiveTesting
//

import Foundation
import Combine

enum MobileAppError: Error {
	case unknown(error: LocalizedError)
	case unauthorized
}

class MobileAppModel: SearchableItemModel {
	public var items: CurrentValueSubject<[AppGroup], Never> {
		get {
			model.groups
		}
	}
	public var facets: FilterableAppGroupFacets {
		get {
			model.facets
		}
	}
	public var filters: AppliedAppGroupFilters {
		get {
			model.filters
		}
	}
	public let showAppGroupFiles = PassthroughSubject<AppGroup, Never>()
	public let showAppGroupSettings = PassthroughSubject<AppGroup, Never>()
	public let app = PassthroughSubject<AppGroup, Never>()
	
	private let model: AppGroupModel
	
	init(model: AppGroupModel) {
		self.model = model
	}
}

class AppGroupFileModel: ItemModel {
	public var items: CurrentValueSubject<[AppGroupFile], Never>
	public let group: AppGroup
	public let file = PassthroughSubject<AppGroupFile, Never>()
	private let service: MobileAppService
	private let appModel: MobileAppModel
	
	init(
		files: [AppGroupFile],
		group: AppGroup,
		service: MobileAppService,
		model: MobileAppModel
	) {
		self.items = CurrentValueSubject<[AppGroupFile], Never>(files)
		self.group = group
		self.service = service
		self.appModel = model
	}
}

class MobileAppViewModel {
	public let state = CurrentValueSubject<ViewState<MobileAppModel, Void, MobileAppError>, Never>(.loading(()))
	
	private let service: MobileAppService
	private let model: AppModel
	
	init(
		model: AppModel,
		service: MobileAppService
	) {
		self.model = model
		self.service = service
	}
	
	func refresh() {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		state.send(.loading(()))
		service.groups(authentication: auth, progress: state)
	}
}

struct MobileAppService {
	let requestManager: RequestManagerProtocol
	let service: AppService
}

extension MobileAppService {
	func groups(
		authentication: AuthenticationData,
		progress: CurrentValueSubject<ViewState<MobileAppModel, Void, MobileAppError>, Never>
	) {
		Task {
			let appGroupResult: Result<AppGroupModel, AppServiceError> = await service.groups(authentication: authentication)
			switch appGroupResult {
			case .failure(let error):
				progress.send(.error(.unknown(error: error)))
				return
			case .success(let model):
				progress.send(.content(data: MobileAppModel(model: model)))
				return
			}
		}
	}
	
	func files(
		from group: AppGroup,
		authentication: AuthenticationData,
		_ queue: DispatchQueue = .main,
		callback: @escaping (Result<[AppGroupFile], MobileAppError>) -> Void
	) {
		Task {
			let appFilesResult: Result<[AppGroupFile], AppServiceError> = await service.files(from: group, authentication: authentication)
			queue.async {
				switch appFilesResult {
				case .failure(let error):
					callback(.failure(.unknown(error: error)))
					return
				case .success(let files):
					callback(.success(files))
					return
				}
			}
		}
	}
}

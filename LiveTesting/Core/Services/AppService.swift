//
//  AppService.swift
//  LiveTesting
//

import Foundation
import Combine

struct FilterableAppGroupFacets: SearchableFacets {
	let platforms = ["android", "ios"]
}

struct AppliedAppGroupFilters: AppliedFacets {
	let os = CurrentValueSubject<[String], Never>([])
	
	let textType = CurrentValueSubject<String, Never>("")
	let filterCount = CurrentValueSubject<Int, Never>(0)
	let showFilterView = PassthroughSubject<Void, Never>()
	
	func sort(_ a: AppGroup, _ b: AppGroup) -> Bool {
		b.name.lowercased() > a.name.lowercased()
	}
	
	func filter(_ group: AppGroup) -> Bool {
		var isTrue = true
		if !textType.value.isEmpty {
			isTrue = isTrue && (group.name.lowercased().contains(textType.value.lowercased()))
		}
		
		if !os.value.isEmpty {
			isTrue = isTrue && os.value.contains(group.recent.kind)
		}
		
		return isTrue
	}
}

enum AppServiceError: LocalizedError {
	case unknown(error: LocalizedError)
}

class AppGroupModel {
	public let groups = CurrentValueSubject<[AppGroup], Never>([])
	public let facets: FilterableAppGroupFacets
	public let filters: AppliedAppGroupFilters
	
	private let allGroups: [AppGroup]
	private let service: AppService
	private let appModel: AppModel
	
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		groups: [AppGroup],
		facets: FilterableAppGroupFacets,
		filters: AppliedAppGroupFilters,
		service: AppService,
		model: AppModel
	) {
		self.allGroups = groups
		self.facets = facets
		self.filters = filters
		self.service = service
		self.appModel = model
		
		filters.textType
			.sink {_ in self.notify() }.store(in: &subscriptions)

		filters.os
			.sink {_ in self.notify() }.store(in: &subscriptions)

		self.notify()
	}
	
	private func notify() {
		groups.send(
			allGroups.filter(filters.filter).sorted(by: filters.sort)
		)
	}
}

struct AppService {
	let requestManager: RequestManagerProtocol
	let model: AppModel
}

extension AppService {
	func groups(authentication: AuthenticationData) async -> Result<AppGroupModel, AppServiceError> {
		var page = 1
		let pageSize = 25
		var groups: [AppGroup] = []
		
		while true {
			let groupsResult: Result<AppGroups, NetworkError> = await requestManager.perform(
				AppRequest.groups(page: page, perPage: pageSize),
				authentication
			)
			
			switch groupsResult {
			case .failure(let error):
				return .failure(.unknown(error: error))
			case .success(let model):
				groups.append(contentsOf: model.items)
				
				let maxPages: Int = Int(ceil(Float(model.totalItems) / Float(pageSize)))
				if page >= maxPages {
					// TODO: Should we cache the results?
					return .success(AppGroupModel(
						groups: groups,
						facets: FilterableAppGroupFacets(),
						filters: AppliedAppGroupFilters(),
						service: self,
						model: self.model
					))
				}
				
				page += 1
			}
		}
	}
	
	func files(from group: AppGroup, authentication: AuthenticationData) async -> Result<[AppGroupFile], AppServiceError> {
		var page = 1
		let pageSize = 25
		var files: [AppGroupFile] = []
		
		while true {
			let groupsResult: Result<AppGroupFiles, NetworkError> = await requestManager.perform(
				AppRequest.files(groupId: group.id, page: page, perPage: pageSize),
				authentication
			)
			
			switch groupsResult {
			case .failure(let error):
				return .failure(.unknown(error: error))
			case .success(let model):
				files.append(contentsOf: model.items)
				
				let maxPages: Int = Int(ceil(Float(model.totalItems) / Float(pageSize)))
				if page >= maxPages {
					return .success(files)
				}
				
				page += 1
			}
		}
	}
}

//
//  SettingsViewModel.swift
//  LiveTesting
//

import Foundation
import Combine

enum SettingsError: Error {
	case unknown(error: LocalizedError)
	case unauthorized
}

struct SettingsModel {
	let dataCenter: CurrentValueSubject<(location: String, endpoint: String), Never>
}

class SettingsViewModel {
	public let state = CurrentValueSubject<ViewState<SettingsModel, Void, SettingsError>, Never>(.loading(()))
	private let model: AppModel
	private let service: SettingsService
	
	init(
		model: AppModel,
		service: SettingsService
	) {
		self.model = model
		self.service = service
	}
	
	func logout() {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		service.logout(
			authentication: auth,
			model: model
		)
	}
	
	func refresh() {
		state.send(.content(
			data: SettingsModel(
				dataCenter: CurrentValueSubject((
					location: model.location ?? "US",
					endpoint: model.credentials.value?.endpoint ?? "us-west-1"
				))
			)
		))
	}
}

struct SettingsService {
	let requestManager: RequestManagerProtocol
}

extension SettingsService {
	func logout(
		authentication: AuthenticationData,
		model: AppModel
	) {
		Task {
			let _: Result<String, NetworkError> = await requestManager.perform(
				AuthTokenRequest.logout,
				authentication
			)
			model.credentials.send(nil)
		}
	}
}

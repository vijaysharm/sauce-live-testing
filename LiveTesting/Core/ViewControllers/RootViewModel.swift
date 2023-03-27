//
//  RootViewModel.swift
//  LiveTesting
//

import Foundation
import Combine

class RootViewModel {
	public let isAuthenticated: CurrentValueSubject<Bool, Never>

	private var subscriptions = Set<AnyCancellable>()
	
	init(model: AppModel) {
		self.isAuthenticated = CurrentValueSubject(model.credentials.value?.isValid ?? false)
		model.credentials.sink {
			self.isAuthenticated.send($0?.isValid ?? false)
		}.store(in: &subscriptions)
	}
}

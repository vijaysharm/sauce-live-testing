//
//  AuthenticationViewModel.swift
//  LiveTesting
//

import Foundation
import Combine

class AuthenticationViewModel {
	public let error: CurrentValueSubject<String?, Never>
	public let username: CurrentValueSubject<String?, Never>
	public let password: CurrentValueSubject<String?, Never>
	public let buttonEnabled: CurrentValueSubject<Bool, Never>
	public let showProgress: CurrentValueSubject<Bool, Never>
	
	private let service: AuthenticationService
	private let model: AppModel
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		service: AuthenticationService,
		model: AppModel
	) {
		self.service = service
		self.model = model
		self.error = CurrentValueSubject<String?, Never>(nil)
		self.buttonEnabled = CurrentValueSubject<Bool, Never>(false)
		self.showProgress = CurrentValueSubject<Bool, Never>(false)
		self.username = CurrentValueSubject<String?, Never>(model.credentials.value?.username)
		self.password = CurrentValueSubject<String?, Never>(model.credentials.value?.password)
		
		username.sink {
			let isEnabled = self.isValid(text: $0) &&
				self.isValid(text: self.password.value)
			self.buttonEnabled.send(isEnabled)
		}.store(in: &subscriptions)
		
		password.sink {
			let isEnabled = self.isValid(text: $0) &&
				self.isValid(text: self.username.value)
			self.buttonEnabled.send(isEnabled)
		}.store(in: &subscriptions)
		
		model.credentials.receive(on: DispatchQueue.main).sink {
			guard let credentials = $0 else { return }
			self.username.send(credentials.username)
			self.password.send(credentials.password)
		}.store(in: &subscriptions)
	}
}

extension AuthenticationViewModel {
	func isValid() -> Bool {
		guard let username = username.value, let password = password.value else {
			return false
		}
		return isValid(text: username) && isValid(text: password)
	}
	
	func login() {
		guard let username = username.value, let password = password.value else {
			error.send("Username or password cannot be empty".loc)
			return
		}

		showProgress.send(true)
		service.authenticate(username, password) { result in
			self.showProgress.send(false)
			switch result {
			case .success(let token):
				let credentials = AuthenticationData(
					token: token, username: username, password: password
				)
				self.model.credentials.send(credentials)
				break
			case .failure(let reason):
				self.model.credentials.send(nil)
				// TODO: Get the error from the repsonse itself
				self.error.send("\(reason.localizedDescription)")
				break
			}
		}
	}
	
	private func isValid(text: String?) -> Bool {
		guard let text = text else {
			return false
		}
		let trimmed = text.trimmingCharacters(
			in: CharacterSet.whitespacesAndNewlines
		)
		
		return !trimmed.isEmpty
	}
}

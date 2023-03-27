//
//  AppModel.swift
//  LiveTesting
//

import Foundation
import Combine

class AppModel {
	private let log = Logger.make(tag: AppModel.self)
	public let credentials: CurrentValueSubject<AuthenticationData?, Never>
	
	private var subscriptions = Set<AnyCancellable>()
	
	var location: String? {
		get {
			credentials.value?.location
		}
	}
	
	init(authentication: AuthenticationData?) {
		credentials = CurrentValueSubject(authentication)
		credentials.sink {
			// TODO: Store preferred geo localtion, and on credential change,
			// TODO: set the location if not nil (??). i.e. set only if not already set
			
			if let login = $0 { self.log.i("New login: \(login)") }
			else { self.log.i("Logged out") }
		}.store(in: &subscriptions)
	}
}

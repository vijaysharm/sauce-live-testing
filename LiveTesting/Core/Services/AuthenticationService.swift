//
//  AuthenticationService.swift
//  LiveTesting
//

import Foundation

struct AuthenticationService {
	let requestManager: RequestManagerProtocol
}

extension AuthenticationService {
	func authenticate(
		_ username: String,
		_ password: String,
		_ queue: DispatchQueue = .main,
		callback: @escaping (Result<AuthenticationToken, Error>) -> Void
	) {
		let request = AuthTokenRequest.auth(
			username: username,
			password: password
		)
		
		Task {
			let result: Result<AuthenticationToken, NetworkError> = await requestManager.authenticate(request)
			queue.async {
				switch result {
				case .success(let token):
					callback(.success(token))
					break
				case .failure(let reason):
					callback(.failure(reason))
					break
				}
			}
		}
	}
}

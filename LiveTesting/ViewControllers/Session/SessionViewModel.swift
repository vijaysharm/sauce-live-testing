//
//  SessionViewModel.swift
//  LiveTesting
//

import Foundation
import Combine

enum SessionError: Error {
	case deviceError
	case unauthorized
	case request(error: LocalizedError)
}

struct SessionModel {
	let session: SauceDeviceSession
	let descriptor: SauceSessionDescriptor
	let companion: SauceDeviceCompanionConnection
	let alternativeIo: SauceAlternativeIoConnection
	let source: TwilioWrapper
}

enum SessionLoadingProgress {
	case initializing
	case started(session: SauceDeviceSession)
	case screen(souce: TwilioWrapper)
	case descriptor(session: SauceSessionDescriptor)
	case deviceConnected(connection: SauceDeviceCompanionConnection)
	case deviceOnline(connection: SauceDeviceCompanionConnection)
}

class SessionViewModel {
	public let state: CurrentValueSubject<ViewState<SessionModel, SessionLoadingProgress, SessionError>, Never>
	
	private let service: SessionViewService
	private let model: AppModel
	private let device: SauceDevice
	
	init(
		model: AppModel,
		device: SauceDevice,
		service: SessionViewService
	) {
		self.device = device
		self.state = CurrentValueSubject(.loading(.initializing))
		self.model = model
		self.service = service
	}
	
	func start() {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		state.send(.loading(.initializing))
		service.connect(authentication: auth, progress: state)
	}
	
	func send(orientation: DeviceOrientation, to session: SauceDeviceSession) {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		service.send(
			request: .orientation(orientation, session: session),
			authentication: auth
		)
	}
	
	func send(pasteText: String, to session: SauceDeviceSession) {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		service.send(
			request: .paste(text: pasteText, session: session),
			authentication: auth
		)
	}
	
	func restart(session: SauceDeviceSession) {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		service.send(
			request: .relaunchApp(session: session),
			authentication: auth
		)
	}
	
	func stop(session: SauceDeviceSession) {
		guard let auth = model.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		
		service.send(
			request: SessionRequest.close(session: session),
			authentication: auth
		)
	}
}

protocol SessionStartApplicationProtocol {
	func start(
		with session: SauceDeviceSession,
		authentication: AuthenticationData
	) async -> Result<Void, NetworkError>
}

class UrlSessionStartApplication: SessionStartApplicationProtocol {
	private let requestManager: RequestManagerProtocol
	private let url: URL
	
	init(
		url: URL,
		requestManager: RequestManagerProtocol
	) {
		self.url = url
		self.requestManager = requestManager
	}
	
	func start(
		with session: SauceDeviceSession,
		authentication: AuthenticationData
	) async -> Result<Void, NetworkError> {
		let startAppResult: Result<SauceOpenUrlOnDeviceResponse, NetworkError> = await requestManager.perform(
			SessionRequest.openUrl(session: session, url: url),
			authentication
		)
		
		switch startAppResult {
		case .failure(let error):
			return .failure(error)
		case .success:
			return .success(())
		}
	}
}

class AppGroupSessionStartApplication: SessionStartApplicationProtocol {
	private let requestManager: RequestManagerProtocol
	private let group: AppGroup
	private let file: AppGroupFile
	init(
		group: AppGroup,
		file: AppGroupFile,
		requestManager: RequestManagerProtocol
	) {
		self.group = group
		self.file = file
		self.requestManager = requestManager
	}
	
	func start(
		with session: SauceDeviceSession,
		authentication: AuthenticationData
	) async -> Result<Void, NetworkError> {
		let startAppResult: Result<SauceInstallationProgressResponse, NetworkError> = await requestManager.perform(
			SessionRequest.install(session: session, group: group, file: file),
			authentication
		)
		
		switch startAppResult {
		case .failure(let error):
			return .failure(error)
		case .success(let response):
			let installationResponse = await waitOnInstallation(from: response, with: session, authentication: authentication)
			switch installationResponse {
			case .failure(let error):
				return .failure(error)
			case .success:
				return .success(())
			}
		}
	}
	
	private func waitOnInstallation(
		from status: SauceInstallationProgressResponse,
		with session: SauceDeviceSession,
		authentication: AuthenticationData
	) async -> Result<Void, NetworkError> {
		let timeout = DispatchTime.now() + (2 * 60)
		while true {
			let installationResult: Result<SauceInstallationProgressResponse, NetworkError> = await requestManager.perform(
				SessionRequest.installationStatus(session: session, id: status.id),
				authentication
			)
			
			switch installationResult {
			case .failure(let error):
				return .failure(error)
			case .success(let response):
				if response.status == .finished {
					return .success(())
				} else if response.status == .error {
					return .failure(.unauthorized)
				}
			}
			
			let now = DispatchTime.now()
			if now > timeout {
				return .failure(.unauthorized)
			}
			
			try? await Task.sleep(for: Duration.milliseconds(100))
		}
	}
}

class SessionViewService {
	private let requestManager: RequestManagerProtocol
	private let startDeviceRequest: SessionRequest
	private let startApplicationRequest: SessionStartApplicationProtocol

	private var subscriptions = Set<AnyCancellable>()
	
	init(
		requestManager: RequestManagerProtocol,
		startDeviceRequest: SessionRequest,
		startApplicationRequest: SessionStartApplicationProtocol
	) {
		self.requestManager = requestManager
		self.startDeviceRequest = startDeviceRequest
		self.startApplicationRequest = startApplicationRequest
	}
}

extension SessionViewService {
	func connect(
		authentication: AuthenticationData,
		progress: CurrentValueSubject<ViewState<SessionModel, SessionLoadingProgress, SessionError>, Never>
	) {
		Task {
			let deviceResult: Result<SauceDeviceSession, NetworkError> = await requestManager.perform(
				startDeviceRequest,
				authentication
			)
			
			var session: SauceDeviceSession? = nil
			switch deviceResult {
			case .failure(let error):
				progress.send(.error(.request(error: error)))
				return
			case .success(let model):
				session = model
				break
			}
			
			guard let session = session else {
				progress.send(.error(.request(error: NetworkError.invalidServerResponse)))
				return
			}
			progress.send(.loading(.started(session: session)))
			
			// TODO: Also send device orientation here so the initial descriptor has the expected value PORTRAIT,
			
			let source = TwilioWrapper(credentials: session.webRtcCredentials)
			progress.send(.loading(.screen(souce: source)))
			
			let descriptorResult: Result<SauceSessionDescriptor, NetworkError> = await requestManager.perform(
				SessionRequest.deviceDescriptor(session: session),
				authentication
			)
			
			var descriptor: SauceSessionDescriptor? = nil
			switch descriptorResult {
			case .failure(let error):
				progress.send(.error(.request(error: error)))
				return
			case .success(let model):
				descriptor = model
				break
			}
			
			guard let descriptor = descriptor else {
				progress.send(.error(.request(error: NetworkError.invalidServerResponse)))
				return
			}
			progress.send(.loading(.descriptor(session: descriptor)))
			
			let deviceDelegate = WebSocketConnectionDelegate()
			let webSocketResult = requestManager.makeWebsocket(
				DeviceWebSocketRequest.companion(session: session),
				authentication,
				deviceDelegate
			)

			var deviceWebSocket: SauceWebSocket? = nil
			switch webSocketResult {
			case .failure(let error):
				progress.send(.error(.request(error: error)))
				return
			case .success(let socket):
				deviceWebSocket = socket
				break
			}
			
			guard let deviceWebSocket = deviceWebSocket else {
				progress.send(.error(.request(error: NetworkError.invalidServerResponse)))
				return
			}
			
			let companion = SauceDeviceCompanionConnection(
				socket: deviceWebSocket,
				delegate: deviceDelegate
			)
			
			progress.send(.loading(.deviceConnected(connection: companion)))

			let ioDelegate = WebSocketConnectionDelegate()
			let ioWebSocketResult = requestManager.makeWebsocket(
				DeviceWebSocketRequest.alternativeIo(session: session),
				authentication,
				ioDelegate
			)

			var ioWebSocket: SauceWebSocket? = nil
			switch ioWebSocketResult {
			case .failure(let error):
				progress.send(.error(.request(error: error)))
				return
			case .success(let socket):
				ioWebSocket = socket
				break
			}
			
			guard let ioWebSocket = ioWebSocket else {
				progress.send(.error(.request(error: NetworkError.invalidServerResponse)))
				return
			}
			
			let alternativeIo = SauceAlternativeIoConnection(
				socket: ioWebSocket,
				delegate: ioDelegate
			)
			
			let targetState = CompanionStatusUpdateMessage.StateType.ONLINE
			let deviceState = await waitForDeviceState(companion, target: targetState)
			guard deviceState == targetState else {
				progress.send(.error(.request(error: NetworkError.invalidServerResponse)))
				return
			}
			progress.send(.loading(.deviceOnline(connection: companion)))
			
			let startAppResult: Result<Void, NetworkError> = await startApplicationRequest.start(
				with: session,
				authentication: authentication
			)
			
			switch startAppResult {
			case .failure(let error):
				progress.send(.error(.request(error: error)))
				return
			case .success:
				progress.send(.content(data: SessionModel(
					session: session,
					descriptor: descriptor,
					companion: companion,
					alternativeIo: alternativeIo,
					source: source
				)))
				break
			}
		}
	}
	
	func send(
		request: SessionRequest,
		authentication: AuthenticationData
	) {
		Task {
			let _: Result<String, NetworkError> = await requestManager.perform(
				request,
				authentication
			)
		}
	}
	
	private func waitForDeviceState(
		_ companion: SauceDeviceCompanionConnection,
		target: CompanionStatusUpdateMessage.StateType
	) async -> CompanionStatusUpdateMessage.StateType {
		let log = Logger.make(tag: SessionViewService.self)
		var tempLastState: CompanionStatusUpdateMessage.StateType? = nil
		var lastExpectedState: CompanionStatusUpdateMessage.StateType? = nil
		let cancelable = companion.statusUpdate.receive(on: DispatchQueue.global()).sink {
			lastExpectedState = $0
		}
		
		let timeout = DispatchTime.now() + (2 * 60)
		while true {
			if lastExpectedState != tempLastState {
				tempLastState = lastExpectedState
				log.d("Device state \(lastExpectedState?.rawValue ?? "unknown")")
			}
			
			if lastExpectedState == target {
				cancelable.cancel()
				return target
			}
			
			if lastExpectedState == .CLOSING || lastExpectedState == .FAILED {
				cancelable.cancel()
				return .FAILED
			}
			
			let now = DispatchTime.now()
			if now > timeout {
				cancelable.cancel()
				return .FAILED
			}
			
			try? await Task.sleep(for: Duration.milliseconds(100))
		}
	}
}

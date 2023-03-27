//
//  SessionViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class SessionViewController: ViewStateTabViewController<SessionModel, SessionLoadingProgress, SessionError> {
	enum CloseReason {
		case connectionClosed
		case sessionClosed
		case userInitiated
		case error
	}
	
	struct ErrorDialogConfig {
		let title: String?
		let subtitle: String?
		let instructions: String?
		let action: (title: String, callback: () -> Void)?
	}
	
	class DeviewView: View {
		private let log = Logger.make(tag: DeviewView.self)
		private let view: VideoTrackStoringVideoView
		
		private var subscriptions = Set<AnyCancellable>()

		override init() {
			self.view = VideoTrackStoringVideoView()
			super.init()
			backgroundColor = .sauceLabs.black
			
			if view == nil {
				// I can't explain it. but this happened to me on my simulator after
				// many many many many runs. I had to erase my simulator to factory
				// settings into order to get it to work again.
				log.e("Twilio VideoView is nil")
				fatalError("Twilio Video is nil")
			}
			view.translatesAutoresizingMaskIntoConstraints = false
			view.contentMode = .scaleAspectFit
			view.shouldMirror = false

			addSubview(view)
			fill(with: view)
		}

		func configure(source: TwilioWrapper) {
			source.track.receive(on: DispatchQueue.main).sink {
				self.view.videoTrack = $0
			}.store(in: &subscriptions)
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	class FallbackDeviceView: View {
		private var subscriptions = Set<AnyCancellable>()
		private var enabled = false
		private let imageView = ImageView()
		
		override init() {
			super.init()
			
			backgroundColor = nil
			addSubview(imageView)
			fill(with: imageView)
		}
		
		func set(enabled: Bool) {
			self.enabled = enabled
			if enabled == false {
				imageView.image = nil
			}
		}
		
		func receive(screenshot: Data) {
			guard enabled else { return }
			imageView.image = UIImage(data: screenshot)
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let log = Logger.make(tag: SessionViewController.self)
	
	private var deviceView = DeviewView()
	private var fallbackDeviceView = FallbackDeviceView()
	private var overlay = DeviceOverlayView()
	
	private let close = PassthroughSubject<CloseReason, Never>()
	private let model: SessionViewModel
	private var sessionModel: SessionModel?
	
	private let factory: SessionViewFactory

	init(
		model: SessionViewModel,
		factory: SessionViewFactory
	) {
		self.model = model
		self.factory = factory
		super.init(state: model.state)
		modalPresentationStyle = .fullScreen
		view.backgroundColor = UIColor.sauceLabs.black
		
		view.addSubview(deviceView)
		fill(with: deviceView)
		
		view.addSubview(fallbackDeviceView)
		fill(with: fallbackDeviceView)
		
		view.addSubview(overlay)
		fill(with: overlay)
		
		overlay.clicked.sink { _ in
			guard let model = self.sessionModel else { return }
			self.showSessionMenu(model: model)
		}.store(in: &subscriptions)
		
		close.receive(on: DispatchQueue.main).sink {
			switch $0 {
			case .error, .userInitiated:
				self.dismiss(animated: true)
				break
			default:
				self.showError(ErrorDialogConfig(
					title: "Your test session has ended".loc,
					subtitle: nil,
					instructions: "You can see details and watch the recording in the Test Results page",
					action: (title: "Start New Test".loc, callback: {
						self.dismiss(animated: true)
					})
				))
				break
			}
		}.store(in: &subscriptions)
	}
	
	override func show(progress: SessionLoadingProgress) {
		switch progress {
		case .initializing:
			self.progress?.removeFromSuperview()
			let progress = SauceProgress()
			self.view.addSubview(progress)
			self.fill(with: progress)
			self.progress = progress
			break
		case .started(let session):
			self.close.sink {
				self.log.d("Closing session because \($0)")
				self.model.stop(session: session)
			}.store(in: &self.subscriptions)
			break
		case .screen(let source):
			self.deviceView.configure(source: source)
			source.connect()
			self.close.sink {
				self.log.d("Closing screen source because \($0)")
				source.disconnect()
			}.store(in: &self.subscriptions)
			break
		case .deviceConnected(let connection):
			// TODO: Add webSocket listener for logs, session wil expire etc...
			connection.sessionClosed.sink { _ in
				self.close.send(.sessionClosed)
			}.store(in: &self.subscriptions)
			connection.connectionClosed.sink { _ in
				self.close.send(.connectionClosed)
			}.store(in: &self.subscriptions)
			connection.open()
			self.close.sink {
				self.log.d("Closing companion because \($0)")
				connection.close()
			}.store(in: &self.subscriptions)
			break
		case .descriptor, .deviceOnline:
			break
		}
	}
	override func show(error: SessionError) {
		showError(ErrorDialogConfig(
			title: "Uh Oh!".loc,
			subtitle: "Something went wrong".loc,
			instructions: nil,
			action: (title: "Start New Test".loc, callback: {
				self.close.send(.error)
			})
		))
	}
	
	override func show(content: SessionModel) {
		sessionModel = content
		progress?.removeFromSuperview()
		
		close.receive(on: DispatchQueue.main).sink {
			self.log.d("Closing alternativeIo because \($0)")
			content.alternativeIo.close()
		}.store(in: &subscriptions)
		
		overlay.touch.sink {
			content.alternativeIo.send(message: $0)
		}.store(in: &subscriptions)
		
		content.companion.logMessage.receive(on: DispatchQueue.main).sink { [weak self] message in
			self?.onLog(message)
		}.store(in: &subscriptions)
		
		content.alternativeIo.screenshot.receive(on: DispatchQueue.main).sink { [weak self] data in
			self?.fallbackDeviceView.receive(screenshot: data)
		}.store(in: &subscriptions)
		
		content.alternativeIo.open()
		overlay.set(enabled: true)
	}
	
	func onLog(_ log: CompanionLogMessage) {
//		const message = log.message;
//		const regex = /to use your (approximate )?location/gm;
//		if (regex.test(message)) {
//		  if (message.indexOf('ViewDidAppear') > -1) {
//			webrtc.setEnabled(false, 'location-dialog-did-appear');
//		  }
//
//		  if (message.indexOf('ViewDidDisappear') > -1) {
//			webrtc.setEnabled(true, 'location-dialog-did-disappear');
//		  }
//		}

//		TODO: Call set enabled == true when we get a message that there's a location dialog up
//		fallbackDeviceView.set(enabled: true)
	}
	
	func showSessionMenu(model: SessionModel) {
		var deviceSectionRows: [DefaultTableRow] = []
		if model.descriptor.deviceSessionDescriptor.os == "IOS" {
			deviceSectionRows.append(
				DefaultTableRow(
					configure: { cell in
						cell.textLabel?.text = "Home".loc
					},
					action: { _, controller in
						model.alternativeIo.send(message: "tt/Sauce_Home_Key")
						controller?.dismiss(animated: true)
					}
				)
			)
		}
		if !model.descriptor.deviceSessionDescriptor.hasOnScreenButtons {
			deviceSectionRows.append(
				DefaultTableRow(
					configure: { cell in
						cell.textLabel?.text = "Home".loc
					},
					action: { _, controller in
						model.alternativeIo.send(message: "tt/Sauce_Home_Key")
						controller?.dismiss(animated: true)
					}
				)
			)
			if model.descriptor.deviceSessionDescriptor.os == "ANDROID" {
				deviceSectionRows.append(contentsOf: [
					DefaultTableRow(
						configure: { cell in
							cell.textLabel?.text = "Back".loc
						},
						action: { _, controller in
							model.alternativeIo.send(message: "tt/Sauce_Back_Key")
							controller?.dismiss(animated: true)
						}
					),
					DefaultTableRow(
						configure: { cell in
							cell.textLabel?.text = "Menu".loc
						},
						action: { _, controller in
							model.alternativeIo.send(message: "tt/Sauce_Menu_Key")
							controller?.dismiss(animated: true)
						}
					),
				])
			}
		}
		
		deviceSectionRows.append(DefaultTableRow(
			configure: { cell in
				cell.textLabel?.text = "Restart App".loc
			},
			action: { _, controller in
				self.model.restart(session: model.session)
				controller?.dismiss(animated: true)
			}
		))
		
		// TODO: Dialog to copy from clipboard is annoying
		var sessionRows: [DefaultTableRow] = []
		if let pasteText = UIPasteboard.general.string {
			sessionRows.append(DefaultTableRow(
				configure: { cell in
					cell.textLabel?.text = "Paste From Clipboard".loc
				},
				action: { _, controller in
					self.model.send(pasteText: pasteText, to: model.session)
					controller?.dismiss(animated: true)
				}
			))
		}
		
		sessionRows.append(DefaultTableRow(
			configure: { cell in
				cell.textLabel?.text = "End Session".loc
				cell.textLabel?.textColor = .sauceLabs.red
			},
			action: { _, controller in
				controller?.dismiss(animated: true) {
					self.close.send(.userInitiated)
				}
			}
		))

		self.present(factory.makeSessionMenu(config: SauceTableConfig(
			data: SauceTableData(
				sections: [
					SauceTableSection(
						title: "Device".loc,
						rows: deviceSectionRows
					),
					SauceTableSection(
						title: "Session".loc,
						rows: sessionRows
					)
				]
			),
			style: .grouped
		)), animated: true)
	}
	
	func showError(_ config: ErrorDialogConfig) {
		errorView?.removeFromSuperview()
		errorView = fill(view: SauceErrorView(
			title: config.title,
			subtitle: config.subtitle,
			instructions: config.instructions,
			action: config.action
		))
		errorView?.alpha = 0
		UIView.animate(withDuration: 1, delay: 0) {
			self.errorView?.alpha = 1
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		model.start()
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		guard let session = sessionModel?.session else { return }
		let orientation: DeviceOrientation = size.width > size.height ? .LANDSCAPE : .PORTRAIT
		model.send(orientation: orientation, to: session)
	}
	
	override var prefersStatusBarHidden: Bool {
	  return true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

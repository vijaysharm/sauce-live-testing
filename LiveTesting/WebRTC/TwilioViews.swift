//
//  TwilioViews.swift
//  LiveTesting
//

import AVKit
import Combine
import TwilioVideo
import UIKit

class VideoTrackStoringVideoView: VideoView {
	var videoTrack: VideoTrack? {
		didSet {
			guard oldValue != videoTrack else { return }
			
			oldValue?.removeRenderer(self)
			
			if let videoTrack = videoTrack {
				videoTrack.addRenderer(self)
			}
		}
	}
}

class PictureInPictureSetupView: UIView {
	private let log = Logger.make(tag: PictureInPictureSetupView.self)
	var videoView: VideoTrackStoringSampleBufferVideoView!
	var placeholderView: PIPPlaceholderView!
	private var pipController: AVPictureInPictureController!
	private var pipVideoCallViewController: AVPictureInPictureVideoCallViewController!
	
	override init(frame: CGRect) {
	  super.init(frame: frame)
		videoView = VideoTrackStoringSampleBufferVideoView()
			
		videoView.contentMode = .scaleAspectFill
		
		pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
		
		// Pretty much just for aspect ratio, normally used for pop-over
		pipVideoCallViewController.preferredContentSize = CGSize(width: 100, height: 150)

		placeholderView = PIPPlaceholderView()
		pipVideoCallViewController.view.addSubview(placeholderView)

		pipVideoCallViewController.view.addSubview(videoView)
		
		videoView.translatesAutoresizingMaskIntoConstraints = false;
		
		let constraints = [
			videoView.leadingAnchor.constraint(equalTo: pipVideoCallViewController.view.leadingAnchor),
			videoView.trailingAnchor.constraint(equalTo: pipVideoCallViewController.view.trailingAnchor),
			videoView.topAnchor.constraint(equalTo: pipVideoCallViewController.view.topAnchor),
			videoView.bottomAnchor.constraint(equalTo: pipVideoCallViewController.view.bottomAnchor)
		]

		NSLayoutConstraint.activate(constraints)

		let pipContentSource = AVPictureInPictureController.ContentSource(
			activeVideoCallSourceView: self,
			contentViewController: pipVideoCallViewController
		)
		
		pipController = AVPictureInPictureController(contentSource: pipContentSource)
		pipController.canStartPictureInPictureAutomaticallyFromInline = true
		pipController.delegate = self
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
	
//	func configure(participant: ParticipantViewModel) {
//		placeholderView.configure(particiipant: participant)
		
//		videoView.videoTrack = participant.cameraTrack
//	}
}

extension PictureInPictureSetupView: AVPictureInPictureControllerDelegate {
	func pictureInPictureControllerWillStartPictureInPicture(
		_ pictureInPictureController: AVPictureInPictureController
	) {
		log.d("pip controller delegate: will start")
	}
	
	func pictureInPictureControllerDidStartPictureInPicture(
		_ pictureInPictureController: AVPictureInPictureController
	) {
		log.d("pip controller delegate: did start")
	}
	
	func pictureInPictureController(
		_ pictureInPictureController: AVPictureInPictureController,
		failedToStartPictureInPictureWithError error: Error
	) {
		log.d("pip controller delegate: failed to start \(error)")
	}
	
	func pictureInPictureControllerWillStopPictureInPicture(
		_ pictureInPictureController: AVPictureInPictureController
	) {
		log.d("pip controller delegate: will stop")
	}
	
	func pictureInPictureControllerDidStopPictureInPicture(
		_ pictureInPictureController: AVPictureInPictureController
	) {
		log.d("pip controller delegate: did stop")
	}

	func pictureInPictureController(
		_ pictureInPictureController: AVPictureInPictureController,
		restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
	) {
		log.d("pip controller delegate: restore UI")
	}
}

class VideoTrackStoringSampleBufferVideoView: SampleBufferVideoView {
	var videoTrack: VideoTrack? {
		didSet {
			guard oldValue != videoTrack else { return }
			
			oldValue?.removeRenderer(self)
			
			if let videoTrack = videoTrack {
				videoTrack.addRenderer(self)
			}
		}
	}
}

class PIPPlaceholderView: UIView {
	let label = UILabel()
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundColor = .green
		
		addSubview(label)
		
		label.textColor = .white
		label.textAlignment = .center
	}
		
	override func didMoveToSuperview() {
		guard let superview = superview else { return }
		
		translatesAutoresizingMaskIntoConstraints = false
		let constraints = [
			leadingAnchor.constraint(equalTo: superview.leadingAnchor),
			trailingAnchor.constraint(equalTo: superview.trailingAnchor),
			topAnchor.constraint(equalTo: superview.topAnchor),
			bottomAnchor.constraint(equalTo: superview.bottomAnchor)
		]
		NSLayoutConstraint.activate(constraints)

		label.translatesAutoresizingMaskIntoConstraints = false
		let labelConstraints = [
			leadingAnchor.constraint(equalTo: label.leadingAnchor),
			trailingAnchor.constraint(equalTo: label.trailingAnchor),
			topAnchor.constraint(equalTo: label.topAnchor),
			bottomAnchor.constraint(equalTo: label.bottomAnchor)
		]
		NSLayoutConstraint.activate(labelConstraints)
	}
	
//	func configure(particiipant: ParticipantViewModel) {
//		label.text = particiipant.displayName
//	}
}

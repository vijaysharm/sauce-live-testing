//
//  TwilioWrapper.swift
//  LiveTesting
//

import Foundation
import TwilioVideo
import Combine

class TwilioWrapper: NSObject {
	public let track = CurrentValueSubject<VideoTrack?, Never>(nil)
	
	private let log = Logger.make(tag: TwilioWrapper.self)
	private let uuid = UUID()
	private let audioDevice: DefaultAudioDevice = {
		let device = DefaultAudioDevice()
		device.isEnabled = true

		return device
	}()
	private let credentials: WebRtcCredentials
	
	private var room: Room? = nil

	init(credentials: WebRtcCredentials) {
		self.credentials = credentials
		super.init()
		TwilioVideoSDK.audioDevice = audioDevice
//		TwilioVideoSDK.setLogLevel(TwilioVideoSDK.LogLevel.all)
	}
	
	func connect() {
		let options = ConnectOptionsFactory().makeConnectOptions(
			accessToken: credentials.accessToken,
			roomName: credentials.roomName,
			uuid: uuid
		)

		room = TwilioVideoSDK.connect(options: options, delegate: self)
	}
	
	func disconnect() {
		track.send(nil)
		room?.disconnect()
		room = nil
	}
}

extension TwilioWrapper: RoomDelegate {
	func roomDidConnect(room: Room) {
		log.d("RoomDelegate.roomDidConnect")
		room.remoteParticipants.forEach {
			$0.delegate = self
			guard let videoTrack = $0.presentationTrack else { return }
			track.send(videoTrack)
		}
	}
	func roomDidFailToConnect(room: Room, error: Error) { log.d("RoomDelegate.roomDidFailToConnect") }
	func roomDidDisconnect(room: Room, error: Error?) { log.d("RoomDelegate.roomDidDisconnect") }
	func participantDidConnect(room: Room, participant: RemoteParticipant) {
		log.d("RoomDelegate.participantDidConnect")
		participant.delegate = self
		guard let videoTrack = participant.presentationTrack else { return }
		track.send(videoTrack)
	}
	func participantDidDisconnect(room: Room, participant: RemoteParticipant) { log.d("RoomDelegate.participantDidDisconnect") }
	func dominantSpeakerDidChange(room: Room, participant: RemoteParticipant?) { log.d("RoomDelegate.dominantSpeakerDidChange") }
	func roomDidStartRecording(room: Room) { log.d("RoomDelegate.roomDidStartRecording") }
	func roomDidStopRecording(room: Room) { log.d("RoomDelegate.roomDidStopRecording") }
}

extension TwilioWrapper: RemoteParticipantDelegate {
	func didSubscribeToVideoTrack(
		videoTrack: RemoteVideoTrack,
		publication: RemoteVideoTrackPublication,
		participant: RemoteParticipant
	) {
		log.d("RemoteParticipantDelegate.didSubscribeToVideoTrack")
		track.send(videoTrack)
	}

	func didUnsubscribeFromVideoTrack(
		videoTrack: RemoteVideoTrack,
		publication: RemoteVideoTrackPublication,
		participant: RemoteParticipant
	) { log.d("RemoteParticipantDelegate.didUnsubscribeFromVideoTrack") }
	func remoteParticipantDidEnableVideoTrack(
		participant: RemoteParticipant,
		publication: RemoteVideoTrackPublication
	) { log.d("RemoteParticipantDelegate.remoteParticipantDidEnableVideoTrack") }
	func remoteParticipantDidDisableVideoTrack(
		participant: RemoteParticipant,
		publication: RemoteVideoTrackPublication
	) { log.d("RemoteParticipantDelegate.remoteParticipantDidDisableVideoTrack") }
	func remoteParticipantSwitchedOnVideoTrack(
		participant: RemoteParticipant,
		track: RemoteVideoTrack
	) { log.d("RemoteParticipantDelegate.remoteParticipantSwitchedOnVideoTrack") }
	func remoteParticipantSwitchedOffVideoTrack(
		participant: RemoteParticipant,
		track: RemoteVideoTrack
	) { log.d("RemoteParticipantDelegate.remoteParticipantSwitchedOffVideoTrack") }
	func didSubscribeToAudioTrack(
		audioTrack: RemoteAudioTrack,
		publication: RemoteAudioTrackPublication,
		participant: RemoteParticipant
	) {
		log.d("RemoteParticipantDelegate.didSubscribeToAudioTrack")
		audioTrack.isPlaybackEnabled = true
	}
	func didUnsubscribeFromAudioTrack(
		audioTrack: RemoteAudioTrack,
		publication: RemoteAudioTrackPublication,
		participant: RemoteParticipant
	) {
		log.d("RemoteParticipantDelegate.didUnsubscribeFromAudioTrack")
		audioTrack.isPlaybackEnabled = false
	}
	func remoteParticipantDidEnableAudioTrack(
		participant: RemoteParticipant,
		publication: RemoteAudioTrackPublication
	) { log.d("RemoteParticipantDelegate.remoteParticipantDidEnableAudioTrack") }
	func remoteParticipantDidDisableAudioTrack(
		participant: RemoteParticipant,
		publication: RemoteAudioTrackPublication
	) { log.d("RemoteParticipantDelegate.remoteParticipantDidDisableAudioTrack") }
	func remoteParticipantNetworkQualityLevelDidChange(
		participant: RemoteParticipant,
		networkQualityLevel: NetworkQualityLevel
	) { log.d("RemoteParticipantDelegate.remoteParticipantNetworkQualityLevelDidChange") }
}

extension RemoteParticipant {
	func videoTrack(_ trackName: String) -> RemoteVideoTrack? {
		remoteVideoTracks.first { $0.trackName.contains(trackName) }?.remoteTrack
	}
	
	var presentationTrack: VideoTrack? {
		videoTrack("screen")
	}
}

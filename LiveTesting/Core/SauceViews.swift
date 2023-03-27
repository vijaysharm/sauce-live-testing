//
//  SauceViews.swift
//  LiveTesting
//

import UIKit
import Combine
import Nuke
import NukeExtensions

class SauceInput: Input {
	override init() {
		super.init()
		
		borderColor = UIColor.sauceLabs.blueGrey
		borderWidth = 1
		cornerRadius = 4
		verticalPadding = 10
		horizontalPadding = 10
		font = UIFont.proximaRegular(size: 12)
		textColor = .sauceLabs.black
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceProgress: View {
	private lazy var view: ProgressView = {
		let view = ProgressView(colors: [UIColor.sauceLabs.green], lineWidth: 6)
		view.isAnimating = true

		return view
	}()
	
	override init() {
		super.init()
		
		addSubview(view)
		center(view)
		
		NSLayoutConstraint.activate([
			view.heightAnchor.constraint(equalToConstant: 30),
			view.widthAnchor.constraint(equalTo: view.heightAnchor),
		])
	}
	
	override func willAppear() {
		super.willAppear()
		view.isAnimating = true
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceErrorView: View {
	private var subscriptions = Set<AnyCancellable>()
	
	init(
		title: String?,
		subtitle: String?,
		instructions: String?,
		action: (title: String, callback: () -> Void)? = nil
	) {
		super.init()
		
		let contentView: UIStackView = {
			let view = UIStackView()
			view.translatesAutoresizingMaskIntoConstraints = false
			view.axis = .vertical
			view.distribution = .fill
			view.alignment = .fill
			view.spacing = 8
			
			return view
		}()
		
		if let title = title {
			let label = Label(text: title, textColor: UIColor.sauceLabs.red)
			label.textAlignment = .center
			label.font = .proximaSemiBold(size: 64)
			contentView.addArrangedSubview(label)
		}
		
		if let subtitle = subtitle {
			let label = Label(text: subtitle, textColor: UIColor.sauceLabs.black)
			label.textAlignment = .center
			label.font = .proximaSemiBold(size: 30)
			label.numberOfLines = 0
			contentView.addArrangedSubview(label)
		}
		
		if let instructions = instructions {
			let label = Label(text: instructions, textColor: UIColor.sauceLabs.grey)
			label.textAlignment = .center
			label.font = .proximaRegular(size: UIFont.labelFontSize)
			contentView.addArrangedSubview(label)
		}
		
		if let action = action {
			let button = SauceActionButton(title: action.title)
			button.onClicked.sink {
				action.callback()
			}.store(in: &subscriptions)
			contentView.addArrangedSubview(button)
		}
		
		backgroundColor = UIColor.sauceLabs.white
		addSubview(contentView)
		
		center(contentView)
		pin(contentView, to: [.leading(), .trailing()])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceActionButton: UIButton {
	public let onClicked = PassthroughSubject<Void, Never>()
	
	init(title: String) {
		super.init(frame: .zero)
		
		var container = AttributeContainer()
		container.font = UIFont.proximaSemiBold(size: UIFont.labelFontSize)
				
		var configuration = UIButton.Configuration.gray()
		configuration.cornerStyle = .small
		configuration.baseForegroundColor = UIColor.sauceLabs.black
		configuration.baseBackgroundColor = UIColor.sauceLabs.green
		configuration.buttonSize = .large
		configuration.attributedTitle = AttributedString(
			title,
			attributes: container
		)
		
		self.configuration = configuration
		self.translatesAutoresizingMaskIntoConstraints = false
		
		addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
	}
	
	@objc func touchUpInside() {
		onClicked.send()
	}
	
	override func updateConfiguration() {
		guard let configuration = configuration else {
			return
		}
		var updatedConfiguration = configuration
		
		switch self.state {
		case .disabled:
			updatedConfiguration.baseForegroundColor = UIColor.sauceLabs.black
			updatedConfiguration.background.backgroundColor = UIColor.sauceLabs.green.withAlphaComponent(0.7)
			
			var container = AttributeContainer()
			container.foregroundColor = UIColor.sauceLabs.black

			let title = updatedConfiguration.title!
			updatedConfiguration.attributedTitle = AttributedString(
				title,
				attributes: container
			)
			break
		default:
			updatedConfiguration.baseForegroundColor = UIColor.sauceLabs.black
			updatedConfiguration.background.backgroundColor = UIColor.sauceLabs.green
			break
		}
		self.configuration = updatedConfiguration
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceErrorBanner: Label {
	init() {
		super.init()
		textColor = UIColor.sauceLabs.red
		backgroundColor = UIColor.sauceLabs.lightestRed
		layer.borderWidth = 1
		layer.borderColor = UIColor.sauceLabs.lightRed.cgColor
		textAlignment = .center
		
		paddingTop = 16
		paddingBottom = 16
		paddingLeft = 8
		paddingRight = 8
		numberOfLines = 0
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceLabel: Label {
	init(text: String) {
		super.init(text: text, textColor: .sauceLabs.black)
		font = .proximaRegular(size: UIFont.labelFontSize)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceDeviceInUseView: SauceLabel {
	init() {
		super.init(text: "IN USE".loc)
		
		font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		textColor = .sauceLabs.white
		backgroundColor = .orange
		paddingTop = 2
		paddingBottom = 2
		paddingLeft = 4
		paddingRight = 4
		layer.cornerRadius = 2
		layer.masksToBounds = true
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize(width: 3, height: 3)
		layer.shadowOpacity = 0.1
		layer.shadowRadius = 0.5
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceAppGroupCell: UICollectionViewCell {
	public var files: (() -> Void)? = nil
	public var settings: (() -> Void)? = nil
	
	private let icon: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleToFill
		
		return view
	}()
	private let os: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleAspectFit
		
		return view
	}()
	private let title = SauceLabel(text: "")
	private let identifier = SauceLabel(text: "")
	private let version = SauceLabel(text: "")
	private let uploaded = SauceLabel(text: "")
	
	private let filesButton = Button(text: "See all versions".loc)
	private let settingsButton = ImageButton(systemIcon: "gear", padding: .zero)
	
	private var subscriptions = Set<AnyCancellable>()
	private lazy var dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
		dateFormatter.locale = NSLocale.current
		dateFormatter.dateStyle = .medium
		return dateFormatter
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backgroundColor = UIColor.sauceLabs.white
		layer.cornerRadius = 4
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize(width: 3, height: 3)
		layer.shadowOpacity = 0.1
		layer.shadowRadius = 0.5
		
		title.font = .proximaSemiBold(size: UIFont.labelFontSize)
		title.numberOfLines = 0
		title.lineBreakMode = .byWordWrapping
		identifier.font = .proximaSemiBold(size: UIFont.labelFontSize)
		identifier.numberOfLines = 0
		identifier.lineBreakMode = .byCharWrapping
		identifier.textColor = .sauceLabs.darkGrey
		identifier.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		version.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		uploaded.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		filesButton.setTitleColor(.sauceLabs.blueGrey, for: .normal)
		
		let versionLabel = SauceLabel(text: "Version:".loc)
		versionLabel.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		versionLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		versionLabel.textColor = .sauceLabs.darkGrey
		let versionContainer = View()
		versionContainer.addSubview(versionLabel)
		versionContainer.addSubview(version)
		NSLayoutConstraint.activate([
			versionLabel.leadingAnchor.constraint(equalTo: versionContainer.leadingAnchor),
			versionLabel.topAnchor.constraint(equalTo: versionContainer.topAnchor),
			versionLabel.bottomAnchor.constraint(equalTo: versionContainer.bottomAnchor),
			version.leadingAnchor.constraint(equalTo: versionLabel.trailingAnchor, constant: 4),
			version.topAnchor.constraint(equalTo: versionContainer.topAnchor),
			version.bottomAnchor.constraint(equalTo: versionContainer.bottomAnchor),
			version.trailingAnchor.constraint(equalTo: versionContainer.trailingAnchor),
		])
		
		let uploadedLabel = SauceLabel(text: "Uploaded:".loc)
		uploadedLabel.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		uploadedLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		uploadedLabel.textColor = .sauceLabs.darkGrey
		let uploadedContainer = View()
		uploadedContainer.addSubview(uploadedLabel)
		uploadedContainer.addSubview(uploaded)
		NSLayoutConstraint.activate([
			uploadedLabel.leadingAnchor.constraint(equalTo: uploadedContainer.leadingAnchor),
			uploadedLabel.topAnchor.constraint(equalTo: uploadedContainer.topAnchor),
			uploadedLabel.bottomAnchor.constraint(equalTo: uploadedContainer.bottomAnchor),
			uploaded.leadingAnchor.constraint(equalTo: uploadedLabel.trailingAnchor, constant: 4),
			uploaded.topAnchor.constraint(equalTo: uploadedContainer.topAnchor),
			uploaded.bottomAnchor.constraint(equalTo: uploadedContainer.bottomAnchor),
			uploaded.trailingAnchor.constraint(equalTo: uploadedContainer.trailingAnchor),
		])
		
		let labelContainer = View()
		labelContainer.addSubview(title)
		labelContainer.addSubview(identifier)
		labelContainer.addSubview(versionContainer)
		labelContainer.addSubview(uploadedContainer)
		labelContainer.addSubview(os)
		NSLayoutConstraint.activate([
			os.centerYAnchor.constraint(equalTo: title.centerYAnchor),
			os.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			os.heightAnchor.constraint(equalToConstant: 16),
			os.widthAnchor.constraint(equalTo: os.heightAnchor),
			
			title.topAnchor.constraint(equalTo: labelContainer.topAnchor),
			title.leadingAnchor.constraint(equalTo: os.trailingAnchor, constant: 4),
			title.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
			identifier.topAnchor.constraint(equalTo: title.bottomAnchor),
			identifier.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			identifier.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
			
			uploadedContainer.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor),
			uploadedContainer.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			uploadedContainer.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
			versionContainer.bottomAnchor.constraint(equalTo: uploadedContainer.topAnchor),
			versionContainer.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			versionContainer.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
		])
		
		let imageContainer = View()
		imageContainer.addSubview(icon)
		NSLayoutConstraint.activate([
			icon.topAnchor.constraint(equalTo: imageContainer.topAnchor),
			icon.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
			icon.widthAnchor.constraint(equalTo: imageContainer.widthAnchor),
			icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
		])
		
		let topContainer = View()
		topContainer.addSubview(imageContainer)
		topContainer.addSubview(labelContainer)
		NSLayoutConstraint.activate([
			imageContainer.topAnchor.constraint(equalTo: topContainer.topAnchor),
			imageContainer.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor),
			imageContainer.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor),
			imageContainer.widthAnchor.constraint(equalToConstant: 70),
			
			labelContainer.topAnchor.constraint(equalTo: topContainer.topAnchor),
			labelContainer.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor),
			labelContainer.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor),
			labelContainer.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: 8),
		])
		
		let bottomContainer = View()
		bottomContainer.addSubview(filesButton)
//		bottomContainer.addSubview(settingsButton)
		NSLayoutConstraint.activate([
			filesButton.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
//			filesButton.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
			filesButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
			filesButton.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor),
			
//			settingsButton.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
//			settingsButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
//			settingsButton.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor),
		])
		
		addSubview(topContainer)
		addSubview(bottomContainer)
		NSLayoutConstraint.activate([
			topContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			topContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			topContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			
			bottomContainer.topAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: 8),
			bottomContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			bottomContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			bottomContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
		])
		
		settingsButton.onClicked.sink {
			guard self.settingsButton.isEnabled else { return }
			self.settings?()
		}.store(in: &subscriptions)
		filesButton.onClicked.sink {
			guard self.filesButton.isEnabled else { return }
			self.files?()
		}.store(in: &subscriptions)
	}
	
	func set(group: AppGroup) {
		title.text = group.recent.metadata.name.isEmpty ? " " : group.recent.metadata.name
		identifier.text = group.name
		
		let date = Date(timeIntervalSince1970: TimeInterval(group.recent.uploadTimestamp))
		uploaded.text = dateFormatter.string(from: date)
		version.text = group.recent.metadata.versionString
		
		if
			let iconString = group.recent.metadata.icon,
			let iconData = Data(base64Encoded: iconString),
			let iconImage = UIImage(data: iconData) {
			icon.image = iconImage
		} else {
			if group.recent.isAndroid {
				icon.image = UIImage(named: "android-app-icon")
			}
			if group.recent.isIos {
				icon.image = UIImage(named: "ios-app-icon")
			}
		}
		
		if group.recent.isAndroid {
			os.image = UIImage(named: "android-icon")
		}
		if group.recent.isIos {
			os.image = UIImage(named: "ios-icon")
		}
		
		var text = "See all versions"
		if group.count == 0 {
			text = ""
		} else if group.count == 1 {
			text = "See version"
		} else {
			text = "See all \(group.count) versions".loc
		}
		filesButton.setTitle(text, for: .normal)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceDeviceCell: UICollectionViewCell {
	public var pin: (() -> Void)? = nil
	public var more: (() -> Void)? = nil
	
	private let imageView: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleAspectFit
		
		return view
	}()
	private let title = SauceLabel(text: "")
	private let os = SauceLabel(text: "")
	private let size = SauceLabel(text: "")
	private let busy = SauceDeviceInUseView()
	
	private let starButton = ImageButton(systemIcon: "pin.fill", scale: .medium)
	private let moreButton = ImageButton(systemIcon: "ellipsis")
	
	private let deviceImageContainer = View()
	
	private var subscriptions = Set<AnyCancellable>()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		backgroundColor = UIColor.sauceLabs.white
		layer.cornerRadius = 4

		title.font = .proximaSemiBold(size: UIFont.labelFontSize)
		title.numberOfLines = 0
		title.lineBreakMode = .byWordWrapping
		os.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		size.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		
		moreButton.onClicked.sink {
			guard self.moreButton.isEnabled else { return }
			self.more?()
		}.store(in: &subscriptions)
		starButton.onClicked.sink {
			guard self.starButton.isEnabled else { return }
			self.pin?()
		}.store(in: &subscriptions)
		
		let buttonContainer = View()
		buttonContainer.addSubview(starButton)
		buttonContainer.addSubview(moreButton)
		NSLayoutConstraint.activate([
			starButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
			starButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
			starButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
			
			moreButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
			moreButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
			moreButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
		])
		
		// shadow
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize(width: 3, height: 3)
		layer.shadowOpacity = 0.1
		layer.shadowRadius = 0.5
		
		deviceImageContainer.addSubview(imageView)
		
		let container = View()
		container.addSubview(title)
		container.addSubview(os)
		container.addSubview(size)
		
		addSubview(deviceImageContainer)
		addSubview(container)
		addSubview(buttonContainer)
		
		NSLayoutConstraint.activate([
			buttonContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			buttonContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
			buttonContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant:  -8),
			buttonContainer.widthAnchor.constraint(equalToConstant: 30),
			
			deviceImageContainer.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			deviceImageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			deviceImageContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
			deviceImageContainer.widthAnchor.constraint(equalTo: deviceImageContainer.heightAnchor),
			imageView.centerXAnchor.constraint(equalTo: deviceImageContainer.centerXAnchor),
			imageView.centerYAnchor.constraint(equalTo: deviceImageContainer.centerYAnchor),
			imageView.heightAnchor.constraint(equalTo: deviceImageContainer.heightAnchor, multiplier: 0.95),
			imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
			
			container.topAnchor.constraint(equalTo: topAnchor, constant: 8),
			container.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
			container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
			container.trailingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
			
			title.topAnchor.constraint(equalTo: container.topAnchor),
			title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
			title.trailingAnchor.constraint(equalTo: container.trailingAnchor),
			
			os.leadingAnchor.constraint(equalTo: container.leadingAnchor),
			os.trailingAnchor.constraint(equalTo: container.trailingAnchor),
			os.bottomAnchor.constraint(equalTo: size.topAnchor),
			
			size.leadingAnchor.constraint(equalTo: container.leadingAnchor),
			size.trailingAnchor.constraint(equalTo: container.trailingAnchor),
			size.bottomAnchor.constraint(equalTo: container.bottomAnchor),
		])
	}

	func set(device: SauceDevice) {
		title.text = device.name
		os.text = "\(device.os) \(device.osVersion)"
		size.text = "\(device.screenSize)\" | \(device.resolutionWidth)x\(device.resolutionHeight)"
		var options = ImageLoadingOptions()
		options.processors = device.inUse ? [
			ImageProcessors.CoreImageFilter(
				name: "CIColorMonochrome",
				parameters: [
					"inputIntensity": 1,
					"inputColor": CIColor(color: .white)
				],
				identifier: "live.testing.monochrome"
			)
		] : []
		NukeExtensions.loadImage(
			with: device.imageUrl,
			options: options,
			into: imageView
		)
		
		busy.removeFromSuperview()
		if device.inUse {
			deviceImageContainer.addSubview(busy)
			NSLayoutConstraint.activate([
				busy.topAnchor.constraint(equalTo: deviceImageContainer.topAnchor),
				busy.leadingAnchor.constraint(equalTo: deviceImageContainer.leadingAnchor),
			])
		}
		
		starButton.tintColor = .sauceLabs.darkGrey
		if device.starred {
			starButton.tintColor = .sauceLabs.green
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceDevice {
	var name: String {
		get {
			device.name
		}
	}
	var os: String {
		get {
			device.os
		}
	}
	var osVersion: String {
		get {
			device.osVersion
		}
	}
	var screenSize: Float {
		get {
			device.screenSize
		}
	}
	var descriptorId: String {
		get {
			device.descriptorId
		}
	}
	var compositeId: String {
		get {
			device.compositeId
		}
	}
	var resolutionWidth: Int {
		get {
			device.resolutionWidth
		}
	}
	var resolutionHeight: Int {
		get {
			device.resolutionHeight
		}
	}
	var cpuType: String {
		get {
			device.cpuType
		}
	}
	var cpuCores: Int {
		get {
			device.cpuCores
		}
	}
	var cpuFrequency: Int {
		get {
			device.cpuFrequency
		}
	}
	var dataCenterId: String {
		get {
			device.dataCenterId
		}
	}
	var modelNumber: String {
		get {
			device.modelNumber
		}
	}
	var ramSize: Int {
		get {
			device.ramSize
		}
	}
	var internalStorageSize: Int {
		get {
			device.internalStorageSize
		}
	}
	var formFactor: String {
		get {
			device.formFactor
		}
	}
	var manufacturers: [String] {
		get {
			device.manufacturers
		}
	}
	var apiLevel: Int {
		get {
			device.apiLevel
		}
	}
	
	let inUse: Bool
	let starred: Bool
	
	var imageUrl: URL {
		get {
			URL(string: "https://d3ty40hendov17.cloudfront.net/device-pictures/\(descriptorId)_optimised.png")!
		}
	}
	
	private let device: FilterableDevice
	
	init(
		device: FilterableDevice,
		inUse: Bool,
		starred: Bool
	) {
		self.device = device
		self.inUse = inUse
		self.starred = starred
	}
}

extension SauceDevice: Hashable {
	static func == (lhs: SauceDevice, rhs: SauceDevice) -> Bool {
		lhs.descriptorId == rhs.descriptorId
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(descriptorId)
	}
}

protocol ItemModel {
	associatedtype T where T: Hashable
	var items: CurrentValueSubject<[T], Never> { get }
}

protocol SearchableFacets {
	
}

protocol AppliedFacets {
	var textType: CurrentValueSubject<String, Never> { get }
	var filterCount: CurrentValueSubject<Int, Never> { get }
	var showFilterView: PassthroughSubject<Void, Never> { get }
}

protocol SearchableItemModel: ItemModel {
	associatedtype FilterType: SearchableFacets
	associatedtype AppliedFilterType: AppliedFacets
	
	var facets: FilterType { get }
	var filters: AppliedFilterType { get }
}

class SauceSearchView: View {
	private let input = Input()
	private let itemCount = Label()
	private let filter = ImageButton(systemIcon: "slider.horizontal.3")
	private let filterCount = Label()
	
	private var subscriptions = Set<AnyCancellable>()
	
	init(model: some SearchableItemModel) {
		super.init()
		
		backgroundColor = .sauceLabs.white
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowOffset = CGSize(width: 3, height: 3)
		layer.shadowOpacity = 0.1
		layer.shadowRadius = 0.5
		layer.cornerRadius = 4
		
		input.placeholder = "Type to Search...".loc
		input.placeholderColor = .sauceLabs.darkGrey
		input.verticalPadding = 10
		input.horizontalPadding = 10
		input.font = UIFont.proximaRegular(size: 20)
		input.textColor = .sauceLabs.black
	
		input.bind(to: model.filters.textType)
		
		itemCount.textColor = .sauceLabs.darkGrey
		itemCount.text = "(\(model.items.value.count))"
		model.items.sink { [weak self] in
			self?.itemCount.text = "(\($0.count))"
		}.store(in: &subscriptions)
		
		let filterContainer = View()
		filter.onClicked.sink { _ in
			model.filters.showFilterView.send()
		}.store(in: &subscriptions)
		filterCount.textColor = .sauceLabs.blue
		filterCount.text = "(\(model.filters.filterCount.value)"
		model.filters.filterCount.sink { [weak self] in
			self?.filterCount.text = "(\($0))"
		}.store(in: &subscriptions)
		let border = View()
		border.backgroundColor = .sauceLabs.lightGrey
		filterContainer.addSubview(border)
		filterContainer.addSubview(filter)
		filterContainer.addSubview(filterCount)
		
		NSLayoutConstraint.activate([
			border.topAnchor.constraint(equalTo: filterContainer.topAnchor),
			border.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor),
			border.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor),
			border.widthAnchor.constraint(equalToConstant: 1),
			
			filter.topAnchor.constraint(equalTo: filterContainer.topAnchor),
			filter.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor),
			filter.leadingAnchor.constraint(equalTo: border.trailingAnchor),
			
			filterCount.topAnchor.constraint(equalTo: filterContainer.topAnchor),
			filterCount.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor),
			filterCount.leadingAnchor.constraint(equalTo: filter.trailingAnchor),
			filterCount.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor, constant: -8),
		])
		
		addSubview(input)
		addSubview(itemCount)
		addSubview(filterContainer)
		
		NSLayoutConstraint.activate([
			input.leadingAnchor.constraint(equalTo: leadingAnchor),
			input.topAnchor.constraint(equalTo: topAnchor),
			input.bottomAnchor.constraint(equalTo: bottomAnchor),
			
			itemCount.topAnchor.constraint(equalTo: topAnchor),
			itemCount.bottomAnchor.constraint(equalTo: bottomAnchor),
			itemCount.leadingAnchor.constraint(equalTo: input.trailingAnchor),
			
			filterContainer.topAnchor.constraint(equalTo: topAnchor),
			filterContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
			filterContainer.leadingAnchor.constraint(equalTo: itemCount.trailingAnchor, constant: 8),
			filterContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
		])

		filter.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		filterCount.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		itemCount.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		input.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

struct SauceSearchableListCongiuration<ItemType> where ItemType: Hashable, ItemType: Sendable {
	let maxHeight: CGFloat
	let configureView: ((UICollectionView) -> Void)?
	let configureCell: ((UICollectionView, UICollectionViewCell, IndexPath, ItemType) -> Void)?
	let configureLayout: UICollectionViewCompositionalLayoutSectionProvider?
	let action: ((IndexPath, ItemType?) -> Void)?
}

class SauceSearchableListView<ItemType>: View where ItemType: Hashable, ItemType: Sendable {
	private let filter: SauceSearchView
	private let items: SauceListView<ItemType>
	
	init(
		model: any SearchableItemModel,
		configuration: SauceSearchableListCongiuration<ItemType>
	) {
		filter = SauceSearchView(model: model)
		items = SauceListView(model: model, configuration: configuration)
		super.init()
		
		addSubview(items)
		addSubview(filter)
		
		fill(with: items)
		pin(filter, to: [.leading(-8), .bottom(8), .trailing(8)], useSafeArea: true)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceListView<ItemType>: View where ItemType: Hashable, ItemType: Sendable {
	enum Section {
		case header
		case main
		case footer
	}
	
	typealias T = ItemType
	typealias DataSource = UICollectionViewDiffableDataSource<Section, ItemType>
	typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ItemType>
	
	private let list: MultiColumnCollectionView
	private var dataSource: DataSource!
	private var subscriptions = Set<AnyCancellable>()
	
	private let emptyView = SauceErrorView(
		title: nil,
		subtitle: "No items match your search".loc,
		instructions: "".loc
	)
	
	init(
		model: some ItemModel,
		configuration: SauceSearchableListCongiuration<ItemType>
	) {
		list = MultiColumnCollectionView(
			layoutProvider: configuration.configureLayout != nil ? configuration.configureLayout! : { (_, layoutEnvironment) -> NSCollectionLayoutSection? in
				// TODO: Implement multiple columns based on size, not device type
				let isPhone = layoutEnvironment.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.phone
				let size = NSCollectionLayoutSize(
					widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
					heightDimension: NSCollectionLayoutDimension.absolute(configuration.maxHeight) // isPhone ? 280 : 250
				)
				let itemCount = isPhone ? 1 : 3
				let item = NSCollectionLayoutItem(layoutSize: size)
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, repeatingSubitem: item, count: itemCount)
				let section = NSCollectionLayoutSection(group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 70, trailing: 10)
				section.interGroupSpacing = 10
				return section
			}
		)
		super.init()
		
		list.spacing = 16
		list.maxHeight = configuration.maxHeight
		list.padding = .init(top: 8, left: 8, bottom: 8, right: 8)
		list.backgroundColor = nil
		configuration.configureView?(list)
		list.didSelectItem = { [weak self] indexPath in
			let item = self?.dataSource.itemIdentifier(for: indexPath)
			configuration.action?(indexPath, item)
		}
		
		/** TODO: This is quite verbose. Can we fix this to be a little more elegant? */
		dataSource = DataSource(collectionView: list) { (collectionView, indexPath, item) ->
			UICollectionViewCell? in
			let cell = collectionView.dequeueReusableCell(
				withReuseIdentifier: "cell",
				for: indexPath
			)
			configuration.configureCell?(collectionView, cell, indexPath, item)
			
			return cell
		}
		
		model.items.sink { [weak self] items in
			guard let self = self else { return }
			guard let typedItems = items as? [ItemType] else { return }
			
			var snapshot = Snapshot()
			snapshot.appendSections([.main])
			snapshot.appendItems(typedItems, toSection: .main)
			self.dataSource.apply(snapshot, animatingDifferences: true)

			self.emptyView.removeFromSuperview()
			if items.isEmpty {
				self.addSubview(self.emptyView)
				self.fill(with: self.emptyView)
			}
		}.store(in: &subscriptions)
		
		addSubview(list)
		fill(with: list)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceBarButtonItem: UIBarButtonItem {
	public let onClicked = PassthroughSubject<Void, Never>()
	
	init(title: String, style: UIBarButtonItem.Style = .done) {
		super.init()
		
		self.title = title
		self.style = style
		self.target = self
		self.action = #selector(go)
		
		setTitleTextAttributes([
			.font: UIFont.proximaRegular(size: UIFont.labelFontSize),
			.foregroundColor: UIColor.sauceLabs.green
		], for: .normal)
	}
	
	@objc func go() {
		onClicked.send()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class DeviceOverlayView: View {
	public let clicked = PassthroughSubject<Bool, Never>()
	public let touch = PassthroughSubject<String, Never>()
	
	private let log = Logger.make(tag: DeviceOverlayView.self)
	private let actionButton: UIButton = {
		let view = UIButton(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: .large)
		let boldSmallSymbolImage = UIImage(systemName: "ellipsis", withConfiguration: config)
		view.setImage(boldSmallSymbolImage, for: .normal)
		view.tintColor = .white
		view.backgroundColor = .sauceLabs.green
		view.layer.cornerRadius = 28
		view.clipsToBounds = true
		view.layer.masksToBounds = false
		view.layer.shadowOffset = CGSizeMake(2, 2)
		view.layer.shadowRadius = 5
		view.layer.shadowOpacity = 0.5
		return view
	}()
	private var actionButtonXAnchor: NSLayoutConstraint!
	private var actionButtonYAnchor: NSLayoutConstraint!
	private var offSet: CGPoint! = .zero
	
	private var touches: [UITouch?] = Array(repeating: nil, count: 2)
	
	override init() {
		super.init()
		backgroundColor = nil
		
		actionButton.addTarget(self, action: #selector(button), for: .touchUpInside)
		actionButton.addGestureRecognizer(
			UIPanGestureRecognizer(target: self, action: #selector(pan(gesture:)))
		)
		
		addSubview(actionButton)
		actionButtonXAnchor = actionButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor)
		actionButtonYAnchor = actionButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 100)
		NSLayoutConstraint.activate([
			actionButton.widthAnchor.constraint(equalToConstant: 56),
			actionButton.heightAnchor.constraint(equalTo: actionButton.widthAnchor),
			actionButtonXAnchor,
			actionButtonYAnchor
		])
	}
	
	func set(enabled: Bool) {
		UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
			self.actionButtonXAnchor.constant = 0
			self.actionButtonYAnchor.constant = 0
			self.layoutIfNeeded()
		})
	}
	
	@objc func button() {
		clicked.send(true)
	}
	
	@objc func pan(gesture: UIPanGestureRecognizer) {
		guard let gestureView = gesture.view, gestureView == actionButton else {
			return
		}
		
		switch (gesture.state) {
		case .began:
			offSet = CGPoint(
				x: actionButtonXAnchor.constant,
				y: actionButtonYAnchor.constant
			)
			break
		case .changed:
			let translation = gesture.translation(in: self)
			actionButtonYAnchor.constant = offSet.y + translation.y
			actionButtonXAnchor.constant = offSet.x + translation.x
			self.layoutIfNeeded()
			break
		case .ended:
			//  0     w
			//  _______
			//  |\   /|    d1 is the negative slope (from top left to bottom right) with intercept = 0
			//  | \ / |    d2 is the positive slope (from bottom left to top right) with intercept = -h
			//  |  \  |
			//  | / \ |
			//  |/   \|
			//  ------
			// -h
			let newPoint = CGPoint(x: actionButtonXAnchor.constant, y: actionButtonYAnchor.constant)
			let slope = bounds.size.height / bounds.size.width
			let d1 = newPoint.y + (slope * newPoint.x)
			let d2 = newPoint.y + bounds.size.height - (slope * newPoint.x)
			
			var finalPoint: CGPoint = .zero
			if (d1 > 0 && d2 > 0) {
				// is in the bottom triangle
				finalPoint.x = actionButtonXAnchor.constant
				finalPoint.y = 0
			} else if (d1 <= 0 && d2 <= 0) {
				// is in the bottom triangle
				finalPoint.x = actionButtonXAnchor.constant
				finalPoint.y = 0
			} else {
				// d1 > 0 left triangle, d1 <= 0 is in the right triangle
				finalPoint.x = d1 > 0 ? bounds.size.width - actionButton.bounds.width : 0
				finalPoint.y = actionButtonYAnchor.constant
			}

			UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
				self.actionButtonXAnchor.constant = finalPoint.x
				self.actionButtonYAnchor.constant = finalPoint.y
				self.layoutIfNeeded()
			})
			break
		default:
			break
		}
	}
	
	override func willRotate(to size: CGSize) {
		self.actionButtonXAnchor.constant = 0
		self.actionButtonYAnchor.constant = 0
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		
		guard let touch = touches.first else { return }
		guard self.touches[0] == nil else { return }

		self.touches[0] = touch
		self.touch.send(self.message(code: "d", finger1: touch, finger2: nil))
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesMoved(touches, with: event)
		guard let touch = touches.first else { return }
		guard let first = self.touches[0] else { return }
		guard touch == first else { return }
		
		self.touch.send(self.message(code: "m", finger1: touch, finger2: nil))
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesEnded(touches, with: event)
		guard let touch = touches.first else { return }
		guard let first = self.touches[0] else { return }
		guard touch == first else { return }
		
		self.touch.send(self.message(code: "u", finger1: touch, finger2: nil))
		self.touches[0] = nil
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesCancelled(touches, with: event)
		self.touchesEnded(touches, with: event)
	}
	
	private func message(code: String, finger1: UITouch, finger2: UITouch?) -> String {
		let touchCount: Int = touches.reduce(0) { count, item in
			return item == nil ? count : (count + 1)
		}
		let width = Int(bounds.size.width)
		let height = Int(bounds.size.height)
		let orientation = width > height ? 1 : 0
		let touchPoint = finger1.location(in: self)
		let x = Int(touchPoint.x)
		let y = Int(touchPoint.y)
		let touchIndex = 0
		return "mt/\(code) \(width) \(height) \(orientation) \(touchCount) \(touchIndex) \(x) \(y)"
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

protocol SauceTableRow {
	var configure: ((UITableViewCell) -> Void)? { get }
	var action: ((SauceTableView, UIViewController?) -> Void)? { get }
}

struct DefaultTableRow: SauceTableRow {
	let configure: ((UITableViewCell) -> Void)?
	let action: ((SauceTableView, UIViewController?) -> Void)?
	init(
		configure: ((UITableViewCell) -> Void)? = nil,
		action: ((SauceTableView, UIViewController?) -> Void)? = nil
	) {
		self.configure = configure
		self.action = action
	}
}

class SauceTableSection {
	public let title: String?
	public let rows: [SauceTableRow]
	public let configure: (UITableViewCell, Int) -> Void
	public let action: (Int, SauceTableView, UIViewController?) -> Void

	init(
		title: String?,
		rows: [SauceTableRow],
		configure: ((UITableViewCell, Int) -> Void)? = nil,
		action: ((Int, SauceTableView, UIViewController?) -> Void)? = nil
	) {
		self.title = title
		self.rows = rows
		if configure == nil {
			self.configure = { cell, row in
				rows[row].configure?(cell)
			}
		} else {
			rows.forEach {
				guard $0.configure != nil else { return }
				fatalError("Support for confiuration at the Section and Row level is not supported. Pick one or the other")
			}
			self.configure = configure!
		}
		
		if action == nil {
			self.action = { row, view, controller in
				rows[row].action?(view, controller)
			}
		} else {
			rows.forEach {
				guard $0.action != nil else { return }
				fatalError("Support for action at the Section and Row level is not supported. Pick one or the other")
			}
			self.action = action!
		}
	}
}

struct SauceTableData {
	let sections: [SauceTableSection]
}

class SauceTableConfig {
	public let style: UITableView.Style
	public let cellClass: AnyClass
	public let data: SauceTableData
	
	init(
		data: SauceTableData,
		style: UITableView.Style = .plain,
		cellClass: AnyClass = UITableViewCell.self
	) {
		self.data = data
		self.cellClass = cellClass
		self.style = style
	}
}

class SauceFilter {
	public let applied: CurrentValueSubject<[String], Never>
	private let strategy: ([String], SauceDevice) -> Bool
	private let _count: Int?
	
	var count: Int {
		get {
			_count == nil ? applied.value.count : _count!
		}
	}
	
	init(
		applied: CurrentValueSubject<[String], Never>,
		count: Int? = nil,
		strategy: @escaping ([String], SauceDevice) -> Bool
	) {
		self.applied = applied
		self.strategy = strategy
		self._count = count
	}
	
	func filter(_ device: SauceDevice) -> Bool {
		if applied.value.isEmpty { return true }
		return strategy(applied.value, device)
	}
}

class SauceFilterTableSectionBuilder {
	enum SelectionType {
		case exclusive
		case inclusive
	}
	
	private var values: [String] = []
	
	private let title: String?
	private let keys: [String]
	private let mapping: [String: String]?
	private let onApply: (([String]) -> Void)?
	private let original: [String]
	private let type: SelectionType
	private let _count: Int?
	
	init(
		title: String?,
		keys: [String],
		values: [String],
		mapping: [String: String]?,
		apply: (([String]) -> Void)?,
		type: SelectionType = .inclusive,
		original: [String] = [],
		count: Int? = nil
	) {
		self.title = title
		self.keys = keys
		self.mapping = mapping
		self.values = values
		self.original = original
		self.onApply = apply
		self.type = type
		self._count = count
	}
	
	var count: Int {
		get {
			guard let total = _count else {
				return values.count
			}
			return total
		}
	}

	func reset() {
		values = Array(original)
	}
	
	func apply() {
		onApply?(values)
	}
	
	func build(changed: PassthroughSubject<Void, Never>) -> SauceTableSection {
		return SauceTableSection(
			title: title,
			rows: Array(repeating: DefaultTableRow(), count: keys.count),
			configure: { [weak self] cell, index in
				guard let self = self else { return }
				let key = self.keys[index]
				cell.textLabel?.text = key
				cell.backgroundColor = .sauceLabs.white
				cell.textLabel?.textColor = .sauceLabs.black
				if let lookup = self.mapping, let mapping = lookup[key] {
					cell.textLabel?.text = mapping
				}
				
				if self.values.contains(key) {
					cell.accessoryType = .checkmark
				} else {
					cell.accessoryType = .none
				}
			},
			action: { [weak self] index, view, _ in
				guard let self = self else { return }
				let key = self.keys[index]
				
				if self.type == .inclusive {
					if self.values.contains(key) {
						if let index = self.values.firstIndex(of: key) {
							self.values.remove(at: index)
						}
					} else {
						self.values.append(key)
					}
				}
				if self.type == .exclusive {
					self.values.removeAll()
					self.values.append(key)
				}
				
				changed.send()
			}
		)
	}
}

class SauceFilterViewConfig: SauceTableConfig {
	public let filterCountChanged = CurrentValueSubject<Int, Never>(0)
	
	private let builders: [SauceFilterTableSectionBuilder]
	private let onApply: ((Int) -> Void)?
	private var subscriptions = Set<AnyCancellable>()
	private var count: Int {
		get {
			filterCountChanged.value
		}
	}
	
	init(
		sections: [SauceFilterTableSectionBuilder],
		apply: ((Int) -> Void)? = nil
	) {
		let notify = PassthroughSubject<Void, Never>()
		self.builders = sections
		self.onApply = apply
		super.init(data: SauceTableData(sections: sections.map { $0.build(changed: notify)}))
		
		let count = sections.reduce(0) { $0 + $1.count }
		self.filterCountChanged.send(count)
		notify.sink {
			let count = sections.reduce(0) { $0 + $1.count }
			self.filterCountChanged.send(count)
		}.store(in: &subscriptions)
	}
	
	func apply() {
		builders.forEach { $0.apply() }
		onApply?(count)
	}
	
	func reset() {
		builders.forEach { $0.reset() }
		
		let count = builders.reduce(0) { $0 + $1.count }
		filterCountChanged.send(count)
	}
}

class SauceTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
	private let model: SauceTableConfig
	
	init(model: SauceTableConfig) {
		self.model = model
		super.init(frame: .zero, style: model.style)
		
		translatesAutoresizingMaskIntoConstraints = false
		backgroundColor = nil
		dataSource = self
		delegate = self
		register(model.cellClass, forCellReuseIdentifier: "cell")
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		model.data.sections[indexPath.section].action(indexPath.row, self, parentViewController)
		tableView.reloadSections([indexPath.section], with: .automatic)
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		model.data.sections[section].title
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		guard let header = view as? UITableViewHeaderFooterView else { return }
		header.textLabel?.textColor = .sauceLabs.darkGrey
		header.textLabel?.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		model.data.sections.count
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		model.data.sections[section].rows.count
	}
	
	func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.backgroundColor = .sauceLabs.white
		cell.textLabel?.textColor = .sauceLabs.black
		cell.detailTextLabel?.text = nil
		cell.detailTextLabel?.textColor = .sauceLabs.darkGrey
		cell.accessoryType = .none
		model.data.sections[indexPath.section].configure(cell, indexPath.row)

		return cell
	}
	
	var parentViewController: UIViewController? {
		var parentResponder: UIResponder? = self.next
		while parentResponder != nil {
			if let viewController = parentResponder as? UIViewController {
				return viewController
			}
			parentResponder = parentResponder!.next
		}

		return nil
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class SauceAppSelectionHeader: View {
	private let icon: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleToFill
		
		return view
	}()
	private let os: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleAspectFit
		
		return view
	}()
	private let title = SauceLabel(text: "")
	private let identifier = SauceLabel(text: "")
	private let version = SauceLabel(text: "")
	
	init(
		file: AppGroupFile,
		showVersion: Bool
	) {
		super.init()
		
		backgroundColor = UIColor.sauceLabs.white
		title.font = .proximaSemiBold(size: UIFont.labelFontSize)
		title.numberOfLines = 0
		title.lineBreakMode = .byWordWrapping
		identifier.font = .proximaSemiBold(size: UIFont.labelFontSize)
		identifier.numberOfLines = 0
		identifier.lineBreakMode = .byCharWrapping
		identifier.textColor = .sauceLabs.darkGrey
		identifier.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		version.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		
		let versionLabel = SauceLabel(text: "Version:".loc)
		versionLabel.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		versionLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		versionLabel.textColor = .sauceLabs.darkGrey
		let versionContainer = View()
		versionContainer.addSubview(versionLabel)
		versionContainer.addSubview(version)
		NSLayoutConstraint.activate([
			versionLabel.leadingAnchor.constraint(equalTo: versionContainer.leadingAnchor),
			versionLabel.topAnchor.constraint(equalTo: versionContainer.topAnchor),
			versionLabel.bottomAnchor.constraint(equalTo: versionContainer.bottomAnchor),
			version.leadingAnchor.constraint(equalTo: versionLabel.trailingAnchor, constant: 4),
			version.topAnchor.constraint(equalTo: versionContainer.topAnchor),
			version.bottomAnchor.constraint(equalTo: versionContainer.bottomAnchor),
			version.trailingAnchor.constraint(equalTo: versionContainer.trailingAnchor),
		])
		
		let labelContainer = View()
		labelContainer.addSubview(title)
		labelContainer.addSubview(identifier)
		labelContainer.addSubview(versionContainer)
		labelContainer.addSubview(os)
		NSLayoutConstraint.activate([
			os.centerYAnchor.constraint(equalTo: title.centerYAnchor),
			os.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			os.heightAnchor.constraint(equalToConstant: 16),
			os.widthAnchor.constraint(equalTo: os.heightAnchor),
			
			title.topAnchor.constraint(equalTo: labelContainer.topAnchor),
			title.leadingAnchor.constraint(equalTo: os.trailingAnchor, constant: 4),
			title.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
			identifier.topAnchor.constraint(equalTo: title.bottomAnchor),
			identifier.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			identifier.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),

			versionContainer.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor),
			versionContainer.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
			versionContainer.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
		])
		
		let imageContainer = View()
		imageContainer.addSubview(icon)
		NSLayoutConstraint.activate([
			icon.topAnchor.constraint(equalTo: imageContainer.topAnchor),
			icon.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
			icon.widthAnchor.constraint(equalTo: imageContainer.widthAnchor),
			icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
		])
		
		addSubview(imageContainer)
		addSubview(labelContainer)
		NSLayoutConstraint.activate([
			imageContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
			imageContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
			imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
			imageContainer.widthAnchor.constraint(equalToConstant: 70),
			
			labelContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
			labelContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
			labelContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
			labelContainer.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: 8),
			
			heightAnchor.constraint(equalToConstant: 78),
		])
		
		title.text = file.metadata.name.isEmpty ? " " : file.metadata.name
		identifier.text = file.metadata.identifier
		
		if showVersion {
			version.text = file.metadata.versionString
		} else {
			version.text = ""
			versionLabel.text = ""
		}
		
		if
			let iconString = file.metadata.icon,
			let iconData = Data(base64Encoded: iconString),
			let iconImage = UIImage(data: iconData) {
			icon.image = iconImage
		} else {
			if file.isAndroid {
				icon.image = UIImage(named: "android-app-icon")
			}
			if file.isIos {
				icon.image = UIImage(named: "ios-app-icon")
			}
		}
		
		if file.isAndroid {
			os.image = UIImage(named: "android-icon")
		}
		if file.isIos {
			os.image = UIImage(named: "ios-icon")
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

//
//  AppGroupFileViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class AppGroupFileViewModel {
	public let state = CurrentValueSubject<ViewState<AppGroupFileModel, Void, MobileAppError>, Never>(.loading(()))
	
	private let service: MobileAppService
	private let group: AppGroup
	private let appModel: AppModel
	private let model: MobileAppModel
	
	init(
		group: AppGroup,
		model: MobileAppModel,
		appModel: AppModel,
		service: MobileAppService
	) {
		self.group = group
		self.appModel = appModel
		self.model = model
		self.service = service
	}
	
	func refresh() {
		guard let auth = appModel.credentials.value else {
			state.send(.error(.unauthorized))
			return
		}
		state.send(.loading(()))
		service.files(from: group, authentication: auth) { [weak self ] results in
			guard let self = self else { return }
			switch results {
			case .failure(let error):
				self.state.send(.error(error))
				break
			case .success(let files):
				self.state.send(.content(data: AppGroupFileModel(
					files: files,
					group: self.group,
					service: self.service,
					model: self.model
				)))
				break
			}
		}
	}
}

class SauceAppFileCell: UICollectionViewCell {
	private let title = SauceLabel(text: "")
	private let identifier = SauceLabel(text: "")
	private let size = SauceLabel(text: "")
	private let version = SauceLabel(text: "")
	private let uploaded = SauceLabel(text: "")
	
	private lazy var dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
		dateFormatter.locale = NSLocale.current
		dateFormatter.dateStyle = .medium
		return dateFormatter
	}()
	
	private lazy var sizeFormatter: ByteCountFormatter = {
		let bcf = ByteCountFormatter()
		bcf.countStyle = .file
		return bcf
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

		identifier.numberOfLines = 0
		identifier.lineBreakMode = .byCharWrapping
		identifier.textColor = .sauceLabs.darkGrey
		identifier.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		
		size.numberOfLines = 1
		size.textColor = .sauceLabs.darkGrey
		size.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		
		version.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		uploaded.font = .proximaSemiBold(size: UIFont.smallSystemFontSize)
		
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
		
		let titleContainer = View()
		titleContainer.addSubview(title)
		titleContainer.addSubview(size)
		size.setContentHuggingPriority(.defaultHigh, for: .horizontal)
		
		NSLayoutConstraint.activate([
			title.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
			title.topAnchor.constraint(equalTo: titleContainer.topAnchor),
			title.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
			
			size.leadingAnchor.constraint(equalTo: title.trailingAnchor),
			size.topAnchor.constraint(equalTo: titleContainer.topAnchor),
			size.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
			size.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
		])
		
		addSubview(titleContainer)
		addSubview(identifier)
		addSubview(versionContainer)
		addSubview(uploadedContainer)
		NSLayoutConstraint.activate([
			titleContainer.topAnchor.constraint(equalTo: topAnchor),
			titleContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			titleContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			identifier.topAnchor.constraint(equalTo: titleContainer.bottomAnchor),
			identifier.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			identifier.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			
			uploadedContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
			uploadedContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			uploadedContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			versionContainer.bottomAnchor.constraint(equalTo: uploadedContainer.topAnchor),
			versionContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
			versionContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
		])
	}
	
	func set(file: AppGroupFile) {
		title.text = file.name
		identifier.text = file.id
		let sizeString = sizeFormatter.string(fromByteCount: file.size)
		size.text = "\(sizeString)"

		let date = Date(timeIntervalSince1970: TimeInterval(file.uploadTimestamp))
		uploaded.text = dateFormatter.string(from: date)
		version.text = file.metadata.versionString
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class AppGroupFileViewController: ViewStateTabViewController<AppGroupFileModel, Void, MobileAppError> {
	class ContentView: View {
		private let view: SauceListView<AppGroupFile>
		init(model: AppGroupFileModel) {
			view = SauceListView(
				model: model,
				configuration: SauceSearchableListCongiuration(
					maxHeight: 100,
					configureView: { list in
						list.register(SauceAppFileCell.self, forCellWithReuseIdentifier: "cell")
					},
					configureCell: { _, cell, _, file in
						guard let cell = cell as? SauceAppFileCell else { return }
						cell.set(file: file)
					},
					configureLayout: nil,
					action: { _, file in
						guard let file = file else { return }
						model.file.send(file)
					}
				)
			)
			super.init()
			
			let header = SauceAppSelectionHeader(
				file: model.group.recent,
				showVersion: false
			)
			addSubview(header)
			addSubview(view)
			
			pin(header, to: [.top(), .leading(), .trailing()])
			pin(view, to: [.bottom(), .leading(), .trailing()])
			
			NSLayoutConstraint.activate([
				view.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4)
			])
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let model: AppGroupFileViewModel
	private let factory: AppGroupFileViewFactory
	private var contentView: ContentView?
	
	init(
		model: AppGroupFileViewModel,
		factory: AppGroupFileViewFactory
	) {
		self.model = model
		self.factory = factory
		super.init(state: model.state)
		
		let cancelButton = SauceBarButtonItem(title: "Close".loc)
		cancelButton.onClicked.sink { [weak self] in
			self?.dismiss(animated: true)
		}.store(in: &subscriptions)
		self.navigationItem.leftBarButtonItem = cancelButton
		
		model.refresh()
	}
	
	override func show(content: AppGroupFileModel) {
		self.contentView?.removeFromSuperview()
		self.contentView = self.fill(
			view: ContentView(model: content)
		)
		
		content.file.sink { [weak self] file in
			self?.showDeviceSelection(group: content.group, file: file)
		}.store(in: &self.subscriptions)
	}

	private func showDeviceSelection(group: AppGroup, file: AppGroupFile) {
		let vc = self.factory.makeDeviceSelectionView(group: group, file: file)
		vc.modalPresentationStyle = .fullScreen
		self.present(vc, animated: true)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

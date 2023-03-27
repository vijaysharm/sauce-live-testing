//
//  Views.swift
//  LiveTesting
//

import UIKit
import Combine

class Label: UILabel {
	init(text: String = "", textColor: UIColor = .black) {
		super.init(frame: .zero)
		
		translatesAutoresizingMaskIntoConstraints = false
		self.textColor = textColor
		self.text = text
	}
	
	var textEdgeInsets = UIEdgeInsets.zero {
		didSet { invalidateIntrinsicContentSize() }
	}
	
	open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
		let insetRect = bounds.inset(by: textEdgeInsets)
		let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
		let invertedInsets = UIEdgeInsets(top: -textEdgeInsets.top, left: -textEdgeInsets.left, bottom: -textEdgeInsets.bottom, right: -textEdgeInsets.right)
		return textRect.inset(by: invertedInsets)
	}
	
	override func drawText(in rect: CGRect) {
		super.drawText(in: rect.inset(by: textEdgeInsets))
	}
	
	@IBInspectable
	var paddingLeft: CGFloat {
		set { textEdgeInsets.left = newValue }
		get { return textEdgeInsets.left }
	}
	
	@IBInspectable
	var paddingRight: CGFloat {
		set { textEdgeInsets.right = newValue }
		get { return textEdgeInsets.right }
	}
	
	@IBInspectable
	var paddingTop: CGFloat {
		set { textEdgeInsets.top = newValue }
		get { return textEdgeInsets.top }
	}
	
	@IBInspectable
	var paddingBottom: CGFloat {
		set { textEdgeInsets.bottom = newValue }
		get { return textEdgeInsets.bottom }
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class Spacer: UIView {
	init(height: CGFloat = 16) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			heightAnchor.constraint(equalToConstant: height)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class Input: UITextField {
	var padding: UIEdgeInsets {
		get {
			return UIEdgeInsets(
				top: verticalPadding,
				left: horizontalPadding,
				bottom: verticalPadding,
				right: horizontalPadding
			)
		}
	}
	@IBInspectable var placeholderColor: UIColor {
		get {
			return attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? .clear
		}
		set {
			guard let attributedPlaceholder = attributedPlaceholder else { return }
			let attributes: [NSAttributedString.Key: UIColor] = [.foregroundColor: newValue]
			self.attributedPlaceholder = NSAttributedString(string: attributedPlaceholder.string, attributes: attributes)
		}
	}
	
	var onInputChanged: ((Input) -> Void)? = nil
	private var subscriptions = Set<AnyCancellable>()
	
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
	}
	
	@objc func textFieldDidChange() {
		onInputChanged?(self)
	}
	
	override func textRect(forBounds bounds: CGRect) -> CGRect {
		bounds.inset(by: padding)
	}

	override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
		bounds.inset(by: padding)
	}

	override func editingRect(forBounds bounds: CGRect) -> CGRect {
		bounds.inset(by: padding)
	}

	@IBInspectable var verticalPadding: CGFloat = 0
	@IBInspectable var horizontalPadding: CGFloat = 0

	@IBInspectable var borderColor: UIColor? = UIColor.clear {
		didSet {
			layer.borderColor = self.borderColor?.cgColor
		}
	}
	
	@IBInspectable var borderWidth: CGFloat = 0 {
		didSet {
			layer.borderWidth = self.borderWidth
		}
	}
	
	@IBInspectable var cornerRadius: CGFloat = 0 {
		didSet {
			layer.cornerRadius = self.cornerRadius
			layer.masksToBounds = self.cornerRadius > 0
		}
	}
	
	override func draw(_ rect: CGRect) {
		self.layer.cornerRadius = self.cornerRadius
		self.layer.borderWidth = self.borderWidth
		self.layer.borderColor = self.borderColor?.cgColor
	}
	
	
	func bind(to observable: CurrentValueSubject<String, Never>) {
		observable.sink { [weak self] in
			self?.text = $0
		}.store(in: &subscriptions)
		onInputChanged = { [weak self] _ in
			guard let self = self else { return }
			observable.send(self.text ?? "")
		}
	}
	
	func bind(to observable: CurrentValueSubject<String?, Never>) {
		observable.sink { [weak self] in
			self?.text = $0
		}.store(in: &subscriptions)
		onInputChanged = { [weak self] _ in
			guard let self = self else { return }
			observable.send(self.text)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}

class TextField: UITextView {
	init(text: String = "", textColor: UIColor = .black) {
		super.init(frame: .zero, textContainer: nil)
		translatesAutoresizingMaskIntoConstraints = false
		
		self.textColor = textColor
		self.text = text
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ScrollView: UIScrollView {
	init(content: UIView, padding: UIEdgeInsets = .zero) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(content)
		
		let contentLayoutGuide = self.contentLayoutGuide
		let frameLayoutGuide = self.frameLayoutGuide
		NSLayoutConstraint.activate([
			content.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: padding.top),
			content.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -padding.bottom),
			content.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: padding.left),
			content.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -padding.right),
			content.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor, constant: -(padding.left + padding.right))
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class HorizontalPageView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
	class PageViewCellView: UICollectionViewCell {
		override init(frame: CGRect) {
			super.init(frame: frame)
			translatesAutoresizingMaskIntoConstraints = false
		}
		
		func fill(view content: UIView) {
			subviews.forEach { $0.removeFromSuperview() }
			
			addSubview(content)
			NSLayoutConstraint.activate([
				content.topAnchor.constraint(equalTo: topAnchor),
				content.bottomAnchor.constraint(equalTo: bottomAnchor),
				content.leadingAnchor.constraint(equalTo: leadingAnchor),
				content.trailingAnchor.constraint(equalTo: trailingAnchor),
			])
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let content: [UIView]
	var pageChanged: ((Int) -> Void)?
	
	init(content: [UIView]) {
		self.content = content
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .horizontal
		super.init(frame: .zero, collectionViewLayout: layout)
		
		translatesAutoresizingMaskIntoConstraints = false
			
		isPagingEnabled = true
		showsVerticalScrollIndicator = false
		showsHorizontalScrollIndicator = false
		allowsMultipleSelection = false
		delegate = self
		dataSource = self
		backgroundColor = nil
		register(PageViewCellView.self, forCellWithReuseIdentifier: "cell")
	}
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		let item = Int(targetContentOffset.pointee.x / scrollView.frame.width)
		pageChanged?(item)
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		content.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PageViewCellView
		let content = self.content[indexPath.row]
		cell.fill(view: content)
		return cell
	}
	
	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
	}

	public func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						insetForSectionAt section: Int) -> UIEdgeInsets {
		.zero
	}
	
	public func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		0
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ColouredSquare: View {
	init(colour: UIColor = .black) {
		super.init()
		
		backgroundColor = colour
		layer.cornerRadius = 8
		layer.borderWidth = 0
		layer.borderColor = UIColor.black.cgColor
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class View: UIView {
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func willRotate(to size: CGSize) {
		
	}
	
	func willAppear() {
		
	}
	
	func fill(with view: UIView, padding: UIEdgeInsets = .zero) {
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
			view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding.bottom),
			view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
			view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding.right),
		])
	}
}

protocol RefreshableViewController {
	func refresh()
}

class ViewController: UIViewController {
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		
		view.subviews.forEach {
			guard let view = $0 as? View else { return }
			view.willAppear()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		view.subviews.forEach {
			guard let view = $0 as? View else { return }
			view.willRotate(to: size)
		}
	}
}

class TabBarController: UITabBarController {
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
}

class NavigationController: UINavigationController {
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		.darkContent
	}
}

extension UIViewController {
	func alert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
		self.present(alert, animated: true, completion: nil)
	}

	func confirm(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		self.present(alert, animated: true, completion: nil)
	}
	
	func fill(
		with view: UIView,
		padding: UIEdgeInsets = .zero,
		useSafeArea: Bool = false
	) {
		if useSafeArea {
			NSLayoutConstraint.activate([
				view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: padding.top),
				view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom),
				view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: padding.left),
				view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -padding.right),
			])
		} else {
			NSLayoutConstraint.activate([
				view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: padding.top),
				view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -padding.bottom),
				view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: padding.left),
				view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -padding.right),
			])
		}
	}
	
	@objc func keyboardWillShow(notification: NSNotification) {
		guard let info = notification.userInfo else { return }
		guard let keyboardFrameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

		self.keyboardWillHide(notification: notification)
		let bounds = view.frame
		self.view.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.size.height - keyboardFrameValue.size.height)
		self.view.layoutIfNeeded()
	}

	@objc func keyboardWillHide(notification: NSNotification) {
		let bounds = UIScreen.main.bounds
		self.view.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.size.height)
		self.view.layoutIfNeeded()
	}
}

extension UIView {
	enum Anchor {
		case top(CGFloat = 0)
		case leading(CGFloat = 0)
		case trailing(CGFloat = 0)
		case bottom(CGFloat = 0)
	}
	
	func pin(
		_ view: UIView,
		to anchors: [Anchor] = [.top(), .bottom(), .leading(), .trailing()],
		useSafeArea: Bool = false
	) {
		let contraints: [NSLayoutConstraint] = anchors.map {
			switch $0 {
			case .top(let padding):
				return (useSafeArea ? safeAreaLayoutGuide.topAnchor : topAnchor).constraint(equalTo: view.topAnchor, constant: padding)
			case .bottom(let padding):
				return (useSafeArea ? safeAreaLayoutGuide.bottomAnchor : bottomAnchor).constraint(equalTo: view.bottomAnchor, constant: padding)
			case .trailing(let padding):
				return (useSafeArea ? safeAreaLayoutGuide.trailingAnchor : trailingAnchor).constraint(equalTo: view.trailingAnchor, constant: padding)
			case .leading(let padding):
				return (useSafeArea ? safeAreaLayoutGuide.leadingAnchor : leadingAnchor).constraint(equalTo: view.leadingAnchor, constant: padding)
			}
		}
		
		NSLayoutConstraint.activate(contraints)
	}
	
	func center(_ view: UIView) {
		NSLayoutConstraint.activate([
			centerXAnchor.constraint(equalTo: view.centerXAnchor),
			centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])
	}
}

class ActionButton: UIButton {
	var action: (() -> Void)?
	
	init(text: String = "", padding: UIEdgeInsets = UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16)) {
		super.init(frame: .zero)
		setTitle(text, for: .normal)
//		backgroundColor = CodeComplete.theme.action
//		setTitleColor(CodeComplete.theme.textPrimary, for: .normal)
		contentEdgeInsets = padding
		
		addTarget(self, action: #selector(runAction), for: .touchUpInside)
	}
	
	@objc func runAction() {
		action?()
	}
	
	func set(enabled: Bool) {
		isEnabled = enabled
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ActionImageButton: UIButton {
	var action: (() -> Void)?
	
	init(systemIcon: String, padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) {
		super.init(frame: .zero)
		let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: .large)
		let boldSmallSymbolImage = UIImage(systemName: systemIcon, withConfiguration: config)
		//tintColor = CodeComplete.theme.textPrimary
		contentEdgeInsets = padding
		setImage(boldSmallSymbolImage, for: .normal)
		//backgroundColor = CodeComplete.theme.action
		translatesAutoresizingMaskIntoConstraints = false
		addTarget(self, action: #selector(runAction), for: .touchUpInside)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func set(enabled: Bool) {
		//backgroundColor = enabled ? CodeComplete.theme.action : CodeComplete.theme.disabled
		isEnabled = enabled
	}
	
	@objc func runAction() {
		action?()
	}
}

class Link: ActionButton {
	override init(text: String = "", padding: UIEdgeInsets = UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16)) {
		super.init(text: text, padding: padding)
		backgroundColor = nil
		setTitleColor(UIColor(red: 74/255, green: 144/255, blue: 226/255, alpha: 1.0), for: .normal)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ImageButton: UIButton {
	public let onClicked = PassthroughSubject<Void, Never>()
	
	init(
		systemIcon: String,
		scale: UIImage.SymbolScale = .large,
		padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
	) {
		super.init(frame: .zero)

		setSystemIcon(systemIcon, scale)
		setConfiguration(padding: padding)
		
		tintColor = .sauceLabs.darkGrey
		translatesAutoresizingMaskIntoConstraints = false
		
		addTarget(self, action: #selector(runAction), for: .touchUpInside)
	}
	
	func setConfiguration(padding: UIEdgeInsets) {
		var container = AttributeContainer()
		container.font = UIFont.proximaSemiBold(size: UIFont.labelFontSize)
				
		var configuration = UIButton.Configuration.plain()
		configuration.buttonSize = .small
		
		self.configuration = configuration
	}
	
	func setSystemIcon(_ systemIcon: String, _ scale: UIImage.SymbolScale) {
		let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: scale)
		let boldSmallSymbolImage = UIImage(systemName: systemIcon, withConfiguration: config)
		setImage(boldSmallSymbolImage, for: .normal)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc func runAction() {
		onClicked.send()
	}
}

class Button: UIButton {
	public let onClicked = PassthroughSubject<Void, Never>()
	
	convenience init(
		text: String,
		padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
	) {
		self.init(padding: padding)
		
		setTitle(text, for: .normal)
	}
	
	convenience init(
		systemIcon: String,
		scale: UIImage.SymbolScale = .large,
		padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
	) {
		self.init(padding: padding)

		setSystemIcon(systemIcon, scale)
	}
	
	init(padding: UIEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) {
		super.init(frame: .zero)
		
		setConfiguration(padding: padding)
		
		tintColor = .sauceLabs.darkGrey
		translatesAutoresizingMaskIntoConstraints = false
		
		addTarget(self, action: #selector(runAction), for: .touchUpInside)
	}
	
	func setConfiguration(padding: UIEdgeInsets) {
		var container = AttributeContainer()
		container.font = UIFont.proximaSemiBold(size: UIFont.labelFontSize)
				
		var configuration = UIButton.Configuration.plain()
		configuration.buttonSize = .small
		
		self.configuration = configuration
	}
	
	func setSystemIcon(_ systemIcon: String, _ scale: UIImage.SymbolScale) {
		let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: scale)
		let boldSmallSymbolImage = UIImage(systemName: systemIcon, withConfiguration: config)
		setImage(boldSmallSymbolImage, for: .normal)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc func runAction() {
		onClicked.send()
	}
}

class ImageView: UIImageView {
	init(name: String) {
		let image = UIImage(named: name)
		super.init(image: image)
		translatesAutoresizingMaskIntoConstraints = false
	}
	
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class IconView: UIImageView {
	init(systemIcon: String, color: UIColor, scale: UIImage.SymbolScale = .default) {
		let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold, scale: scale)
		let image = UIImage(
			systemName: systemIcon,
			withConfiguration: config
		)!.withTintColor(
			color,
			renderingMode: .alwaysOriginal
		)
		super.init(image: image)
		translatesAutoresizingMaskIntoConstraints = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ActionLabel: View {
	private let label = Label()
	private var gesture: UITapGestureRecognizer!
	
	var tapUpInside: ((ActionLabel) -> Void)?

	init(text: String = "") {
		super.init()
		
		gesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
		addGestureRecognizer(gesture)
		
		label.text = text
		layer.cornerRadius = 4
		addSubview(label)
		
		NSLayoutConstraint.activate([
			label.topAnchor.constraint(equalTo: topAnchor, constant: 1),
			label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
			label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
			label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
		])
	}
	
	@objc func tapped() {
		tapUpInside?(self)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class LabelCollectionView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
	class LabelCellView: UICollectionViewCell {
		let label = Label()
		let container = View()
		
		override init(frame: CGRect) {
			super.init(frame: frame)
			
			container.layer.cornerRadius = 4
			container.addSubview(label)
			
			addSubview(container)
			
			NSLayoutConstraint.activate([
				label.topAnchor.constraint(equalTo: container.topAnchor, constant: 1),
				label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1),
				label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
				label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
				
				container.centerXAnchor.constraint(equalTo: centerXAnchor),
				container.centerYAnchor.constraint(equalTo: centerYAnchor)
			])
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let items: [String]
	private var current = 0
	var selection: ((Int) -> Void)?
	
	init(items: [String], direction: UICollectionView.ScrollDirection) {
		self.items = items
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = direction
		
		super.init(frame: .zero, collectionViewLayout: layout)
		
		translatesAutoresizingMaskIntoConstraints = false
		showsVerticalScrollIndicator = true
		showsHorizontalScrollIndicator = false
		allowsMultipleSelection = false
		delegate = self
		dataSource = self
		backgroundColor = nil
		register(LabelCellView.self, forCellWithReuseIdentifier: "cell")
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		items.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! LabelCellView
		cell.label.text = items[indexPath.row]
//		cell.label.textColor =  CodeComplete.theme.textPrimary
		
		if indexPath.row == current {
//			cell.container.backgroundColor = CodeComplete.theme.action
		} else {
			cell.container.backgroundColor = nil
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selection?(indexPath.row)
		current = indexPath.row
		collectionView.reloadData()
	}
	
	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		CGSize(width: 100, height: 48)
	}
	
	public func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						insetForSectionAt section: Int) -> UIEdgeInsets {
		.zero
	}
	
	public func collectionView(_ collectionView: UICollectionView,
						layout collectionViewLayout: UICollectionViewLayout,
						minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		0
	}
}

class BlurredView: View {
	private let blurView: UIVisualEffectView = {
		let blur = UIBlurEffect(style: .light)
		let view = UIVisualEffectView(effect: blur)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isUserInteractionEnabled = true
		
		return view
	}()
	
	private let message: Label = {
		let view = Label()
		view.isUserInteractionEnabled = true
		view.textAlignment = .center
		
		return view
	}()
	private var gesture: UITapGestureRecognizer!
	var revealed: (() -> Void)?
	
	init(content: UIView, tip: String = "Tap to reveal", padding: UIEdgeInsets = .zero) {
		super.init()
		
		gesture = UITapGestureRecognizer(target: self, action: #selector(showContent))
		message.text = tip
		
		addSubview(content)
		addSubview(blurView)
		addSubview(message)
		
		blurView.addGestureRecognizer(gesture)
		self.message.addGestureRecognizer(gesture)
		
		fill(with: content, padding: padding)
		fill(with: blurView)
		fill(with: self.message, padding: padding)
	}
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc func showContent() {
		blurView.removeGestureRecognizer(gesture)
		message.removeGestureRecognizer(gesture)
		
		blurView.removeFromSuperview()
		message.removeFromSuperview()
		revealed?()
	}
}

class LockedView: View {
	private let blurView: UIVisualEffectView = {
		let blur = UIBlurEffect(style: .light)
		let view = UIVisualEffectView(effect: blur)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.isUserInteractionEnabled = true
		
		return view
	}()
	private var current: UIView?
	
	override init() {
		super.init()
		
		addSubview(blurView)
		fill(with: blurView)
	}
	
	func set(dialog: UIView, size: CGSize) {
		if let current = current {
			current.removeFromSuperview()
		}
		
		current = dialog
		addSubview(dialog)
		NSLayoutConstraint.activate([
			dialog.centerYAnchor.constraint(equalTo: centerYAnchor),
			dialog.centerXAnchor.constraint(equalTo: centerXAnchor),
			dialog.widthAnchor.constraint(equalToConstant: size.width),
			dialog.heightAnchor.constraint(equalToConstant: size.height),
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
//
//class TestView: View {
//	var revealed: (() -> Void)?
//	init(
//		title: String,
//		test: NSAttributedString?
//	) {
//		super.init()
//
//		layer.cornerRadius = 8
//		clipsToBounds = true
////		backgroundColor = CodeComplete.theme.secondary
//
//		let titleLabel = Label(text: String(title))
//		let titleView = View()
//		titleView.addSubview(titleLabel)
//
//		let testContainer = TitleWithContentView(title: "Input(s)", text: test)
//		let wrappedView = BlurredView(content: testContainer, tip: "Tap to view test")
//		wrappedView.revealed = {
//			self.revealed?()
//		}
//
//		addSubview(titleView)
//		addSubview(wrappedView)
//
//		NSLayoutConstraint.activate([
//			titleLabel.topAnchor.constraint(equalTo: titleView.topAnchor),
//			titleLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor),
//			titleLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 16),
//			titleLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),
//
//			titleView.topAnchor.constraint(equalTo: topAnchor),
//			titleView.trailingAnchor.constraint(equalTo: trailingAnchor),
//			titleView.leadingAnchor.constraint(equalTo: leadingAnchor),
//			titleView.heightAnchor.constraint(equalToConstant: 48),
//
//			wrappedView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
//			wrappedView.trailingAnchor.constraint(equalTo: trailingAnchor),
//			wrappedView.leadingAnchor.constraint(equalTo: leadingAnchor),
//			wrappedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
//		])
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}
//
//class TestsView: ScrollableStackView {
//	var revealed: ((Int) -> Void)?
//	init(question: Question, json: JSONPrettyPrinter, highlightr: Highlightr?) {
//		super.init()
//
//		let tests = question.JSONTests
//		for (index, test) in tests.enumerated() {
//			let format = json.stringify(json: test)
//			let text = highlightr?.highlight(format, as: "json")
//			let view = TestView(title: "Test Case \(index + 1)", test: text)
//			view.revealed = {
//				self.revealed?(index)
//			}
//			super.contentView.addArrangedSubview(view)
//		}
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}

class TitleWithContentView: UIStackView {
	init(title: String, text: NSAttributedString?) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		axis = .vertical
		distribution = .fill
		alignment = .fill
		spacing = 8
		
		let inputTitle = Label(text: title)
		inputTitle.font = UIFont.boldSystemFont(ofSize: 17)
		let titleContainer = View()
		titleContainer.addSubview(inputTitle)
		titleContainer.fill(with: inputTitle, padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
		
		let inputText = Label()
		inputText.numberOfLines = 0
		inputText.attributedText = text
//		let testLabel = TextField()
//		testLabel.attributedText = test
//		testLabel.isSelectable = true
//		testLabel.isEditable = false
//		testLabel.isScrollEnabled = true
//		testLabel.showsHorizontalScrollIndicator = true
//		testLabel.showsVerticalScrollIndicator = false
//		testLabel.backgroundColor = nil
		let contentContainer = View()
		contentContainer.addSubview(inputText)
		contentContainer.fill(with: inputText, padding: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
//		contentContainer.backgroundColor = CodeComplete.theme.primary
		
		addArrangedSubview(titleContainer)
		addArrangedSubview(contentContainer)
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class VStack: UIStackView {
	init() {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		axis = .vertical
		distribution = .fill
		alignment = .fill
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class HStack: UIStackView {
	init(
		distribution: UIStackView.Distribution = .fillProportionally,
		alignment: UIStackView.Alignment = .fill
	) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		axis = .horizontal
		self.distribution = distribution
		self.alignment = alignment
	}
	
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ResultView: View {
	private let contentView: UIStackView = {
		let view = UIStackView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.axis = .vertical
		view.distribution = .fill
		view.alignment = .fill
		view.spacing = 16
		
		return view
	}()
	
	var revealed: (() -> Void)?
	
	init(
		success: Bool,
		title: String,
		ours: NSAttributedString?,
		yours: NSAttributedString?,
		input: NSAttributedString?,
		hide: Bool
	) {
		super.init()
		
		layer.cornerRadius = 8
		clipsToBounds = true
//		backgroundColor = CodeComplete.theme.secondary
		
		let titleLabel = Label(text: String(title))
		let titleIcon = IconView(
			systemIcon: success ? "checkmark.circle.fill": "xmark.circle.fill",
			color: .white //success ? CodeComplete.theme.successColour : CodeComplete.theme.failedColour
		)
		let titleView = View()
		titleView.addSubview(titleIcon)
		titleView.addSubview(titleLabel)
		
		if let ours = ours {
			contentView.addArrangedSubview(TitleWithContentView(title: "Our Code's Output", text: ours))
		}
		
		if let yours = yours {
			contentView.addArrangedSubview(TitleWithContentView(title: "Your Code's Output", text: yours))
		}
		
		contentView.addArrangedSubview(TitleWithContentView(title: "Input(s)", text: input))
		
		let wrappedView: UIView
		if hide {
			let blurred = BlurredView(content: contentView, tip: "Tap to view test")
			blurred.revealed = {
				self.revealed?()
			}
			wrappedView = blurred
		} else {
			wrappedView = contentView
		}
		
		addSubview(titleView)
		addSubview(wrappedView)
		
		NSLayoutConstraint.activate([
			titleIcon.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
			titleIcon.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 16),
			titleIcon.widthAnchor.constraint(equalToConstant: 24),
			titleIcon.heightAnchor.constraint(equalToConstant: 24),
			
			titleLabel.topAnchor.constraint(equalTo: titleView.topAnchor),
			titleLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor),
			titleLabel.leadingAnchor.constraint(equalTo: titleIcon.trailingAnchor, constant: 16),
			titleLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),
			
			titleView.topAnchor.constraint(equalTo: topAnchor),
			titleView.trailingAnchor.constraint(equalTo: trailingAnchor),
			titleView.leadingAnchor.constraint(equalTo: leadingAnchor),
			titleView.heightAnchor.constraint(equalToConstant: 48),
			
			wrappedView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
			wrappedView.trailingAnchor.constraint(equalTo: trailingAnchor),
			wrappedView.leadingAnchor.constraint(equalTo: leadingAnchor),
			wrappedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class ResultViewHeader: View {
	private let title: Label
	private let subtitle: Label
	
	init(title: String, subtitle: String) {
		self.title = Label(text: title)
		self.subtitle = Label(text: subtitle)
		
		super.init()
		
		self.title.textAlignment = .center
//		self.title.font = CodeComplete.theme.questionTitle
		self.title.numberOfLines = 0
		self.subtitle.textAlignment = .center
		self.subtitle.textColor = .lightGray
		
		addSubview(self.title)
		addSubview(self.subtitle)
		
		NSLayoutConstraint.activate([
			self.title.topAnchor.constraint(equalTo: topAnchor),
			self.title.leadingAnchor.constraint(equalTo: leadingAnchor),
			self.title.trailingAnchor.constraint(equalTo: trailingAnchor),
			self.title.bottomAnchor.constraint(equalTo: self.subtitle.topAnchor, constant: -8),
			
			self.subtitle.leadingAnchor.constraint(equalTo: leadingAnchor),
			self.subtitle.trailingAnchor.constraint(equalTo: trailingAnchor),
			self.subtitle.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
//
//class ResultsView: ScrollableStackView {
//	var revealed: ((Int) -> Void)?
//	init(
//		question: Question,
//		results: [TestResult],
//		hidden: [Bool],
//		json: JSONPrettyPrinter,
//		highlightr: Highlightr?,
//		success: Bool,
//		showActual: Bool
//	) {
//		super.init()
//
//		let tests = question.JSONTests
//		let answers = question.JSONAnswers
//
//		let count = tests.count
//		var successCount = 0
//		var views: [ResultView] = []
//
//		for (index, test) in tests.enumerated() {
//			let result = results[index]
//			let actual = result.actual as? String ?? (result.success ? answers[index] : "undefined")
//			let expected = result.expected as? String ?? answers[index]
//			successCount = successCount + (result.success ? 1 : 0)
//			let view = ResultView(
//				success: result.success,
//				title: "Test Case \(index + 1)",
//				ours: highlightr?.highlight(json.stringify(json: expected), as: "json"),
//				yours: showActual ? highlightr?.highlight(json.stringify(json: actual), as: "json") : nil,
//				input: highlightr?.highlight(json.stringify(json: test), as: "json"),
//				hide: hidden[index]
//			)
//			view.revealed = {
//				self.revealed?(index)
//			}
//			views.append(view)
//		}
//
//		super.contentView.addArrangedSubview(ResultViewHeader(
//			title: success ? "Yay, code passed all the test cases!" : "Aww, code failed at least one of the test cases.",
//			subtitle: "\(successCount)/\(count) test cases passed"
//		))
//		views.forEach { super.contentView.addArrangedSubview($0) }
//
//		layer.borderWidth = 2
//		layer.borderColor = success ? CodeComplete.theme.successColour.cgColor : CodeComplete.theme.failedColour.cgColor
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}

class ScrollableStackView: UIScrollView {
	private let contentView: UIStackView = {
		let view = UIStackView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.axis = .vertical
		view.distribution = .fill
		view.alignment = .fill
		
		return view
	}()
	
	init(padding: CGFloat = 16, spacing: CGFloat = 16) {
		super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		
		contentView.spacing = spacing
		addSubview(contentView)
		
		let contentLayoutGuide = self.contentLayoutGuide
		let frameLayoutGuide = self.frameLayoutGuide
		NSLayoutConstraint.activate([
			contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor, constant: padding),
			contentView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -padding),
			contentView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: padding),
			contentView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
			contentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor, constant: -2 * padding)
		])
	}
	
	func addView(_ view: UIView) {
		contentView.addArrangedSubview(view)
	}
	
	func removeAllArrangedSubviews() {
		let removedSubviews = contentView.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
			contentView.removeArrangedSubview(subview)
			return allSubviews + [subview]
		}
		
		// Deactivate all constraints
		// NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
		
		// Remove the views from self
		removedSubviews.forEach({ $0.removeFromSuperview() })
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class MultiColumnCollectionView: UICollectionView {
	var padding = UIEdgeInsets.zero {
		didSet { invalidateIntrinsicContentSize() }
	}
	var maxWidth: CGFloat = 250 {
		didSet { invalidateIntrinsicContentSize() }
	}
	var maxHeight: CGFloat = 130 {
		didSet { invalidateIntrinsicContentSize() }
	}
	var spacing: CGFloat = 0 {
		didSet { invalidateIntrinsicContentSize() }
	}
	
	var didSelectItem: ((IndexPath) -> Void)? = nil
	
	init(
		layoutProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider
	) {
		let layout = UICollectionViewFlowLayout()
		layout.sectionHeadersPinToVisibleBounds = true
		
		super.init(frame: .zero, collectionViewLayout: layout)
		translatesAutoresizingMaskIntoConstraints = false
		showsVerticalScrollIndicator = true
		showsHorizontalScrollIndicator = false
		allowsMultipleSelection = false
		delegate = self

		collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: layoutProvider)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension MultiColumnCollectionView: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
		didSelectItem?(indexPath)
	}
}

extension MultiColumnCollectionView: UICollectionViewDelegateFlowLayout {
	public func collectionView(
		_ collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		sizeForItemAt indexPath: IndexPath
	) -> CGSize {
		let fullWidth = collectionView.frame.width - padding.left - padding.right
		let possibleColumns = Int(fullWidth / maxWidth)
		if possibleColumns == 0 || possibleColumns == 1 {
			return CGSize(width: fullWidth, height: maxHeight)
		}
		
		let size = (fullWidth - (CGFloat(possibleColumns - 1) * spacing)) / CGFloat(possibleColumns)
		return CGSize(width: size, height: maxHeight)
	}
	
	public func collectionView(
		_ collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		insetForSectionAt section: Int
	) -> UIEdgeInsets {
		padding
	}
	
	public func collectionView(
		_ collectioknView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		minimumLineSpacingForSectionAt section: Int
	) -> CGFloat {
		spacing
	}
}

//
//class HintsView: UIScrollView {
//	class HintView: View {
//		init(title: String, hint: String) {
//			super.init()
//
//			layer.cornerRadius = 8
//			clipsToBounds = true
//
//			let titleLabel = Label(text: String(title))
//			let titleView = View()
//			titleView.addSubview(titleLabel)
//			titleView.backgroundColor = CodeComplete.theme.secondary
//
//			let hintLabel = Label(text: String(hint))
//			hintLabel.numberOfLines = 0
//			let hintContainer = View()
//			hintContainer.backgroundColor = CodeComplete.theme.secondary
//			hintContainer.addSubview(hintLabel)
//			hintContainer.fill(with: hintLabel, padding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
//			let hintView = BlurredView(content: hintContainer, tip: "Tap to reveal \(title.lowercased())")
//
//			addSubview(titleView)
//			addSubview(hintView)
//
//			NSLayoutConstraint.activate([
//				titleLabel.topAnchor.constraint(equalTo: titleView.topAnchor),
//				titleLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor),
//				titleLabel.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 16),
//				titleLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),
//
//				titleView.topAnchor.constraint(equalTo: topAnchor),
//				titleView.trailingAnchor.constraint(equalTo: trailingAnchor),
//				titleView.leadingAnchor.constraint(equalTo: leadingAnchor),
//				titleView.heightAnchor.constraint(equalToConstant: 48),
//
//				hintView.topAnchor.constraint(equalTo: titleView.bottomAnchor),
//				hintView.trailingAnchor.constraint(equalTo: trailingAnchor),
//				hintView.leadingAnchor.constraint(equalTo: leadingAnchor),
//				hintView.bottomAnchor.constraint(equalTo: bottomAnchor)
//			])
//		}
//
//		required init?(coder: NSCoder) {
//			fatalError("init(coder:) has not been implemented")
//		}
//	}
//
//	private let contentView: UIStackView = {
//		let view = UIStackView()
//		view.translatesAutoresizingMaskIntoConstraints = false
//		view.axis = .vertical
//		view.distribution = .fill
//		view.alignment = .fill
//		view.spacing = 16
//
//		return view
//	}()
//
//	init(question: Question) {
//		super.init(frame: .zero)
//		translatesAutoresizingMaskIntoConstraints = false
//
//		let hints = question.Hints.split(separator: "\n")
//		for (index, hint) in hints.enumerated() {
//			contentView.addArrangedSubview(
//				HintView(title: "Hint #\(index + 1)", hint: String(hint))
//			)
//		}
//
//		contentView.addArrangedSubview(
//			HintView(title: "Complexity", hint: question.SpaceTime)
//		)
//
//		addSubview(contentView)
//
//		let contentLayoutGuide = self.contentLayoutGuide
//		let frameLayoutGuide = self.frameLayoutGuide
//		NSLayoutConstraint.activate([
//			contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
//			contentView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
//			contentView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
//			contentView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
//			contentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor)
//		])
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}

//class PanelDelegate: QuestionPanelDelegate {
//	private let panels: [QuestionPanelDelegate]
//
//	init(panels: [QuestionPanelDelegate]) {
//		self.panels = panels
//	}
//
//	func tabCount(panel: QuestionPanel) -> Int {
//		panels.count
//	}
//
//	func configure(panel: QuestionPanel, tab: Int, label: Label) {
//		panels[tab].configure(panel: panel, tab: tab, label: label)
//	}
//
//	func configure(panel: QuestionPanel, tab: Int, content: View) {
//		panels[tab].configure(panel: panel, tab: tab, content: content)
//	}
//
//	func configure(panel: QuestionPanel, tab: Int, cell: QuickPanelCellView) {
//		panels[tab].configure(panel: panel, tab: tab, cell: cell)
//	}
//}
//
//class GenericPanel: QuestionPanelDelegate {
//	private let cellName: String
//	private let tabName: String
//	private let content: UIView?
//	private let padding: UIEdgeInsets?
//
//	init(
//		cellName: String,
//		tabName: String,
//		content: UIView? = .none,
//		padding: UIEdgeInsets? = .zero
//	) {
//		self.cellName = cellName
//		self.tabName = tabName
//		self.content = content
//		self.padding = padding
//	}
//
//	func tabCount(panel: QuestionPanel) -> Int { fatalError() }
//	func configure(panel: QuestionPanel, tab: Int, cell: QuickPanelCellView) { cell.label.text = cellName }
//	func configure(panel: QuestionPanel, tab: Int, label: Label) { label.text = tabName }
//	func configure(panel: QuestionPanel, tab: Int, content: View) {
//		if let body = self.content {
//			content.addSubview(body)
//			content.fill(with: body, padding: padding ?? UIEdgeInsets.zero)
//		}
//	}
//}
//
//class ConsoleView: View {
//	init(message: String) {
//		super.init()
//
//		let label = Label(text: message)
//		label.textAlignment = .center
//
//		addSubview(label)
//		fill(with: label)
//	}
//
//	func set(text: String, success: Bool) {
//		subviews.forEach { $0.removeFromSuperview() }
//
//		layer.borderWidth = 2
//		layer.borderColor = success ? CodeComplete.theme.successColour.cgColor : CodeComplete.theme.failedColour.cgColor
//
//		let label = Label(text: text)
//		label.numberOfLines = 0
//		label.textColor = success ? CodeComplete.theme.successColour : CodeComplete.theme.failedColour
//
//		let scroll = ScrollView(content: label, padding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
//		addSubview(scroll)
//		fill(with: scroll)
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}
//
//class PromptView: View {
//	private let promptView: WebView
//
//	init(question: Question, state: String?) {
//		promptView = WebView(question: question, state: state)
//		super.init()
//
//		addSubview(promptView)
//		fill(with: promptView)
//	}
//
//	func set(state: String?) {
//		promptView.set(state: state)
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}
//
//protocol QuestionView {
//	func showPanel(panel: QuestionPanelDelegate)
//}
//
//class SplitPanel: View, QuestionView {
//	private let left = QuestionPanel()
//	private let right = QuestionPanel()
//
//	init(leftPanels: [QuestionPanelDelegate], rightPanels: [QuestionPanelDelegate]) {
//		super.init()
//		right.delegate = PanelDelegate(panels: rightPanels)
//		left.delegate = PanelDelegate(panels: leftPanels)
//
//		addSubview(right)
//		addSubview(left)
//
//		NSLayoutConstraint.activate([
//			left.topAnchor.constraint(equalTo: topAnchor),
//			left.bottomAnchor.constraint(equalTo: bottomAnchor),
//			left.leadingAnchor.constraint(equalTo: leadingAnchor),
//			left.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -4),
//
//			right.topAnchor.constraint(equalTo: topAnchor),
//			right.bottomAnchor.constraint(equalTo: bottomAnchor),
//			right.trailingAnchor.constraint(equalTo: trailingAnchor),
//			right.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -4),
//		])
//
//		left.set(index: 0)
//		right.set(index: 0)
//	}
//
//	func showPanel(panel: QuestionPanelDelegate) {
//		if let _ = panel as? TestsPanel {
//			self.left.set(index: 2)
//		} else {
//			self.right.set(index: 2)
//		}
//	}
//
//	deinit {
//		left.delegate = nil
//		right.delegate = nil
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}
//
//class SinglePanel: View, QuestionView {
//	private let panel = QuestionPanel()
//
//	init(panels: [QuestionPanelDelegate]) {
//		super.init()
//
//		panel.delegate = PanelDelegate(panels: panels)
//
//		addSubview(panel)
//		fill(with: panel)
//
//		panel.set(index: 0)
//	}
//
//	deinit {
//		panel.delegate = nil
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//
//	func showPanel(panel: QuestionPanelDelegate) {
//		if let _ = panel as? TestsPanel {
//			self.panel.set(index: 3)
//		} else {
//			self.panel.set(index: 5)
//		}
//	}
//}
//
//extension Purchases.Package {
//	func unitPrice(priceFormatter: NumberFormatter) -> String {
//		switch packageType {
//		case .lifetime:
//			return "One time"
//		case .annual:
//			return "\(priceFormatter.string(from: product.price.dividing(by: 12.0)) ?? "") / mo"
//		case .sixMonth:
//			return "\(priceFormatter.string(from: product.price.dividing(by: 6.0)) ?? "") / mo"
//		case .threeMonth:
//			return "\(priceFormatter.string(from: product.price.dividing(by: 3.0)) ?? "") / mo"
//		case .twoMonth:
//			return "\(priceFormatter.string(from: product.price.dividing(by: 2.0)) ?? "") / mo"
//		case .monthly:
//			return "\(localizedPriceString) / mo"
//		case .weekly:
//			return "\(localizedPriceString) / wk"
//		default:
//			return ""
//		}
//	}
//
//	func span() -> String {
//		switch packageType {
//		case .lifetime:
//			return "Lifetime"
//		case .annual:
//			return "1 Year"
//		case .sixMonth:
//			return "6 Months"
//		case .threeMonth:
//			return "3 Months"
//		case .twoMonth:
//			return "2 Months"
//		case .monthly:
//			return "1 Months"
//		case .weekly:
//			return "1 Week"
//		default:
//			return "\(identifier)"
//		}
//	}
//}
//
//class QuestionTimer: View {
//	enum State {
//		case stopped
//		case running
//		case paused
//	}
//
//	private let label = Label(text: "00:00")
//	private var timer: Timer? = nil
//	private var seconds: Int? = nil
//
//	let stopButton = ImageButton(systemIcon: "xmark", padding: .zero)
//	private let controlButton = ImageButton(systemIcon: "pause.circle", padding: .zero)
//
//	override init() {
//		super.init()
//
//		backgroundColor = UIColor.black.withAlphaComponent(0.7)
//		label.font = UIFont.systemFont(ofSize: 12)
//		label.textAlignment = .center
//
//		clipsToBounds = true;
//		layer.masksToBounds = true;
//		layer.cornerRadius = 15;
//
//		addSubview(controlButton)
//		addSubview(label)
//		addSubview(stopButton)
//
//		controlButton.action = {
//			if self.isActive() {
//				self.pause()
//				self.controlButton.setSystemIcon("play.circle")
//			} else {
//				self.resume()
//				self.controlButton.setSystemIcon("pause.circle")
//			}
//		}
//
//		NSLayoutConstraint.activate([
//			controlButton.topAnchor.constraint(equalTo: topAnchor),
//			controlButton.bottomAnchor.constraint(equalTo: bottomAnchor),
//			controlButton.leadingAnchor.constraint(equalTo: leadingAnchor),
//			controlButton.widthAnchor.constraint(equalTo: controlButton.heightAnchor),
//
//			stopButton.topAnchor.constraint(equalTo: topAnchor),
//			stopButton.bottomAnchor.constraint(equalTo: bottomAnchor),
//			stopButton.trailingAnchor.constraint(equalTo: trailingAnchor),
//			stopButton.widthAnchor.constraint(equalTo: stopButton.heightAnchor),
//
//			label.topAnchor.constraint(equalTo: topAnchor),
//			label.bottomAnchor.constraint(equalTo: bottomAnchor),
//			label.leadingAnchor.constraint(equalTo: controlButton.trailingAnchor),
//			label.trailingAnchor.constraint(equalTo: stopButton.leadingAnchor),
//
//			heightAnchor.constraint(equalToConstant: 30),
//			widthAnchor.constraint(equalToConstant: 120),
//		])
//	}
//
//	func isActive() -> Bool {
//		return timer != nil
//	}
//
//	func start() {
//		timer?.invalidate()
//		seconds = 0
//		label.text = duration(seconds: 0)
//		timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
//	}
//
//	func stop() {
//		timer?.invalidate()
//		timer = nil
//		seconds = nil
//	}
//
//	@objc func fireTimer() {
//		guard let _ = seconds else { return }
//		self.seconds! += 1
//		label.text = duration(seconds: self.seconds!)
//	}
//
//	private func pause() {
//		timer?.invalidate()
//		timer = nil
//	}
//
//	private func resume() {
//		timer?.invalidate()
//
//		timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
//	}
//
//	private func duration(seconds: Int) -> String {
//		let ss = seconds % 60
//		let mm = Int(floor(Double(seconds / 60))) % 60
//		let hh = Int(floor(Double(seconds) / 60.0))
//		if hh >= 1 {
//			let s = String(format: "%02d", ss)
//			let m = String(format: "%02d", mm)
//			return "\(hh):\(m):\(s)"
//		} else {
//			let s = String(format: "%02d", ss)
//			let m = String(format: "%02d", mm)
//			return "\(m):\(s)"
//		}
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}

class HorizontalProgressBar: View {
	var colour: UIColor? = .gray
	var progress: CGFloat = 0.5 {
		didSet { setNeedsDisplay() }
	}
	
	private let progressLayer = CALayer()
	private let backgroundMask = CAShapeLayer()
	
	override init() {
		super.init()
		layer.addSublayer(progressLayer)
		backgroundColor = .green
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func draw(_ rect: CGRect) {
		backgroundMask.path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.25).cgPath
		layer.mask = backgroundMask
		
		let progressRect = CGRect(origin: .zero, size: CGSize(width: rect.width * progress, height: rect.height))
		
		progressLayer.frame = progressRect
		progressLayer.backgroundColor = colour?.cgColor
	}
}

class PlainCircularProgressBar: View {
	var ringWidth: CGFloat = 5
	var colour: UIColor? = .gray {
		didSet { setNeedsDisplay() }
	}
	var progress: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}

	private var progressLayer = CAShapeLayer()
	private var backgroundMask = CAShapeLayer()

	override init() {
		super.init()
		setupLayers()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupLayers()
	}

	private func setupLayers() {
		backgroundMask.lineWidth = ringWidth
		backgroundMask.fillColor = nil
		backgroundMask.strokeColor = UIColor.black.cgColor
		layer.mask = backgroundMask

		progressLayer.lineWidth = ringWidth
		progressLayer.fillColor = nil
		layer.addSublayer(progressLayer)
		layer.transform = CATransform3DMakeRotation(CGFloat(90 * Double.pi / 180), 0, 0, -1)
	}

	override func draw(_ rect: CGRect) {
		let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
		backgroundMask.path = circlePath.cgPath

		progressLayer.path = circlePath.cgPath
		progressLayer.lineCap = .round
		progressLayer.strokeStart = 0
		progressLayer.strokeEnd = progress
		progressLayer.strokeColor = colour?.cgColor
	}
}

//class ProgressView: View {
//	private let label = Label()
//	private let progress = PlainCircularProgressBar()
//
//	override init() {
//		super.init()
//
//		addSubview(progress)
//		addSubview(label)
//
//		label.text = "18 Questions out of 100 Completed"
//
//		NSLayoutConstraint.activate([
//			label.leadingAnchor.constraint(equalTo: leadingAnchor),
//			label.trailingAnchor.constraint(equalTo: trailingAnchor),
//			label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
//			label.bottomAnchor.constraint(equalTo: progress.topAnchor, constant: -8),
//
//			progress.leadingAnchor.constraint(equalTo: leadingAnchor),
//			progress.trailingAnchor.constraint(equalTo: trailingAnchor),
//			progress.bottomAnchor.constraint(equalTo: bottomAnchor),
//			progress.heightAnchor.constraint(equalToConstant: 20)
//		])
//	}
//
//	override func layoutSubviews() {
//		super.layoutSubviews()
//		self.setNeedsDisplay()
//		progress.setNeedsDisplay()
//	}
//
//	required init?(coder: NSCoder) {
//		fatalError("init(coder:) has not been implemented")
//	}
//}

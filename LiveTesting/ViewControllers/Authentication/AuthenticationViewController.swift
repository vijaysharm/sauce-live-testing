//
//  AuthenticationViewController.swift
//  LiveTesting
//

import UIKit
import Combine

/**
 * TODO: Attach success fail back to error / progress
 */
class AuthenticationViewController: ViewController {
	class AuthenticationView: View, UITextFieldDelegate {
		private let usernameInput = SauceInput()
		private let passwordInput = SauceInput()
		
		private var loginAction: (() -> Void)? = nil
		private var subscriptions = Set<AnyCancellable>()
		
		init(model: AuthenticationViewModel) {
			super.init()
			
			let contentView: UIStackView = {
				let view = UIStackView()
				view.translatesAutoresizingMaskIntoConstraints = false
				view.axis = .vertical
				view.distribution = .fill
				view.alignment = .fill
				
				return view
			}()
			let loginButton = SauceActionButton(
				title: "Log in".loc
			)
			
			backgroundColor = UIColor.sauceLabs.white
			contentView.addArrangedSubview(Spacer(height: 20))
			contentView.addArrangedSubview(bold("Sign in".loc))
			contentView.addArrangedSubview(Spacer(height: 32))
			contentView.addArrangedSubview(SauceLabel(text: "User Name".loc))
			contentView.addArrangedSubview(Spacer(height: 4))
			contentView.addArrangedSubview(usernameInput)
			contentView.addArrangedSubview(Spacer(height: 16))
			contentView.addArrangedSubview(SauceLabel(text: "Password".loc))
			contentView.addArrangedSubview(Spacer(height: 4))
			contentView.addArrangedSubview(passwordInput)
			contentView.addArrangedSubview(Spacer(height: 64))
			contentView.addArrangedSubview(loginButton)
			contentView.addArrangedSubview(Spacer(height: 20))
			
			addSubview(contentView)
			pin(contentView, to: [.top()])
			NSLayoutConstraint.activate([
				contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
				contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
				contentView.heightAnchor.constraint(equalTo: heightAnchor)
			])
			
			layer.borderWidth = 0.5
			layer.borderColor = UIColor.lightGray.withAlphaComponent(0.9).cgColor
			
			usernameInput.keyboardType = .emailAddress
			usernameInput.returnKeyType = .next
			usernameInput.tag = 0
			usernameInput.enablesReturnKeyAutomatically = true
			usernameInput.delegate = self
			usernameInput.bind(to: model.username)
			
			passwordInput.isSecureTextEntry = true
			passwordInput.returnKeyType = .go
			passwordInput.tag = 1
			passwordInput.enablesReturnKeyAutomatically = true
			passwordInput.delegate = self
			passwordInput.bind(to: model.password)
			
			loginAction = { [weak self] in
				self?.notifyLogin()
				model.login()
			}
			loginButton.onClicked.sink { [weak self] in
				self?.loginAction?()
			}.store(in: &subscriptions)
			
			loginButton.isEnabled = model.buttonEnabled.value
			model.buttonEnabled.sink {
				loginButton.isEnabled = $0
			}.store(in: &subscriptions)
			
			if model.isValid() {
				self.loginAction?()
			}
		}
		
		func focus() {
			usernameInput.becomeFirstResponder()
		}
		
		private func notifyLogin() {
			[self.usernameInput, self.passwordInput].forEach {
				$0.resignFirstResponder()
			}
		}
		
		private func bold(_ text: String) -> Label {
			let title = Label(text: text)
			title.font = .proximaSemiBold(size: 24)
			title.textColor = .sauceLabs.black
			
			return title
		}
		
		func textFieldShouldReturn(_ textField: UITextField) -> Bool {
			let nextTag = textField.tag + 1
			if let field = textField.superview?.viewWithTag(nextTag) as? UIResponder {
				field.becomeFirstResponder()
				return true
			}
			
			textField.resignFirstResponder()
			loginAction?()
			return false
		}
		
		required init(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	private let authenticationView: AuthenticationView
	private let error = SauceErrorBanner()
	private var progress: SauceProgress?
	
	private var constraint: NSLayoutConstraint!
	private var subscriptions = Set<AnyCancellable>()
	
	init(model: AuthenticationViewModel) {
		self.authenticationView = AuthenticationView(model: model)
		super.init(nibName: nil, bundle: nil)

		view.backgroundColor = .sauceLabs.lightGreen
		modalPresentationStyle = .fullScreen
		
		let contentView = ScrollableStackView(padding: 0, spacing: 0)
		contentView.addView(banner())
		contentView.addView(authenticationView)
		
		view.addSubview(contentView)
		fill(with: contentView, useSafeArea: true)
		
		view.addSubview(error)
		view.pin(error, to: [.leading(), .trailing()], useSafeArea: true)
		
		constraint = error.bottomAnchor.constraint(
			equalTo: view.safeAreaLayoutGuide.bottomAnchor,
			constant: 100
		)
		constraint.isActive = true

		error.text = model.error.value
		model.error.sink { [weak self] in
			guard let message = $0 else { return }
			self?.showError(message)
		}.store(in: &subscriptions)
		
		self.progress(show: model.showProgress.value)
		model.showProgress.sink { [weak self] in
			self?.progress(show: $0)
		}.store(in: &subscriptions)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		authenticationView.focus()
	}
	
	private func progress(show: Bool) {
		self.progress?.removeFromSuperview()
		self.progress = nil
		if show {
			let progress = SauceProgress()
			view.addSubview(progress)
			fill(with: progress)
			self.progress = progress
		}
	}
	
	private func showError(_ message: String) {
		error.text = message
		UIView.animate(withDuration: 0.4, delay: 0, animations: {
			self.constraint.constant = 0
			self.view.layoutIfNeeded()
		}, completion: { _ in
			UIView.animate(withDuration: 0.4, delay: 4, animations: {
				self.constraint.constant = 100
				self.view.layoutIfNeeded()
			}, completion: { _ in
				self.error.text = ""
			})
		})
	}
	
	private func banner() -> UIView {
		let image = ImageView(name: "Banner")
		image.contentMode = .scaleAspectFit
		let view = View()
		view.addSubview(image)

		view.center(image)
		NSLayoutConstraint.activate([
			view.heightAnchor.constraint(equalTo: image.heightAnchor, constant: 40),
			image.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
		])

		return view
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}



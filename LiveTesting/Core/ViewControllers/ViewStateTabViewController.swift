//
//  ViewStateTabViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class ViewStateTabViewController<DataType, ProgressType, ErrorType: Error>: ViewController {
	var subscriptions = Set<AnyCancellable>()
	var progress: SauceProgress?
	var errorView: SauceErrorView?
	
	init(state: CurrentValueSubject<ViewState<DataType, ProgressType, ErrorType>, Never>) {
		super.init(nibName: nil, bundle: nil)
		
		self.view.backgroundColor = UIColor.sauceLabs.lightGrey
		state.receive(on: DispatchQueue.main).sink { [weak self] in
			guard let self = self else { return }
			switch $0 {
			case .empty:
				self.showEmpty()
				break
			case .loading(let type):
				self.show(progress: type)
				break
			case .error(let error):
				self.show(error: error)
				break
			case .content(let data):
				self.show(content: data)
				break
			}
		}.store(in: &subscriptions)
	}
	
	func showEmpty() {
		
	}
	
	func show(progress: ProgressType) {
		self.progress?.removeFromSuperview()
		self.progress = self.fill(view: SauceProgress())
	}
	
	func show(error: ErrorType) {
		self.errorView?.removeFromSuperview()
		self.errorView = self.fill(view: SauceErrorView(
			title: "Uh Oh!".loc,
			subtitle: "Something went wrong".loc,
			instructions: "Log out from Settings and try again".loc
		))
		self.errorView?.alpha = 0
		UIView.animate(withDuration: 1, delay: 0) {
			self.errorView?.alpha = 1
		}
	}
	
	func show(content: DataType) {
		
	}
	
	func fill<T: UIView>(view: T) -> T {
		self.view.subviews.forEach { $0.removeFromSuperview() }
		self.view.addSubview(view)
		self.fill(with: view, useSafeArea: true)
		return view
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

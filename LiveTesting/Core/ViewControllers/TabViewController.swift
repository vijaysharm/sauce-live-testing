//
//  TabViewController.swift
//  LiveTesting
//

import UIKit
import Combine

class TabViewController<DataType, ProgressType, ErrorType: Error>: ViewStateTabViewController<DataType, ProgressType, ErrorType> {
	init(
		title: String,
		image: UIImage,
		state: CurrentValueSubject<ViewState<DataType, ProgressType, ErrorType>, Never>
	) {
		super.init(state: state)
		tabBarItem = UITabBarItem(
			title: title, image: image, tag: 0
		)
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		.darkContent
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

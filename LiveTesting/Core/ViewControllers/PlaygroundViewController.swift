//
//  PlaygroundViewController.swift
//  LiveTesting
//

import UIKit
import Combine

struct SFSymbolItem: Hashable {
	let name: String
	let image: UIImage
	
	init(name: String) {
		self.name = name
		self.image = UIImage(systemName: name)!
	}
}

struct PlaySearchableItemModel: SearchableItemModel {	
	let items: CurrentValueSubject<[SFSymbolItem], Never>
	let facets: PlaySearchableFacets
	let filters: PlayAppliedFacets
}

struct PlaySearchableFacets: SearchableFacets {
	
}

class PlayCell: UICollectionViewCell {
	private let imageView: UIImageView = {
		let view = UIImageView(frame: .zero)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.contentMode = .scaleAspectFit
		
		return view
	}()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	
		addSubview(imageView)
		NSLayoutConstraint.activate([
			imageView.topAnchor.constraint(equalTo: topAnchor),
			imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
			imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
			imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
		])
	}
	
	func set(data: SFSymbolItem) {
		imageView.image = data.image
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

struct PlayAppliedFacets: AppliedFacets {
	let textType = CurrentValueSubject<String, Never>("")
	let filterCount = CurrentValueSubject<Int, Never>(0)
	let itemCount = CurrentValueSubject<Int, Never>(0)
	let showFilterView = PassthroughSubject<Void, Never>()
}

class PlaygroundViewController: ViewController {
	private var subscriptions = Set<AnyCancellable>()
	
	init() {
		super.init(nibName: nil, bundle: nil)
		view.backgroundColor = .black
		
		let items = CurrentValueSubject<[SFSymbolItem], Never>(
			[
				SFSymbolItem(name: "iphone.homebutton"),
				SFSymbolItem(name: "pc"),
				SFSymbolItem(name: "headphones"),
				SFSymbolItem(name: "sun.min"),
				SFSymbolItem(name: "sunset.fill"),
			]
		)

		let model = PlaySearchableItemModel(
			items: items,
			facets: PlaySearchableFacets(),
			filters: PlayAppliedFacets()
		)
//		let view = SauceSearchableListView<SFSymbolItem>(
//			model: model,
//			configuration: SauceSearchableListCongiuration(
//				maxHeight: 250,
//				configureView: { list in
//					list.register(PlayCell.self, forCellWithReuseIdentifier: "cell")
//				},
//				configureCell: { _, cell, _, data in
//					guard let cell = cell as? PlayCell else { return }
//					cell.set(data: data)
//				},
//				configureLayout: nil,
//				action: { _, _ in
//					print("Action received")
//				}
//			)
//		)
//		model.facets
		let platformSection = SauceTableSection(
			title: "Platform".loc,
			rows: [
				DefaultTableRow(configure: { cell in
					cell.textLabel?.text = "ANDROID"
				}),
				DefaultTableRow(configure: { cell in
					cell.textLabel?.text = "iOS"
				}),
			],
			action: { indexPath, view, controller in
				
			}
		)
		
		let config = SauceFilterViewConfig(sections: [
			SauceFilterTableSectionBuilder(
				title: "Platform",
				keys: ["ANDROID", "IOS"],
				values: [],
				mapping: ["ANDROID": "Android", "IOS": "iOS"],
				apply: { _ in }
			)
		], apply: { _ in })
		config.filterCountChanged.sink {
			print("new Count: \($0)")
		}.store(in: &subscriptions)
		let view = SauceTableView(model: config)
		
		self.view.addSubview(view)
		fill(with: view)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

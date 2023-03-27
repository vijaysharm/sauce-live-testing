//
//  ProgressView.swift
//  CircularProgress
//
//  Created by Zafar on 10/3/20.
//  Copyright © 2020 Zafar. All rights reserved.
//
// https://github.com/zafarivaev/CircularLoadingIndicator

import UIKit

class ProgressView: UIView {
	class StrokeColorAnimation: CAKeyframeAnimation {
		override init() {
			super.init()
		}
		
		init(colors: [CGColor], duration: Double) {
			super.init()
			
			self.keyPath = "strokeColor"
			self.values = colors
			self.duration = duration
			self.repeatCount = .greatestFiniteMagnitude
			self.timingFunction = .init(name: .easeInEaseOut)
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	class StrokeAnimation: CABasicAnimation {
		override init() {
			super.init()
		}

		init(
			type: StrokeType,
			beginTime: Double = 0.0,
			fromValue: CGFloat,
			toValue: CGFloat,
			duration: Double
		) {
			super.init()
			
			self.keyPath = type == .start ? "strokeStart" : "strokeEnd"
			self.beginTime = beginTime
			self.fromValue = fromValue
			self.toValue = toValue
			self.duration = duration
			self.timingFunction = .init(name: .easeInEaseOut)
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		enum StrokeType {
			case start
			case end
		}
	}
	
	class RotationAnimation: CABasicAnimation {
		enum Direction: String {
			case x, y, z
		}
		
		override init() {
			super.init()
		}
		
		public init(
			direction: Direction,
			fromValue: CGFloat,
			toValue: CGFloat,
			duration: Double,
			repeatCount: Float
		) {

			super.init()
			
			self.keyPath = "transform.rotation.\(direction.rawValue)"
			self.fromValue = fromValue
			self.toValue = toValue
			self.duration = duration
			self.repeatCount = repeatCount
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	class ProgressShapeLayer: CAShapeLayer {
		public init(strokeColor: UIColor, lineWidth: CGFloat) {
			super.init()
			
			self.strokeColor = strokeColor.cgColor
			self.lineWidth = lineWidth
			self.fillColor = UIColor.clear.cgColor
			self.lineCap = .round
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	// MARK: - Properties
	private let colors: [UIColor]
	private let lineWidth: CGFloat
	
	private lazy var shapeLayer: ProgressShapeLayer = {
		return ProgressShapeLayer(strokeColor: colors.first!, lineWidth: lineWidth)
	}()
	
	var isAnimating: Bool = false {
		didSet {
			if isAnimating {
				self.animateStroke()
				self.animateRotation()
			} else {
				self.shapeLayer.removeFromSuperlayer()
				self.layer.removeAllAnimations()
			}
		}
	}
	
	// MARK: - Initialization
	init(
		colors: [UIColor],
		lineWidth: CGFloat
	) {
		self.colors = colors
		self.lineWidth = lineWidth
		
		super.init(frame: .zero)
		self.backgroundColor = .clear
		self.translatesAutoresizingMaskIntoConstraints = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) is not supported")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.layer.cornerRadius = self.frame.width / 2
		
		let path = UIBezierPath(ovalIn:
			CGRect(
				x: 0,
				y: 0,
				width: self.bounds.width,
				height: self.bounds.width
			)
		)
		
		shapeLayer.path = path.cgPath
	}
	
	// MARK: - Animations
	func animateStroke() {
		let startAnimation = StrokeAnimation(
			type: .start,
			beginTime: 0.25,
			fromValue: 0.0,
			toValue: 1.0,
			duration: 0.75
		)
		
		let endAnimation = StrokeAnimation(
			type: .end,
			fromValue: 0.0,
			toValue: 1.0,
			duration: 0.75
		)
		
		let strokeAnimationGroup = CAAnimationGroup()
		strokeAnimationGroup.duration = 1
		strokeAnimationGroup.repeatDuration = .infinity
		strokeAnimationGroup.animations = [startAnimation, endAnimation]
		
		shapeLayer.add(strokeAnimationGroup, forKey: nil)
		
		let colorAnimation = StrokeColorAnimation(
			colors: colors.map { $0.cgColor },
			duration: strokeAnimationGroup.duration * Double(colors.count)
		)

		shapeLayer.add(colorAnimation, forKey: nil)
		
		self.layer.addSublayer(shapeLayer)
	}
	
	func animateRotation() {
		let rotationAnimation = RotationAnimation(
			direction: .z,
			fromValue: 0,
			toValue: CGFloat.pi * 2,
			duration: 2,
			repeatCount: .greatestFiniteMagnitude
		)
		
		self.layer.add(rotationAnimation, forKey: nil)
	}
}

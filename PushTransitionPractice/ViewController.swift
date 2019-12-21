/**
# ZMIOUSB.swift - PushTransitionPractice

- Created by zumuya on 2019/08/26.

Copyright © 2019 zumuya
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR
APARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/

import Cocoa

class ViewController: NSViewController
{
	@IBOutlet var label: NSTextField!
	@IBOutlet var categoryPopUpButton: NSPopUpButton!
	@IBOutlet var filterPopUpButton: NSPopUpButton!
	
	@objc dynamic var isTransitionEnabled = true
	
	var layer: CALayer!
	
	//MARK: - View
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		view.layerUsesCoreImageFilters = true
		view.wantsLayer = true
		layer = view.layer
		layer.backgroundColor = NSColor.windowBackgroundColor.cgColor
	}
		
	//MARK: - Animation
	
	@objc dynamic let categories: [[String: Any]] = [
		[
			"name": "Standard",
			"choices": ["Fade", "Move In", "Push", "Reveal"],
		],
		[
			"name": "Private",
			"choices":  ["Suck", "Rotate", "Cube", "Flip", "Page Curl", "Ripple", "Camera Iris"],
			///<http://iphonedevwiki.net/index.php/CATransition>
			"typeNames": ["suckEffect", "rotate", "cube", "flip", "pageCurl", "rippleEffect", "cameraIris"],
		],
		[
			"name": "Filter",
			"choices": ["CIBarsSwipeTransition", "CICopyMachineTransition", "CIFlashTransition", "CIModTransition", "CIPageCurlWithShadowTransition", "CIRippleTransition", "CISwipeTransition"],
			///<https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html>
			"filterNames": ["CIBarsSwipeTransition", "CICopyMachineTransition", "CIFlashTransition", "CIModTransition", "CIPageCurlWithShadowTransition", "CIRippleTransition", "CISwipeTransition"],
		],
		[
			"name": "Custom Filter",
			"choices": ["Navigation", "Spread", "Genie", "Tab"]
		]
	]
	
	func pushTransition(button: NSButton? = nil, isPop: Bool) -> CATransition?
	{
		guard isTransitionEnabled else {
			return nil
		}
		
		let category = categories[categoryPopUpButton.indexOfSelectedItem]
		
		var timingFunctionName = CAMediaTimingFunctionName.easeOut
		var filter: CIFilter?
		var transitionType: CATransitionType?
		var transitionSubtype: CATransitionSubtype?
		var duration: CFTimeInterval = 0.5
		do {
			switch category["name"] as! String {
				
			case "Standard":
				let types: [CATransitionType] = [.fade, .moveIn, .push, .reveal]
				transitionType = types[filterPopUpButton.indexOfSelectedItem]
				
				transitionSubtype = (isPop ? .fromLeft : .fromRight)
				
			case "Private":
				let typeNames = category["typeNames"] as! [String]
				let typeName = typeNames[filterPopUpButton.indexOfSelectedItem]
				
				transitionType = .init(rawValue: typeName)
				transitionSubtype = (isPop ? .fromLeft : .fromRight)
				switch typeName {
				case "rotate":
					transitionSubtype = .init(rawValue: (isPop ? "90ccw" : "90cw"))
				case "pageCurl":
					if isPop {
						transitionType = .init(rawValue: "pageUnCurl")
					}
					transitionSubtype = .fromRight
				case "rippleEffect":
					duration = 1.0
				default:
					break
				}
				
			case "Filter":
				let filterNames = category["filterNames"] as! [String]
				let filterName = filterNames[filterPopUpButton.indexOfSelectedItem]
				
				filter = CIFilter(name: filterName)
				filter?.setDefaults()
				
				switch filterName {
				case "CIPageCurlWithShadowTransition":
					filter?.setValue(isPop ? -45 : 45, forKey: kCIInputAngleKey)
				default:
					break
				}
				
			case "Custom Filter":
				switch filterPopUpButton.indexOfSelectedItem {
				case 0:
					filter = NavigationTransitionFilter()
				case 1:
					filter = SpreadTransitionFilter()
				case 2:
					filter = GenieTransitionFilter()
					if isPop {
						timingFunctionName = .easeIn
					}
				case 3:
					filter = TabTransitionFilter()
				default:
					break
				}
				filter?.setDefaults()
				
			default:
				break
			}
		}
		if let filter = filter {
			///set attributes to filters.
			if filter.attributes[kCIInputCenterKey] != nil {
				if let button = button {
					let buttonFrameInView = view.convert(button.bounds, from: button)
					filter.setValue(CIVector(cgPoint: .init(x: buttonFrameInView.midX, y: buttonFrameInView.midY)), forKey: kCIInputCenterKey)
				} else {
					let bounds = view.bounds
					filter.setValue(CIVector(cgPoint: .init(x: bounds.midX, y: bounds.midY)), forKey: kCIInputCenterKey)
				}
			}
			if filter.attributes["inputShadingImage"] != nil {
				///prepare empty image.
				let imageBounds = NSRect(x: 0, y: 0, width: 1, height: 1)
				let image = NSImage(size: imageBounds.size, flipped: true) { _ in true }
				filter.setValue(CIImage(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!), forKey: "inputShadingImage")
			}
			if filter.attributes["inputIsReverseTransition"] != nil {
				filter.setValue(isPop, forKey: "inputIsReverseTransition")
			}
		}
		let transition = CATransition(); do {
			if let transitionType = transitionType {
				transition.type = transitionType
			}
			transition.subtype = transitionSubtype
			transition.filter = filter
			transition.timingFunction = .init(name: timingFunctionName)
			transition.duration = (duration * (NSEvent.modifierFlags.contains(.shift) ? 3.0 : 1.0))
		}
		return transition
	}
	
	static let pushAnimationKey = kCATransition
	
	//MARK: - Push & Pop
	
	func pushOrPop(transition: CATransition?, isPop: Bool)
	{
		if let transition = transition {
			layer.add(transition, forKey: Self.pushAnimationKey)
		} else {
			layer.removeAnimation(forKey: Self.pushAnimationKey)
		}
		
		///Disable implicit animations
		CATransaction.begin()
		defer { CATransaction.commit() }
		CATransaction.setDisableActions(true)
		
		do { ///Update background color
			let color: NSColor
			if !NSEvent.modifierFlags.contains(.option) {
				color = .init(hue: .random(in: 0...1.0), saturation: 0.8, brightness: 0.6, alpha: 1.0)
			} else {
				color = .windowBackgroundColor
			}
			layer.backgroundColor = color.cgColor
		}
		do { ///Update title
			var titles: Set<String> = ["Apple", "Mango", "Orange", "Peech", "Grape", "Melon"]
			titles.remove(label.stringValue)
			label.stringValue = titles.randomElement()!
		}
	}
	func pushOrPop(button: NSButton? = nil, isPop: Bool, transitionConfigurationHandler: ((CATransition) -> Void)? = nil) -> Bool
	{
		if let transition = pushTransition(button: button, isPop: isPop) {
			transitionConfigurationHandler?(transition)
			pushOrPop(transition: transition, isPop: isPop)
		} else {
			pushOrPop(transition: nil, isPop: isPop)
		}
		return true
	}
	
	//MARK: - Swipe Context
	
	class SwipeContext
	{
		enum Result
		{
			case success
			case cancelled
		}
		
		let direction: NSRectEdge
		var result: Result?
		var isStopped = false
		
		init?(eventDelta: CGPoint)
		{
			guard (abs(eventDelta.x) > 0.0), (abs(eventDelta.x) > abs(eventDelta.y * 2.0)) else {
				return nil
			}
			self.direction = ((eventDelta.x > 0.0) ? .maxX : .minX)
		}
		
		var completionHandler: ((SwipeContext) -> Void)?
		
		func complete()
		{
			completionHandler?(self)
		}
	}
	
	var swipeContext: SwipeContext?
	
	func cancelTrackingAndCommitCurrentSwipe()
	{
		if let swipeContext = swipeContext {
			swipeContext.isStopped = true
			swipeContext.complete()
			self.swipeContext = nil
		}
	}
	
	//MARK: - Event Tracking
	
	override func scrollWheel(with event: NSEvent)
	{
		return
		
		let eventDelta = CGPoint(x: event.deltaX, y: event.deltaY)
		
		guard event.phase == .changed, let swipeContext = SwipeContext(eventDelta: eventDelta) else {
			return
		}
		
		cancelTrackingAndCommitCurrentSwipe()
		
		let layer = self.layer!
		
		let isPop = (eventDelta.x > 0.0)
		guard let transition = pushTransition(isPop: isPop) else {
			return
		}
		self.swipeContext = swipeContext
		
		let duration: TimeInterval = 1.0
		layer.speed = 0.0
		
		transition.duration = duration
		transition.isRemovedOnCompletion = false
		
		let oldTitle = label.stringValue
		let oldBackgroundColor = layer.backgroundColor
		let cancelHandler = {
			self.label.stringValue = oldTitle
			layer.backgroundColor = oldBackgroundColor
		}
		pushOrPop(transition: transition, isPop: isPop)
		
		swipeContext.completionHandler = { swipeContext in
			do {
				CATransaction.begin()
				defer { CATransaction.commit() }
				CATransaction.setDisableActions(true)
				
				if (swipeContext.result == .success) {
					
				} else {
					cancelHandler()
				}
			}
			layer.speed = 1.0
			layer.timeOffset = 0.0
			layer.removeAnimation(forKey: Self.pushAnimationKey)
			
			//Force redraw, otherwise old animating state may be cached on next animation.
			CATransaction.flush()
		}
		
		event.trackSwipeEvent(options: [.lockDirection], dampenAmountThresholdMin: (isPop ? 0 : -1), max: (isPop ? 1 : 0)) { (gestureAmount, phase, isComplete, stopPtr) in
			if swipeContext.isStopped {
				stopPtr.pointee = true
				return
			}
			
			var timeOffset = (duration * TimeInterval(abs(gestureAmount)))
			timeOffset = max(timeOffset, 0.01)
			layer.timeOffset = timeOffset
			
			switch phase {
			case .ended:
				swipeContext.result = .success
			case .cancelled:
				swipeContext.result = .cancelled
			default:
				break
			}
			
			if isComplete {
				swipeContext.complete()
				self.swipeContext = nil
			}
		}
	}
	
	//MARK: - Actions
	
	@IBAction func push(_ sender: Any?)
	{
		cancelTrackingAndCommitCurrentSwipe()
		_ = pushOrPop(button: sender as? NSButton, isPop: false)
	}
	@IBAction func pop(_ sender: Any?)
	{
		cancelTrackingAndCommitCurrentSwipe()
		_ = pushOrPop(button: sender as? NSButton, isPop: true)
	}
}


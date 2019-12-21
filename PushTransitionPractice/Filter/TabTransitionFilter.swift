/**
# TabTransitionFilter.swift - PushTransitionPractice

- Created by zumuya on 2019/08/27.

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

class TabTransitionFilter: CIFilter, CIFilterProtocol
{
	//MARK: - Attributes
	
	@objc dynamic var inputTime: CGFloat = 0.0
	@objc dynamic var inputExtent: CIVector?
	@objc dynamic var inputImage: CIImage?
	@objc dynamic var inputTargetImage: CIImage?
	@objc dynamic var inputIsReverseTransition = false
	
	//make some setters empty to prevent from errors.
	override func setNilValueForKey(_ key: String) { }
	override func setValue(_ value: Any?, forUndefinedKey key: String) { }

	static func customAttributes() -> [String : Any]?
	{ [
		kCIAttributeFilterDisplayName: "Tab Transition",
		kCIAttributeFilterCategories: [kCICategoryTransition],
		#keyPath(inputTime): [
			kCIAttributeClass: NSNumber.self,
			kCIAttributeType: kCIAttributeTypeScalar,
			kCIAttributeDefault: 0.0,
			kCIAttributeIdentity: 0.0,
			kCIAttributeMin: 0.0,
			kCIAttributeMax: 1.0,
			kCIAttributeSliderMin: 0.0,
			kCIAttributeSliderMax: 1.0,
		],
		#keyPath(inputExtent): [
			kCIAttributeClass: CIVector.self,
			kCIAttributeType: kCIAttributeTypeRectangle,
			kCIAttributeDefault: CIVector(cgRect: .zero),
			kCIAttributeIdentity: CIVector(cgRect: .zero),
		],
		#keyPath(inputImage): [
			kCIAttributeClass: CIImage.self,
		],
		#keyPath(outputImage): [
			kCIAttributeClass: CIImage.self,
		],
		#keyPath(inputIsReverseTransition): [
			kCIAttributeClass: NSNumber.self,
			kCIAttributeType: kCIAttributeTypeBoolean,
			kCIAttributeDefault: false,
		],
	] }
	
	//MARK: - Child Filters
	
	let affineTransformFilter = CIFilter(name: "CIAffineTransform")
	let colorControlsFilter = CIFilter(name: "CIColorControls")
	
	//MARK: - Output
	
	override var outputImage: CIImage?
	{
		guard let sourceImage = inputImage, let destinationImage = inputTargetImage else {
			print("\(Self.self).\(#function): No input image!")
			return nil
		}
		guard let extent = inputExtent?.cgRectValue else {
			print("\(Self.self).\(#function): No extent!")
			return nil
		}
		
		let progress = inputTime
		let pushProgress = (inputIsReverseTransition ? (1.0 - progress) : progress)
		var leftImage = (inputIsReverseTransition ? destinationImage : sourceImage)
		var rightImage = (inputIsReverseTransition ? sourceImage : destinationImage)
		
		//imagine that we are in view of size { 2w, h } and visible rect becomes from { 0, 0, w, h } to { w, 0, w, h}.
		
		let scaleProgress: CGFloat = min(1.0, min((-4.0 * (pushProgress - 1.0)), (4.0 * pushProgress)))
		let minimumScale: CGFloat = 0.8
		
		if let affineTransformFilter = affineTransformFilter {
			[leftImage, rightImage].forEach {
				let isLeft = ($0 == leftImage)
				
				affineTransformFilter.setValue($0, forKey: kCIInputImageKey)
				
				let scale = (1.0 - (scaleProgress * (1.0 - minimumScale)))
				var scaleCenter = CGPoint(x: extent.midX, y: extent.midY)
				if !isLeft {
					scaleCenter.x += extent.width
				}
				var affineTransform = CGAffineTransform.identity; do {
					affineTransform = affineTransform
						.translatedBy(x: scaleCenter.x, y: scaleCenter.y)
						.translatedBy(x: -(extent.width * 0.5 * scale), y: -(extent.height * 0.5 * scale))
						.translatedBy(x: -(extent.width * pushProgress), y: 0.0)
						.scaledBy(x: scale, y: scale)
					if !isLeft {
						affineTransform = affineTransform
							.translatedBy(x: -(extent.width * (1.0 - minimumScale) * scaleProgress), y: 0.0)
					}
				}
				affineTransformFilter.setValue(affineTransform, forKey: kCIInputTransformKey)
				
				if let affineTransformImage = affineTransformFilter.outputImage {
					if isLeft {
						leftImage = affineTransformImage
					} else {
						rightImage = affineTransformImage
					}
				}
			}
		}
		
		return leftImage.composited(over: rightImage)
	}
}

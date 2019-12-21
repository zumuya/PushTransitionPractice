/**
# PushTransitionFilter.swift - PushTransitionPractice

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

class NavigationTransitionFilter: CIFilter, CIFilterProtocol
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
	
	let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
	
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
		var backImage = (inputIsReverseTransition ? destinationImage : sourceImage)
		var frontImage = (inputIsReverseTransition ? sourceImage : destinationImage)
		
		backImage = backImage
			.transformed(by: .init(translationX: -(extent.width * 0.5 * pushProgress), y: 0.0))
		
		var backCrop = extent
		backCrop.size.width = (backCrop.width * (1.0 - pushProgress))
		
		if let gradientFilter = gradientFilter {
			gradientFilter.setValue(CIVector(cgPoint: .init(x: backCrop.minX, y: 0.0)), forKey: "inputPoint0")
			gradientFilter.setValue(CIVector(cgPoint: .init(x: backCrop.maxX, y: 0.0)), forKey: "inputPoint1")
			gradientFilter.setValue(CIColor(cgColor: .init(gray: 0.0, alpha: (0.1 * min((pushProgress * 3.0), 1.0)))), forKey: "inputColor0")
			gradientFilter.setValue(CIColor(cgColor: .init(gray: 0.0, alpha: (0.3 * min((pushProgress * 3.0), 1.0)))), forKey: "inputColor1")
			
			if let gradientImage = gradientFilter.outputImage {
				backImage = gradientImage.composited(over: backImage)
			}
		}
		backImage = backImage
			.cropped(to: backCrop)
		
		frontImage = frontImage
			.transformed(by: .init(translationX: backCrop.maxX, y: 0.0))
		
		return frontImage.composited(over: backImage)
	}
}

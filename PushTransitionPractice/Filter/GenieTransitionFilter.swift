/**
# GenieTransitionFilter.swift - PushTransitionPractice

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

class GenieTransitionFilter: CIFilter, CIFilterProtocol
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
	
	let bumpDistortionFilter = CIFilter(name: "CIBumpDistortion")
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
		var backImage = (inputIsReverseTransition ? destinationImage : sourceImage)
		var frontImage = (inputIsReverseTransition ? sourceImage : destinationImage)
		
		let bumpCenter = CGPoint(x: extent.minX, y: extent.midY)
		let genieCenter = CGPoint(x: extent.minX, y: extent.midY)
		let scaleProgress = max(0.0, (1.5 * (pushProgress - 0.34)))
		let translationProgress = pow(pushProgress, 0.7)
		let bumpProgress = pow((1.0 - pushProgress), 0.5)
		let minimumScale: CGFloat = 0.3
		
		if let affineTransformFilter = affineTransformFilter {
			affineTransformFilter.setValue(frontImage, forKey: kCIInputImageKey)
			let scale = (minimumScale + (scaleProgress * (1.0 - minimumScale)))
			let affineTransform = CGAffineTransform.identity
				.translatedBy(x: ((extent.minX + genieCenter.x) * (1.0 - scale)), y: ((extent.minY + genieCenter.y) * (1.0 - scale)))
				.translatedBy(x: -(extent.width * minimumScale * (1.0 - translationProgress)), y: 0.0)
				.scaledBy(x: scale, y: scale)
			affineTransformFilter.setValue(affineTransform, forKey: kCIInputTransformKey)
			
			if let affineTransformImage = affineTransformFilter.outputImage {
				frontImage = affineTransformImage
				
				if let bumpDistortionFilter = bumpDistortionFilter {
					bumpDistortionFilter.setValue(frontImage, forKey: kCIInputImageKey)
					bumpDistortionFilter.setValue(CIVector(cgPoint: bumpCenter), forKey: kCIInputCenterKey)
					bumpDistortionFilter.setValue(max(extent.width, extent.height), forKey: kCIInputRadiusKey)
					bumpDistortionFilter.setValue((-1.8 * bumpProgress), forKey: kCIInputScaleKey)
					
					if let bumpDistortionImage = bumpDistortionFilter.outputImage {
						frontImage = bumpDistortionImage
					}
				}
			}
		}
		if let colorControlsFilter = colorControlsFilter {
			colorControlsFilter.setValue(backImage, forKey: kCIInputImageKey)
			colorControlsFilter.setValue(1.0, forKey: kCIInputSaturationKey)
			colorControlsFilter.setValue((-0.1 * pow(pushProgress, 2.0)), forKey: kCIInputBrightnessKey)
			colorControlsFilter.setValue(1.0, forKey: kCIInputContrastKey)
			
			if let colorControlsImage = colorControlsFilter.outputImage {
				backImage = colorControlsImage
			}
		}
		
		return frontImage.composited(over: backImage)
	}
}

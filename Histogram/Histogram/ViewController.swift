//
//  ViewController.swift
//  Histogram
//
//  Created by Thomas Wolf on 11.03.19.
//  Copyright © 2019 Thomas Wolf. All rights reserved.
//

import UIKit


//--------------------------------------------------------------------------------------------
//  Bitmap structure

public struct PixelData {
	var a, r, g, b: UInt8

	init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
		self.a = 255
		self.r = r
		self.g = g
		self.b = b
	}
	
	init(_ white: UInt8) {
		self.init(r: white, g: white, b: white)
	}
	
	init(_ v: IntData, div: Int) {
		self.a = 255
		self.r = UInt8(v.r * 255 / div)
		self.g = UInt8(v.g * 255 / div)
		self.b = UInt8(v.b * 255 / div)
	}
}

//--------------------------------------------------------------------------------------------
//  Histogram structure

public struct IntData {
	var r, g, b: Int
	
	init() {
		self.r = 0
		self.g = 0
		self.b = 0
	}
	
	var maxRGB : Int {
		return max( max(r, g), b)
	}
}

//--------------------------------------------------------------------------------------------

class ViewController: UIViewController {
	
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var histogramDraw: HistogramView!
	@IBOutlet weak var histogramView: UIImageView!
	@IBOutlet weak var histogramView1: UIImageView!
	
	let context = CIContext(options: [.workingColorSpace: NSNull()])

	let names = ["Karla.jpg", "Kerze.jpg", "Gradient.png", "Radial.png", "Gaussian.png", "Linear1.png"]
	var index = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()

		showPicture(name: names[index])
		index = (index + 1) % names.count
	}
	
	@IBAction func actionNextPicture(_ sender: Any) {
		showPicture(name: names[index])
		index = (index + 1) % names.count
	}
	
	//----------------------------------------------------------------------------------------
	//  Calculate different histograms of the image and display them
	
	func showPicture(name: String) {
		
		let sourceImage = UIImage(named: name )
		imageView.image = sourceImage
		
		let sourceCGImage = sourceImage!.cgImage!

		//------------------------------------------------------------------------------------
		// Calculate and display histogram (own subroutine)
		
		let histData = calculateHistogram(fromImage: sourceCGImage)
		histogramDraw.histData = histData
		histogramDraw.setNeedsDisplay()
		
		//------------------------------------------------------------------------------------
		// Convert histogram data in CIImage and use this as input for CIHistogramDisplayFilter
		
		let imageHist = CIImage(cgImage: imageFromARGB32Bitmap(pixels: histData, width: 256, height: 1)!)
		
		let histImage = histogramDisplayFilter(imageHist, height: 200, highLimit: 1.0, lowLimit: 0.0)
		let cgImage = context.createCGImage(histImage!, from: histImage!.extent)
		let uiImage = UIImage(cgImage: cgImage!)
		histogramView.image = uiImage

		//------------------------------------------------------------------------------------
		// Calculate and display histogram (Apple Core Image Filter)

		let sourceCIImage = CIImage(cgImage: sourceCGImage)
		let imageHist1 = areaHistogramFilter(sourceCIImage, rect: sourceCIImage.extent)

		let histImage1 = histogramDisplayFilter(imageHist1!, height: 200, highLimit: 1.0, lowLimit: 0.0)
		let cgImage1 = context.createCGImage(histImage1!, from: histImage1!.extent)
		let uiImage1 = UIImage(cgImage: cgImage1!)
		histogramView1.image = uiImage1
	}

	//----------------------------------------------------------------------------------------
	// Calculate histogram
	
	func calculateHistogram(fromImage image: CGImage) -> [PixelData] {
	
		var hist : [IntData] = Array(repeating: IntData(), count: 256)
		
		let pixelData = image.dataProvider!.data
		let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
		
		for i in 0..<Int(image.width * image.width) {
			hist[ Int(data[i*4+0]) ].r += 1
			hist[ Int(data[i*4+1]) ].g += 1
			hist[ Int(data[i*4+2]) ].b += 1
		}
		// max. value of all histogram entries and normalize output to 0...255
		let maxValue : Int = hist.reduce(0) { max($0, $1.maxRGB) }
		return hist.map { PixelData($0, div: maxValue) }
	}
	
	//----------------------------------------------------------------------------------------
	// Apple Core Image Filter
	
	func areaHistogramFilter(_ input: CIImage, rect: CGRect, count: Int = 256, scale: Float = 15) -> CIImage?
	{
		let filter = CIFilter(name:"CIAreaHistogram")
		filter?.setValue(input, forKey: kCIInputImageKey)
		filter?.setValue(CIVector(cgRect: rect), forKey: "inputExtent")
		filter?.setValue(count, forKey: "inputCount")
		filter?.setValue(scale, forKey: "inputScale")
		return filter?.outputImage
	}
	
	func histogramDisplayFilter(_ input: CIImage, height: Float = 100, highLimit: Float = 1.0, lowLimit: Float = 0.0) -> CIImage?
	{
		let filter = CIFilter(name:"CIHistogramDisplayFilter")
		filter?.setValue(input,     forKey: kCIInputImageKey)
		filter?.setValue(height,    forKey: "inputHeight")
		filter?.setValue(highLimit, forKey: "inputHighLimit")
		filter?.setValue(lowLimit,  forKey: "inputLowLimit")
		return filter?.outputImage
	}
	
	
	//----------------------------------------------------------------------------------------
	//  Convert pixel data to CGImage. With inspirations from
	//  https://stackoverflow.com/questions/30958427/pixel-array-to-uiimage-in-swift
	
	func imageFromARGB32Bitmap(pixels: [PixelData], width: Int, height: Int) -> CGImage? {
		
		guard width > 0 && height > 0 else 			{ return nil }
		guard pixels.count == width * height else 	{ return nil }
		
		let size = MemoryLayout<PixelData>.size
		
		var data = pixels 							// Copy to mutable []
		guard let provider = CGDataProvider(data: NSData(bytes: &data, length: data.count * size) )
			else { return nil }
		
		guard let cgImage = CGImage(
			width: 				width,
			height: 			height,
			bitsPerComponent: 	8 * size / 4,
			bitsPerPixel: 		8 * size,
			bytesPerRow: 		width * size,
			space: 				CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: 		CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
			provider: 			provider,
			decode: 			nil,
			shouldInterpolate: 	true,
			intent: 			.defaultIntent
			)
			else { return nil }
		
		return cgImage
	}

}



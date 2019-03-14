//
//  histogramView.swift
//  Histogram
//
//  Created by Thomas Wolf on 12.03.19.
//  Copyright © 2019 Thomas Wolf. All rights reserved.
//

import UIKit

class HistogramView: UIView {

	var histData : [PixelData]?
	
    override func draw(_ rect: CGRect) {
		
		guard let hist = histData else { return }
	
		let count = hist.count
		
		let ctx = UIGraphicsGetCurrentContext()!
		ctx.saveGState()

		struct _xData { var i : Int; var x : CGFloat }
		
		// Index array
		let idx = Array(0..<count)
		
		let width  = self.bounds.width
		let height = self.bounds.height
		
		let xscale : CGFloat = width  / CGFloat(count-1)
		let yscale : CGFloat = height / 255
		
		// Array with index and x values
		let x = idx.map { _xData(i:$0, x: CGFloat($0) * xscale) }
		
		// Map arrays to [CPoint] and draw lines
		let redPoints = x.map { CGPoint(x: $0.x, y: CGFloat(height - CGFloat(hist[$0.i].r) * yscale) ) }
		ctx.addLines(between: redPoints)
		ctx.setStrokeColor(UIColor.red.cgColor)
		ctx.strokePath()

		let greenPoints = x.map { CGPoint(x: $0.x, y: CGFloat(height - CGFloat(hist[$0.i].g) * yscale) ) }
		ctx.addLines(between: greenPoints)
		ctx.setStrokeColor(UIColor.green.cgColor)
		ctx.strokePath()
		
		let bluePoints = x.map { CGPoint(x: $0.x, y: CGFloat(height - CGFloat(hist[$0.i].b) * yscale) ) }
		ctx.addLines(between: bluePoints)
		ctx.setStrokeColor(UIColor.blue.cgColor)
		ctx.strokePath()
		
		ctx.restoreGState()
    }
}

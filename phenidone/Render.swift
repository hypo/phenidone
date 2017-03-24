//
//  Render.swift
//  phenidone
//
//  Created by Yung-Luen Lan on 23/03/2017.
//  Copyright © 2017 Hypo. All rights reserved.
//

import Foundation
import Cocoa
import CoreGraphics

protocol DrawCommand {
    func render(ctx: CGContext)
}

struct SetFillColorCommand: DrawCommand {
    var color: CGColor
    
    func render(ctx: CGContext) {
        ctx.setFillColor(self.color)
    }
}

struct SetStrokeColorCommand: DrawCommand {
    var color: CGColor
    
    func render(ctx: CGContext) {
        ctx.setStrokeColor(self.color)
    }
}

struct FillRectCommand: DrawCommand {
    var rect: CGRect
    
    func render(ctx: CGContext) {
        ctx.fill(self.rect)
    }
}

struct StrokeRectCommand: DrawCommand {
    var rect: CGRect
    
    func render(ctx: CGContext) {
        ctx.stroke(self.rect)
    }
}

struct DrawPDFCommand: DrawCommand {
    var page: CGPDFPage
    
    func render(ctx: CGContext) {
        ctx.drawPDFPage(self.page)
    }
}

struct ClipCommand: DrawCommand {
    var bezierPath: NSBezierPath
    var content: DrawCommand
    
    func render(ctx: CGContext) {
        ctx.saveGState()
        for idx in 0..<self.bezierPath.elementCount {
            let points = NSPointArray.allocate(capacity: 3)
            let e = self.bezierPath.element(at: idx, associatedPoints: points)
            switch e {
            case .closePathBezierPathElement:
                ctx.closePath()
            case .curveToBezierPathElement:
                ctx.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .lineToBezierPathElement:
                ctx.addLine(to: points[0])
            case .moveToBezierPathElement:
                ctx.move(to: points[0])
            }
            points.deallocate(capacity: 3)
        }
        ctx.clip()
        content.render(ctx: ctx)
        ctx.restoreGState()
    }
}

struct ScaleCommand: DrawCommand {
    var x: CGFloat
    var y: CGFloat
    
    func render(ctx: CGContext) {
        ctx.scaleBy(x: self.x, y: self.y)
    }
}

struct TranslateCommand: DrawCommand {
    var x: CGFloat
    var y: CGFloat
    
    func render(ctx: CGContext) {
        ctx.translateBy(x: self.x, y: self.y)
    }
}

struct RotateCommand: DrawCommand {
    var radian: CGFloat
    
    func render(ctx: CGContext) {
        ctx.rotate(by: self.radian)
    }
}

struct DrawCommandGroup: DrawCommand {
    var commands: [DrawCommand] = []
    
    func render(ctx: CGContext) {
        for cmd in commands {
            cmd.render(ctx: ctx)
        }
    }
}

struct PageCommand: DrawCommand {
    var mediaBox: CGRect
    var content: DrawCommandGroup
    
    init(size: CGSize, content: [DrawCommand] = []) {
        self.mediaBox = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.content = DrawCommandGroup(commands: content)
    }
    
    func render(ctx: CGContext) {
        var box = self.mediaBox
        ctx.beginPage(mediaBox: &box)
        self.content.render(ctx: ctx)
        ctx.endPage()
    }
}

struct TextCommand: DrawCommand {
    var rect: CGRect
    var text: String
    
    func render(ctx: CGContext) {
        ctx.saveGState()
        let cocoagc = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(cocoagc)
        (text as NSString).draw(in: self.rect, withAttributes: nil)
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }
}

// MARK: - High Level

enum ContentMode {
    case AspectFit
    case AspectFill
    case ScaleToFill
}

struct DrawPDFIntoRect: DrawCommand {
    var page: DrawPDFCommand
    var rect: CGRect
    var mode: ContentMode
    
    init(page: CGPDFPage, rect: CGRect, mode: ContentMode = .ScaleToFill) {
        self.page = DrawPDFCommand(page: page)
        self.rect = rect
        self.mode = mode
    }
    
    func render(ctx: CGContext) {
        if self.rect.width == 0 || self.rect.height == 0 {
            return
        }
        ctx.saveGState()
        
        let ctm: CGAffineTransform

        switch self.mode {
            case .ScaleToFill:
                ctm = page.page.getDrawingTransform(CGPDFBox.mediaBox, rect: rect, rotate: 0, preserveAspectRatio: false)
            case .AspectFit:
                ctm = page.page.getDrawingTransform(CGPDFBox.mediaBox, rect: rect, rotate: 0, preserveAspectRatio: true)
            case .AspectFill:
                let pageSize = page.page.getBoxRect(.mediaBox).size
                let scaleX = self.rect.width / pageSize.width
                let scaleY = self.rect.height / pageSize.height
                let scale = max(scaleX, scaleY)
                let newSize = CGSize(width: pageSize.width * scale, height: pageSize.height)
                let newRect = CGRect(origin: CGPoint(x: self.rect.midX - newSize.width / 2, y: self.rect.midY - newSize.height / 2), size: newSize)
                ctm = page.page.getDrawingTransform(CGPDFBox.mediaBox, rect: newRect, rotate: 0, preserveAspectRatio: true)
        }
        
        ctx.concatenate(ctm)
        self.page.render(ctx: ctx)
        ctx.restoreGState()
    }
}

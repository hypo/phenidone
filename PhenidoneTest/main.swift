//
//  main.swift
//  PhenidoneTest
//
//  Created by Yung-Luen Lan on 23/03/2017.
//  Copyright © 2017 Hypo. All rights reserved.
//

import Foundation
import Cocoa

print("Begin Test")

let url = URL(fileURLWithPath: "/tmp/test.pdf")


func testRender(url: URL, pages: [PageCommand]) {
    let ctx = CGContext(url as CFURL, mediaBox: nil, nil)
    for p in pages {
        p.render(ctx: ctx!)
    }
    ctx?.closePDF()
    
    NSWorkspace().open(url)
}

// test multiple pages

testRender(url: URL(fileURLWithPath: "/tmp/multipage.pdf"),
           pages: [PageCommand(size: CGSize(width:10.cm, height:5.cm)),
                   PageCommand(size: CGSize(width:10.cm, height:10.cm)),
                   PageCommand(size: CGSize(width:10.cm, height:15.cm))])

testRender(url: URL(fileURLWithPath: "/tmp/dutch.pdf"),
           pages: [PageCommand(size: CGSize(width:20.cm, height:15.cm),
                           content: [SetFillColorCommand(color: NSColor.red.cgColor),
                                     FillRectCommand(rect: CGRect(x: 0.cm, y: 10.cm, width: 20.cm, height: 5.cm)),
                                     SetFillColorCommand(color: NSColor.blue.cgColor),
                                     FillRectCommand(rect: CGRect(x: 0.cm, y: 0.cm, width: 20.cm, height: 5.cm))
                                      ])])

testRender(url: URL(fileURLWithPath: "/tmp/group.pdf"),
           pages: [PageCommand(size: CGSize(width:10.cm, height:10.cm),
                           content: [DrawCommandGroup(commands: [
                            FillRectCommand(rect: CGRect(x: 1.cm, y: 1.cm, width: 3.cm, height: 4.cm)),
                            SetFillColorCommand(color: NSColor.red.cgColor),
                            FillRectCommand(rect: CGRect(x: 5.cm, y: 6.cm, width: 4.cm, height: 3.cm))
                            ])])])

let dutch: CGPDFDocument = CGPDFDocument(URL(fileURLWithPath: "/tmp/dutch.pdf") as CFURL)!
let p: CGPDFPage = dutch.page(at: 1)!

testRender(url: URL(fileURLWithPath: "/tmp/draw_pdf.pdf"),
           pages: [PageCommand(size: CGSize(width:30.cm, height:30.cm),
                               content: [
                                TranslateCommand(x: CGFloat(2.cm), y: CGFloat(3.cm)),
                                ScaleCommand(x: 0.5, y: 0.5),
                                DrawPDFCommand(page: p)
                    ])])

let r1 = CGRect(x: 1.cm, y: 11.cm, width: 8.cm, height: 8.cm)
let r2 = CGRect(x: 11.cm, y: 11.cm, width: 8.cm, height: 8.cm)
let r3 = CGRect(x: 21.cm, y: 11.cm, width: 8.cm, height: 8.cm)

testRender(url: URL(fileURLWithPath: "/tmp/draw_pdf_mode.pdf"),
           pages: [PageCommand(size: CGSize(width:30.cm, height:30.cm),
                               content: [
                                DrawPDFIntoRect(page: p, rect: r1, mode: .AspectFill),
                                StrokeRectCommand(rect: r1),
                                DrawPDFIntoRect(page: p, rect: r2, mode: .AspectFit),
                                StrokeRectCommand(rect: r2),
                                DrawPDFIntoRect(page: p, rect: r3, mode: .ScaleToFill),
                                StrokeRectCommand(rect: r3)
            ])])


testRender(url: URL(fileURLWithPath: "/tmp/clip_pdf_mode.pdf"),
           pages: [PageCommand(size: CGSize(width:30.cm, height:30.cm),
                               content: [
                                TextCommand(rect: CGRect(x: 1.cm, y: 20.cm, width: 10.cm, height: 2.cm), text: "left"),
                                ClipCommand(bezierPath: NSBezierPath(ovalIn: r1), content: DrawPDFIntoRect(page: p, rect: r1)),
                                TextCommand(rect: CGRect(x: 11.cm, y: 20.cm, width: 10.cm, height: 2.cm), text: "right"),
                                ClipCommand(bezierPath: NSBezierPath(roundedRect: r2, xRadius: CGFloat(2.cm), yRadius: CGFloat(2.cm)), content: DrawPDFIntoRect(page: p, rect: r2))
            ])])

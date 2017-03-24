//
//  AppDelegate.swift
//  JetPack
//
//  Created by Yung-Luen Lan on 24/03/2017.
//  Copyright © 2017 Hypo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


    @IBAction func pack(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = ["pdf"]
        panel.begin { (result) in
            if result == NSFileHandlingPanelOKButton {
                
                let url = URL(fileURLWithPath: "/tmp/packed.pdf")
                let ctx = CGContext(url as CFURL, mediaBox: nil, nil)
                for p in self.pack(pdfURLs: panel.urls) {
                    p.render(ctx: ctx!)
                }
                ctx?.closePDF()
                
                NSWorkspace().open(url)
                
            }
        }
    }
    
    func pack(pdfURLs: [URL]) -> [PageCommand] {

        let imageSize = CGSize(width: 6.0.cm, height: 6.0.cm)
        let imageSlots: [CGRect] = [
            CGRect(origin: CGPoint(x:  3.0.cm, y: 18.0.cm), size: imageSize),
            CGRect(origin: CGPoint(x: 10.0.cm, y: 18.0.cm), size: imageSize),
            CGRect(origin: CGPoint(x:  3.0.cm, y: 10.0.cm), size: imageSize),
            CGRect(origin: CGPoint(x: 10.0.cm, y: 10.0.cm), size: imageSize),
            CGRect(origin: CGPoint(x:  3.0.cm, y: 2.0.cm), size: imageSize),
            CGRect(origin: CGPoint(x: 10.0.cm, y: 2.0.cm), size: imageSize)
        ]
        let textSize = CGSize(width: 6.0.cm, height: 0.6.cm)
        let textSlots: [CGRect] = [
            CGRect(origin: CGPoint(x:  3.0.cm, y: 18.0.cm + Double(imageSize.height)), size: textSize),
            CGRect(origin: CGPoint(x: 10.0.cm, y: 18.0.cm + Double(imageSize.height)), size: textSize),
            CGRect(origin: CGPoint(x:  3.0.cm, y: 10.0.cm + Double(imageSize.height)), size: textSize),
            CGRect(origin: CGPoint(x: 10.0.cm, y: 10.0.cm + Double(imageSize.height)), size: textSize),
            CGRect(origin: CGPoint(x:  3.0.cm, y: 2.0.cm + Double(imageSize.height)), size: textSize),
            CGRect(origin: CGPoint(x: 10.0.cm, y: 2.0.cm + Double(imageSize.height)), size: textSize)
        ]
        let batchSize = imageSlots.count
        let totalPages = Int(ceil(Double(pdfURLs.count) / Double(batchSize)))

        let pageSize = CGSize(width: 21.0.cm, height: 29.7.cm)
        var results: [PageCommand] = []
        
        for p in 0..<totalPages {
            var contents: [DrawCommand] = []
            
            for idx in p * batchSize..<min(pdfURLs.count, (p + 1) * batchSize) {
                
                let n = idx - p * batchSize
                let imageSlot = imageSlots[n]
                let textSlot = textSlots[n]
                
                let url = pdfURLs[idx]
                let filename = url.lastPathComponent
                
                let pdfDocument = CGPDFDocument(url as CFURL)!
                let page = pdfDocument.page(at: 1)!
                
                contents.append(TextCommand(rect: textSlot, text: filename))
                contents.append(ClipCommand(bezierPath: NSBezierPath(roundedRect: imageSlot, xRadius: CGFloat(0.5.cm), yRadius: CGFloat(0.5.cm)), content:
                    DrawPDFIntoRect(page: page, rect: imageSlot)
                ))
                
            }
            results.append(PageCommand(size: pageSize, content: contents))
        }
        return results
    }
}


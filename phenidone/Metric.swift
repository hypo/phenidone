//
//  Metric.swift
//  phenidone
//
//  Created by Yung-Luen Lan on 23/03/2017.
//  Copyright © 2017 Hypo. All rights reserved.
//

import Foundation

extension Double {
    var pt: Double { return self }
    var cm: Double { return self * 72.0 / 2.54 }
    var mm: Double { return self * 720.0 / 2.54 }
    var inch: Double { return self * 72.0 }
}

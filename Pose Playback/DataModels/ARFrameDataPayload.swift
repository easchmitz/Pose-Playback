//
//  ARFrameDataPayload.swift
//  ROSE
//
//  Created by Eric Schmitz on 2/22/21.
//

import Foundation

struct ARFrameDataPayload: Codable {
    var ts: String
    var jointData: [[Float]]
    var anchor: [Float]
    var camera: [Float]
}


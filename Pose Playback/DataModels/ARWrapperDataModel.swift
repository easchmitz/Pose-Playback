//
//  ARWrapperDataModel.swift
//  Pose Playback
//
//  Created by Eric Schmitz on 4/3/21.
//

import Foundation

struct ARWrapperDataModel : Codable {
    var hasVideo: Bool
    var dataSource: String
    var type: String
    var user: String
    var data: ARJointPositionDataModel
}

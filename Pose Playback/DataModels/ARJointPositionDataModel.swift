//
//  ARJointPositionDataModel.swift
//  ROSE
//
//  Created by Eric Schmitz on 2/22/21.
//

import Foundation

struct ARJointPositionDataModel: Codable {
    var uuid: String
    var testTime: String
    var testType: String
    var userIdentifier: String
    var testScore: String
    var mqi: Decimal?
    var mqiTime: Decimal?
    var mqiWeight: Decimal?
    var mqiLegLength: Decimal?
    var mqiChairHeight: Decimal?
    var meta: ARMetaData
    var frames: [ARFrameDataPayload]
}

//
//  ViewController.swift
//  Pose Playback
//
//  Created by Eric Schmitz on 4/2/21.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    
    // The 3D character to display.
    private var robot: SCNNode!
    // hmmm
    private var dummyNode: SCNNode!
    private var refNode: SCNNode!
    
    // main view of this controller
    @IBOutlet var scnView: SCNView!
    
    private var dataModel: ARJointPositionDataModel?

    private var currentFrame: Int = 0
    
    private var frameCount: Int = 0
    
    private var isEvenFrame: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // load the data
        dataModel = loadData()
        
        scnView.delegate = self
    
        setupScene()
    }
    
    private func setupScene() {
        
        let scene = SCNScene(named: "art.scnassets/main.scn")!
        
        robot = usdzNodeFromFile("robot", exten: "usdz", internalNode: "biped_robot_ace")!
        robot.position = SCNVector3(0,0,0)
        scene.rootNode.addChildNode(robot)
        
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode
        
        // These nodes are used to position the joints.
        // Using the data we collected during sit-to-stand
        // we position the dummyNode to the anchor point,
        // then set the relative position of the refNode to the individual joint.
        // We then take the world transform of the ref node to set the robot's individual joints
        dummyNode = SCNNode()
        refNode = SCNNode()
        dummyNode.addChildNode(refNode)
        scene.rootNode.addChildNode(dummyNode)
        
        // scene view setup
        scnView.preferredFramesPerSecond = 20
        scnView.rendersContinuously = true
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        //scnView.debugOptions = [.showSkeletons]
        scnView.autoenablesDefaultLighting = true
        
        scnView.scene = scene

    }
    
    /// Creates a SCNNode with a USDZ model
    private func usdzNodeFromFile(_ file: String, exten: String, internalNode: String) -> SCNNode? {
        let rootNode = SCNNode()
        let scale = 1.0
        
        guard let fileUrl = Bundle.main.url(forResource: file, withExtension: exten) else { fatalError() }
        let scene = try! SCNScene(url: fileUrl, options: [.checkConsistency: true])
        let node = scene.rootNode.childNode(withName: internalNode, recursively: true)!
        node.name = internalNode
        node.position = SCNVector3(0, 0, 0)
        node.scale = SCNVector3(scale, scale, scale)
        rootNode.addChildNode(node)
        
        return rootNode
    }
    
    /// Loads the saved JSON data into our data model
    private func loadData() -> ARJointPositionDataModel? {
        let decoder = JSONDecoder()
        guard
            let url = Bundle.main.url(forResource: "schmitze", withExtension: "json"),
            let json = try? Data(contentsOf: url),
            let data = try? decoder.decode([ARWrapperDataModel].self, from: json)
        else {
            return nil
        }
        let retval = data[0].data
        frameCount = retval.frames.count
        return retval
    }
    
    /// Applies the transforms from the data to the robot
    private func applyTransforms() {
        
        guard
            let frame = dataModel?.frames[currentFrame].jointData,
            let anchor = dataModel?.frames[currentFrame].anchor,
            let camera = dataModel?.frames[currentFrame].camera
        else {
            print("some data is nil")
            return
        }
        
        // The position of the ARBodyAnchor root joint in space
        let anchorWorldMatrix = scnMatrixFromValues(anchor)
    
        // apply the anchor transform to the robot
        robot.setWorldTransform(anchorWorldMatrix)
        // also move the dummyNode and refNode child to the anchor
        dummyNode.setWorldTransform(anchorWorldMatrix)
        
        // look at each child node in the robot searching the node names for matches on our dictionary
        robot.enumerateChildNodes { (node, stop) in
            //print(node.name ?? "??")
            // check to see if the current node name is a joint we track
            if let jointIndex = dataModel!.meta.jointNames.firstIndex(of: node.name!) {
                // values for this node exist, get the values array and convert to matrix
                let m = matrixFromValues(frame[jointIndex])
                // move our refNode according to the transform
                // simdTransform: The transform applied to the node relative to its parent
                // Here the refNode has only one parent, and the parent is at the root
                refNode.simdTransform = m
                // take the world transform of our refNode as the transform of the corresponding robot joint
                node.setWorldTransform(refNode.worldTransform)
            }
            
        }
    }
    
    /// Converts the array of floats to a SCNMatrix4 matrix
    private func scnMatrixFromValues(_ v: [Float]) -> SCNMatrix4 {
        let m = matrixFromValues(v)
        let matrix = SCNMatrix4(m)
        return matrix
    }
    
    /// Converts the array of floats to a simd_float4x4 matrix
    private func matrixFromValues(_ v: [Float]) -> simd_float4x4 {
        let c0 = SIMD4(v[0], v[1], v[2], v[3])
        let c1 = SIMD4(v[4], v[5], v[6], v[7])
        let c2 = SIMD4(v[8], v[9], v[10], v[11])
        let c3 = SIMD4(v[12], v[13], v[14], v[15])
        let matrix = simd_float4x4([c0, c1, c2, c3])
        return matrix
    }
}

extension ViewController : SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        isEvenFrame = !isEvenFrame
        
        if isEvenFrame {
            applyTransforms()
            currentFrame += 1
            if(currentFrame >= frameCount) { currentFrame = 0 }
        }
        
    }
    
}

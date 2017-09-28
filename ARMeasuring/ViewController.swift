//
//  ViewController.swift
//  ARMeasuring
//
//  Created by Ivan Ken Tiu on 28/09/2017.
//  Copyright © 2017 FinalShift Inc. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var zLabel: UILabel!
    var startingPosition: SCNNode?
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.delegate = self
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        guard let currentFrame = sceneView.session.currentFrame else { return }
        // stop measuring at a spot (tapped) guard statestatement fail in renderer(stops measuring)
        if self.startingPosition != nil {
            self.startingPosition?.removeFromParentNode()
            self.startingPosition = nil
            return
        }
        let camera = currentFrame.camera
        // 4 by 4 matrix (exact position of our phone)
        let transform = camera.transform
        // need to be modified since default is 1
        var translationMatrix = matrix_identity_float4x4
        // access 3rd column of matrix
        translationMatrix.columns.3.z = -0.1
        // multiply 2 matrices (Linear Algebra) only modified the z
        let modifiedMatrix = simd_mul(transform, translationMatrix)
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.005))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        // access transform matrix of the sphere ( 4 by 4 matrix ) Node position where the phone is!
        sphere.simdTransform = modifiedMatrix
        self.sceneView.scene.rootNode.addChildNode(sphere)
        self.startingPosition = sphere
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // also called once per frame (normal updates, no physics etc)
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // only run if tapped and added starting position
        guard let startingPosition = self.startingPosition else { return }
        guard let pointOfView = sceneView.pointOfView else { return }
       
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let xDistance = location.x - startingPosition.position.x
        let yDistance = location.y - startingPosition.position.y
        let zDistance = location.z - startingPosition.position.z
        // not showing? make sure main thread not background
        DispatchQueue.main.async {
            self.xLabel.text = String(format: "%.2f", xDistance) + "m"
            self.yLabel.text = String(format: "%.2f", yDistance) + "m"
            self.zLabel.text = String(format: "%.2f", zDistance) + "m"
            self.distance.text = String(format: "%.2f", self.distanceTravelled(x: xDistance, y: yDistance, z: zDistance)
        ) + "m"
        }
    }
    
    // get diagonal distance travelled (walk forward) Pythogorian Theorem
    func distanceTravelled(x: Float, y: Float, z: Float) -> Float {
        return (sqrtf(x*x + y*y + z*z))
    }


}


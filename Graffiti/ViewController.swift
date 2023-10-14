//
//  ViewController.swift
//  Graffiti
//
//  Created by Azhan on 10/13/23.
//

import UIKit
import SceneKit
import ARKit
import Firebase
import FirebaseAnalytics
import FirebaseStorage

extension SCNGeometry {
    static func line(from start: SCNVector3, to end: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [start, end])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var currentLineNode: SCNNode?
    var currentLinePoints: [SCNVector3] = []
    var selectedColor: UIColor = .black
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        configuration.planeDetection = .vertical

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    
    @IBAction func colorButtonTapped(_ sender: UIButton) {
        guard let buttonColor = sender.backgroundColor else { return }
        selectedColor = buttonColor
    }

    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)  // semi-transparent white to represent whiteboard
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }


    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLinePoints.removeAll()  // Start a new line
    }


    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        let raycastQuery = sceneView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .vertical)
        if let query = raycastQuery {
            let results = sceneView.session.raycast(query)
            if let firstResult = results.first {
                let worldPosition = SCNVector3(firstResult.worldTransform.columns.3.x, firstResult.worldTransform.columns.3.y, firstResult.worldTransform.columns.3.z)
                currentLinePoints.append(worldPosition)
                updateLine()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLineNode = nil  // End the current line
    }
    
    func updateLine() {
        guard currentLinePoints.count >= 2 else { return }  // Need at least two points to create a line
        
        if currentLineNode == nil {
            let line = SCNGeometry.line(from: currentLinePoints[0], to: currentLinePoints[1])
            currentLineNode = SCNNode(geometry: line)
            sceneView.scene.rootNode.addChildNode(currentLineNode!)
        } else {
            let newLine = SCNGeometry.line(from: currentLinePoints[currentLinePoints.count - 2], to: currentLinePoints.last!)
            let newNode = SCNNode(geometry: newLine)
            currentLineNode!.addChildNode(newNode)
        }
    }

    
    
    func addDrawing(at raycastResult: ARRaycastResult) {
        let sphere = SCNSphere(radius: 0.005)  // small sphere to represent a drawing point
        sphere.materials.first?.diffuse.contents = selectedColor  // use selectedColor here
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(raycastResult.worldTransform.columns.3.x, raycastResult.worldTransform.columns.3.y, raycastResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }


    
    
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

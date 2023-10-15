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
    static func line(from start: SCNVector3, to end: SCNVector3, color: UIColor) -> SCNGeometry {
          let indices: [Int32] = [0, 1]
          let source = SCNGeometrySource(vertices: [start, end])
          let element = SCNGeometryElement(indices: indices, primitiveType: .line)
          let geometry = SCNGeometry(sources: [source], elements: [element])
          
          let material = SCNMaterial()
          material.diffuse.contents = color
          geometry.materials = [material]
          
          return geometry
      }
}

extension SCNVector3 {
    func distance(to point: SCNVector3) -> CGFloat {
        return CGFloat(sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2) + pow(self.z - point.z, 2)))
    }
}


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var currentLineNode: SCNNode?
    var currentLinePoints: [SCNVector3] = []
    var selectedColor: UIColor = .black
    var displayContentTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseDatabaseManager.initializeCounter() { [weak self] in
            guard let self = self else { return }

            print(FirebaseDatabaseManager.counter)

            for i in 0...Int(FirebaseDatabaseManager.counter) {
                var string_num = String(i)
                let path = FirebaseDatabaseManager.user + "/" + string_num
                FirebaseDatabaseManager.downloadData(from: path) { (data) in
                    if let downloadedData = data,
                       let node = FirebaseDatabaseManager.unarchiveNode(from: downloadedData) {
                        self.sceneView.scene.rootNode.addChildNode(node)
                    }
                }
            }
            
            FirebaseDatabaseManager.listAllFiles(sceneView: self.sceneView)

            FirebaseDatabaseManager.counter += 1
                
            scheduleDisplayContentTimer()
            // Set the view's delegate
            self.sceneView.delegate = self
            
            // Show statistics such as fps and timing information
            self.sceneView.showsStatistics = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        configuration.planeDetection = .vertical

        sceneView.session.run(configuration)
    }
    
    func scheduleDisplayContentTimer() {
        displayContentTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(displayContent), userInfo: nil, repeats: true)
    }

    // This function will be called every 10 seconds
    @objc func displayContent() {
        print("Here now")
        
        let path = "\(FirebaseDatabaseManager.user)/\(FirebaseDatabaseManager.otherUserCounter)"
        FirebaseDatabaseManager.downloadData(from: path) { data in
            DispatchQueue.main.async {
                if let node = data as? Data {
                    let newnode = FirebaseDatabaseManager.unarchiveNode(from: node)
                    self.sceneView.scene.rootNode.addChildNode(newnode!)
                    FirebaseDatabaseManager.otherUserCounter += 1
                    self.displayContent() // Recursively call the function to fetch the next data
                } else {
                    // Stop the recursive calls when an error is encountered
                    print("Error encountered. Stopping data fetch.")
                }
            }
        }
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
           print("Selected color changed to: \(selectedColor)")
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
        print("ENDDDDDDD")
        if let unwrappedNode = currentLineNode {
            FirebaseDatabaseManager.uploadNode(unwrappedNode)
            FirebaseDatabaseManager.pushDataToDatabase(data: ["latest_pushed" : FirebaseDatabaseManager.counter], path: FirebaseDatabaseManager.user)
        } else {
            // Handle the case where currentLineNode is nil.
            print("currentLineNode is nil")
        }
        print(FirebaseDatabaseManager.counter)
        currentLineNode = nil  // End the current line
    }
    
    func updateLine() {
        guard currentLinePoints.count >= 2 else { return }
            if currentLineNode == nil {
                print("QQQQQQ")
                let line = SCNGeometry.line(from: currentLinePoints[0], to: currentLinePoints[1], color: selectedColor)
                currentLineNode = SCNNode(geometry: line)
                sceneView.scene.rootNode.addChildNode(currentLineNode!)
            } else {
                let newLine = SCNGeometry.line(from: currentLinePoints[currentLinePoints.count - 2], to: currentLinePoints.last!, color: selectedColor)
                let newNode = SCNNode(geometry: newLine)
                currentLineNode!.addChildNode(newNode)
            }
        let startPoint = currentLinePoints[currentLinePoints.count - 2]
        let endPoint = currentLinePoints.last!
        addTube(from: startPoint, to: endPoint, radius: 0.005, color: selectedColor)  // Adjust the radius as needed
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

    func tube(from start: SCNVector3, to end: SCNVector3, radius: CGFloat, color: UIColor) -> SCNGeometry {
        let height = start.distance(to: end)
        let cylinder = SCNCylinder(radius: radius, height: height)
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        cylinder.materials = [material]

        return cylinder
    }

    func addTube(from start: SCNVector3, to end: SCNVector3, radius: CGFloat, color: UIColor) {
        let tubeGeometry = tube(from: start, to: end, radius: radius, color: color)
        let tubeNode = SCNNode(geometry: tubeGeometry)

        tubeNode.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)
        tubeNode.look(at: end, up: sceneView.scene.rootNode.worldUp, localFront: tubeNode.worldUp)
        
        sceneView.scene.rootNode.addChildNode(tubeNode)
        FirebaseDatabaseManager.uploadNode(tubeNode)
        FirebaseDatabaseManager.counter += 1
        FirebaseDatabaseManager.pushDataToDatabase(data: ["latest_pushed" : FirebaseDatabaseManager.counter], path: FirebaseDatabaseManager.user)
    }

}

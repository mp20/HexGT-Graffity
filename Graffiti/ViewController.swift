//
//  ViewController.swift
//  Graffiti
//
//  Created by Azhan on 10/13/23.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var sprayNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @IBAction func colorButtonTapped(_ sender: UIButton) {
        guard let buttonColor = sender.backgroundColor else { return }
        
        if let sprayParticles = SCNParticleSystem(named: "SprayParticles.scnp", inDirectory: nil) {
            sprayParticles.particleColor = buttonColor
            sprayNode?.removeAllParticleSystems()
            sprayNode?.addParticleSystem(sprayParticles)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        let results = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let query = results {
            let hitResults = sceneView.session.raycast(query)
            if let hitResult = hitResults.first {
                let worldPosition = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
                createSprayNode(at: worldPosition)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        let results = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let query = results {
            let hitResults = sceneView.session.raycast(query)
            if let hitResult = hitResults.first {
                let worldPosition = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
                moveSprayNode(to: worldPosition)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopSpraying()
    }
    
    func createSprayNode(at position: SCNVector3) {
        if let sprayParticles = SCNParticleSystem(named: "SprayParticles.scnp", inDirectory: nil) {
            print("Particle system created")
            sprayNode = SCNNode()
            sprayNode?.position = position
            sprayNode?.addParticleSystem(sprayParticles)
            sceneView.scene.rootNode.addChildNode(sprayNode!)
            print("Spray node added to scene")
        } else {
            print("Failed to print")
        }
    }
    
    func moveSprayNode(to position: SCNVector3) {
        sprayNode?.position = position
    }
    
    func stopSpraying() {
        sprayNode?.removeAllParticleSystems()
        sprayNode = nil
    }
}

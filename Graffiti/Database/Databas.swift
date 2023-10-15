//
//  Databas.swift
//  Graffiti
//
//  Created by Ariya nazari on 10/14/23.
//

//  FirebaseDatabaseManager.swift

import Foundation
import FirebaseDatabase
import UIKit
import SceneKit
import ARKit
import Firebase
import FirebaseAnalytics
import FirebaseStorage

class FirebaseDatabaseManager {
    
    private let database = Database.database().reference()
    private let storage = Storage.storage().reference()
    
    static var user = "Azhan"
    static var other_user = "Ariya"
    static var counter = 0
    static var otherUserCounter = 0
    
    static func initializeCounter(completion: @escaping () -> Void) {
        FirebaseDatabaseManager.pullDataFromDatabase(path: user) { (data) in
            if let dictionary = data, let counterValue = dictionary["latest_pushed"] as? Int {
                print("COUNTER:" + String(counterValue))
                counter = counterValue
                completion()
            }
        }
    }
    
    static func archiveNode(_ node: SCNNode) -> Data? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: node, requiringSecureCoding: true)
            return data
        } catch {
            print("Error archiving SCNNode: \(error)")
            return nil
        }
    }
    
    static func unarchiveNode(from data: Data) -> SCNNode? {
        do {
            if let node = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: data) {
                return node
            } else {
                print("Unarchiving resulted in a nil SCNNode.")
                return nil
            }
        } catch {
            print("Error unarchiving SCNNode: \(error)")
            return nil
        }
    }
    
    static func uploadNode(_ node: SCNNode) {
        guard let data = archiveNode(node) else { return }

        // Create a reference to the file you want to upload
        var path = user + "/" + String(counter)
        let nodeRef = Storage.storage().reference().child(path)

        // Upload the file
        let uploadTask = nodeRef.putData(data, metadata: nil) { (metadata, error) in
            guard let _ = metadata else {
                // Uh-oh, an error occurred!
                print("Error uploading node: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            counter += 1;
            // Metadata contains file metadata such as size, content-type, and download URL.
            // You might want to store the download URL in Firebase Database for easier retrieval.
        }
    }
    static func downloadData(from path: String, completion: @escaping (Data?) -> Void) {
        let storageRef = Storage.storage().reference().child(path)

        // Download in memory with a maximum allowed size of 1MB (you might need to adjust this)
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                // Handle any errors
                print("Error downloading data: \(error)")
                completion(nil)
            } else {
                // Data for "path" is returned
                completion(data)
            }
        }
    }
    static func pushDataToDatabase(data: [String: Any], path: String) {
        let reference = Database.database().reference().child(path)
        reference.setValue(data) { (error, _) in
            if let error = error {
                print("Failed to push data: \(error.localizedDescription)")
            } else {
                print("Data successfully pushed to Firebase Realtime Database.")
            }
        }
    }
        
    static func pullDataFromDatabase(path: String, completion: @escaping ([String: Any]?) -> Void) {
        let reference = Database.database().reference().child(path)
        reference.observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                print("Failed to pull data.")
                completion(nil)
                return
            }
            completion(dictionary)
        }
    }
    
    static func listAllFiles(sceneView: ARSCNView!) {
        // Create a reference to the folder
        let storageRef = Storage.storage().reference().child(other_user)

        // List all files in the folder
        storageRef.listAll { (result, error) in
            if let error = error {
                print("Error listing files: \(error)")
                return
            }

            // Safely unwrap the result
            guard let unwrappedResult = result else {
                print("No result found.")
                return
            }

            for item in unwrappedResult.items {
                let filePath = "\(other_user)/\(item.name)"
                FirebaseDatabaseManager.downloadData(from: filePath) { (data) in
                    if let downloadedData = data,
                       let node = FirebaseDatabaseManager.unarchiveNode(from: downloadedData) {
                        otherUserCounter+=1
                        sceneView.scene.rootNode.addChildNode(node)
                }
            }
        }
    }
    }
    
}



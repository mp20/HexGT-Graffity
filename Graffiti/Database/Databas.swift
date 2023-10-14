//
//  Databas.swift
//  Graffiti
//
//  Created by Ariya nazari on 10/14/23.
//

//  FirebaseDatabaseManager.swift

import Foundation
import FirebaseDatabase

class FirebaseDatabaseManager {
    
    private let database = Database.database().reference()
    
    // Singleton instance
    static let shared = FirebaseDatabaseManager()
    
    // Prevent direct initialization
    private init() {}
    
    
    func observeData(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
            database.child(path).observe(.value, with: { (snapshot) in
                // Check if the snapshot has value
                guard snapshot.exists() else {
                    completion(.failure(NSError(domain: "com.yourAppDomain.errorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data at given path"])))
                    return
                }
                // If snapshot has value, return the data
                if let data = snapshot.value {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "com.yourAppDomain.errorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Data could not be serialized"])))
                }
            }) { (error) in
                completion(.failure(error))
            }
        }
    
    
    func writeData(path: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        database.child(path).setValue(data) { error, _ in
            completion(error)
        }
    }
    
    func readData(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child(path).observeSingleEvent(of: .value, with: { (snapshot) in
            // Check if the snapshot has value, and if not, return an error
            guard snapshot.exists() else {
                completion(.failure(NSError(domain: "com.yourAppDomain.errorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data at given path"])))
                return
            }
            // If snapshot has value, return the data
            if let data = snapshot.value {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "com.yourAppDomain.errorDomain", code: -2, userInfo: [NSLocalizedDescriptionKey: "Data could not be serialized"])))
            }
        }) { (error) in
            // This block is called if there's an error with the Firebase call
            completion(.failure(error))
        }
    }
}



//
//  PersistenceController.swift
//  Shelly
//
// This file sets up and manages how the app stores persistent data locally
// Apple's object graph database framework
//
//  Created by Christopher Wallrauch on 7/21/25.
//

import CoreData

struct PersistenceController {
    // Creates the shared instance of the controller avaialble across all views
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    // Initializer for the container
    init(inMemory: Bool = false) {
        // Sets up the container and links it to the CoreData model
        container = NSPersistentContainer(name: "database")
        
        if inMemory {
            // Stores the data in memory if inMemory is true
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
            // Attempts to load the stored data, and crashes the app if it fails
            container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        // This automatically updates changes made and so it synces with the UI
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

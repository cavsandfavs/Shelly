//
//  CoreDataHelpers.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 8/1/26.
//

import SwiftUI
import CoreData

// Put all CoreData operations into 1 file for modularity
struct CoreDataHelpers {
    
    static func delete(task: AssignmentTask, context: NSManagedObjectContext) throws {
        context.delete(task)
        try context.save()
        }
    }

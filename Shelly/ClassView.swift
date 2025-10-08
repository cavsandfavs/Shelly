//
//  ClassView.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 8/5/25.
//

import SwiftUI

struct ClassView: View {
    let className: String
    
    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true)],
        animation: .default
    ) var tasksFetched: FetchedResults<AssignmentTask> // Stores a special type of collection, similar to arrays
    
    var body: some View {
        VStack {
            ForEach(tasksFetched) { task in
                if task.class_Name == className {
                    let pass = task.taskTitle
                    classViewFunction(tasknames: pass ?? "No Title")
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    func classViewFunction(tasknames: String) -> some View {
        VStack {
            Text(tasknames)
        }
    }
}

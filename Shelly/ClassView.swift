//
//  ClassView.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 8/5/25.
//

import SwiftUI

struct ClassView: View {
    let tappedName: String
    
    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true)],
        animation: .default
    ) var tasksFetched: FetchedResults<AssignmentTask> // Stores a special type of collection, similar to arrays
    
    var body: some View {
        VStack {
            ForEach(tasksFetched) { task in
                if task.class_Name == tappedName {
                    classViewFunction()
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    func classViewFunction() -> some View {
        VStack {
            Text(tappedName)
        }
    }
}

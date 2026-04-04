//
//  ClassView.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 8/5/25.
//

import SwiftUI

struct ClassView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appData: AppData
    let name: String
    // Filters the array to include just the tasks from the passed classname
    private var tasksForClass: [AssignmentTask] {
        tasksFetched.filter { $0.class_name == name }
    }
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    private var timeFormatter: DateFormatter {
        let formatter2 = DateFormatter()
        formatter2.dateStyle = .none
        formatter2.timeStyle = .short
        return formatter2
    }
    
    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true)],
        animation: .default
    ) var tasksFetched: FetchedResults<AssignmentTask> // Stores a special type of collection, similar to arrays
    
    @FetchRequest(
        entity: Classes.entity(),
        sortDescriptors: [],
        animation: .default
    ) var classesFetched: FetchedResults<Classes>
    // Maps the classes from their property to strings, the set removes duplicates, and the Array allows sorting
    private var classes: [String] {
        Array(Set(classesFetched.map { $0.name ?? "None" })).sorted()
    }
    
    var body: some View {
        List {
            VStack (alignment: .leading) {
                Text(name)
                    .font(.largeTitle .bold())
                    .foregroundStyle(.blue)
                    .padding()
                HStack {
                    Button("Delete Class") {
                        // Fix the nil situation!!!
                        let classToDelete = classesFetched.first(where: { $0.name == name })!
                        deleteClass(className: classToDelete)
                    }
                }
                
                ForEach(tasksForClass, id: \.objectID) { task in
                    HStack(spacing: 10) {
                        if task.class_name == name {
                            Text(task.taskTitle ?? "Untitled")
                            Text(dateFormatter.string(from: task.taskDate ?? Date()))
                            Text(timeFormatter.string(from: task.taskTime ?? Date()))
                            Text(task.class_name ?? "")
                            Button("Completed") {
                                delete(task: task)
                            }
                            .font(.caption)
                            .foregroundStyle(Color.green)
                        }
                    }
                }
            }
        }
    }
    
    private func delete(task: AssignmentTask) {
        viewContext.delete(task)
        appData.tasksDueToday.removeAll { $0.objectID == task.objectID }
        
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }
    
    private func deleteClass(className: Classes) {
        viewContext.delete(className)
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }
}

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
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading) {
                Text(name)
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                
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
    private func dailyGoalCount() {
        // Clear and rebuild the array whenever it is called to prevent duplicates
        appData.tasksDueToday = []
        for task in tasksFetched {
            let isToday = Calendar.current.isDate(task.taskDate ?? Date(), inSameDayAs: Date.now)
            if isToday && task != task.objectID {
                appData.tasksDueToday.append(task)
            }
        }
    }
}

//
//  ClassView.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 8/5/25.
//

import SwiftUI

// MARK: - ClassView

struct ClassView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appData: AppData
    let name: String
    @State var editedName: String = ""
    @State var showEditTaskPopover: Bool = false


    // Filters the array to include just the tasks from the passed classname
    private var tasksForClass: [AssignmentTask] {
        tasksFetched.filter { $0.class_name == name }
    }

    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true)],
        animation: .default
    ) var tasksFetched: FetchedResults<AssignmentTask>

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
                HStack {
                    Text(name)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.blue)

                    Spacer()

                    // Defines the options menu and the buttons inside
                    Menu {
                        Button("Delete Class", role: .destructive) {
                            guard let classToDelete = classesFetched.first(where: { $0.name == name }) else {
                                return
                            }
                            deleteClass(_class_: classToDelete)
                        }
                        Button("Edit Class") {
                            editedName = name
                            showEditTaskPopover.toggle()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    .popover(isPresented: $showEditTaskPopover) {
                        Text("Edit Name")
                        TextField("New Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .onSubmit {
                            editClass(newName: editedName)
                        }
                        HStack {
                            Button("Cancel") {
                                showEditTaskPopover = false
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Change") {
                                editClass(newName: editedName)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(editedName.isEmpty)
                        }
                    }
                }
                .padding()

                ForEach(tasksForClass, id: \.self) { task in
                    ClassTaskRowView(
                        task: task,
                        name: name,
                        onDelete: { delete(task: task) }
                    )
                }
            }
        }
    }

// MARK: - Subviews

private struct ClassTaskRowView: View {
    let task: AssignmentTask
    let name: String
    let onDelete: () -> Void

    @EnvironmentObject var appData: AppData

    var body: some View {
        HStack(spacing: 10) {
            if task.class_name == name {
                Text(task.taskTitle ?? "Untitled")
                Text(appData.dateFormatter.string(from: task.taskDate ?? Date()))
                Text(appData.timeFormatter.string(from: task.taskTime ?? Date()))
                Text(task.class_name ?? "")
                Button("Completed", action: onDelete)
                    .font(.caption)
                    .foregroundStyle(Color.green)
            }
        }
    }
}

// MARK: - Helpers

private extension ClassView {
    func delete(task: AssignmentTask) {
        viewContext.delete(task)
        appData.tasksDueToday.removeAll { $0.objectID == task.objectID }
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }
    
    func editClass(newName: String) {
        guard let classToEdit = classesFetched.first(where: { $0.name == name }) else { return }
        classToEdit.name = newName
        do {
            try viewContext.save()
        } catch {
            print("Save failed: \(error)")
        }
    }

    func deleteClass(_class_: Classes) {
        // Remove all the tasks with the deleted class
        for task in tasksFetched {
            if task.class_name == _class_.name {
                viewContext.delete(task)
                do {
                    try viewContext.save()
                } catch {
                    print("Error occured: \(error)")
                }
            }
        }
        // Delete the class
        viewContext.delete(_class_)
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }
}

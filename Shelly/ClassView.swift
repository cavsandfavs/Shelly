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
    @ObservedObject var clazz: Classes
    let onDeleteClass: () -> Void
    @State private var editedName: String = ""
    @State private var showEditTaskPopover: Bool = false
    private var tasksForClass: [AssignmentTask] {
        tasksFetched.filter { $0.clazz == clazz }
    }

    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true)],
        animation: .default
    ) var tasksFetched: FetchedResults<AssignmentTask>

    var body: some View {
        VStack {
            HStack {
                Text(clazz.name ?? "Untitled")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.blue)

                Spacer()

                Menu {
                    Button("Delete Class", role: .destructive) {
                        deleteClass()
                    }
                    Button("Edit Class") {
                        editedName = clazz.name ?? ""
                        showEditTaskPopover.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
                
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
            Divider()
            List {
                ForEach(tasksForClass, id: \.id) { task in
                    ClassTaskRowView(
                        task: task,
                        onDelete: { delete(task: task) }
                    )
                }
            }
        }
    }
}
// MARK: - Subviews

private struct ClassTaskRowView: View {
    let task: AssignmentTask
    let onDelete: () -> Void

    @EnvironmentObject var appData: AppData

    var body: some View {
        HStack(spacing: 10) {
            Text(task.taskTitle ?? "Untitled")
            Text(appData.dateFormatter.string(from: task.taskDate ?? Date()))
            Text(appData.timeFormatter.string(from: task.taskTime ?? Date()))
            Text(task.clazz?.name ?? "")
            Button(action: onDelete) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Helpers

private extension ClassView {
    func delete(task: AssignmentTask) {
        viewContext.delete(task)
        appData.tasksDueToday.removeAll { $0.id == task.id }
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }
    
    func editClass(newName: String) {
        clazz.name = newName
        do {
            try viewContext.save()
            showEditTaskPopover = false
        } catch {
            print("Save failed: \(error)")
        }
    }

    func deleteClass() {
        let deletedTaskIDs = tasksForClass.map(\.id)
        for task in tasksForClass {
            viewContext.delete(task)
        }
        appData.tasksDueToday.removeAll { deletedTaskIDs.contains($0.id) }
        viewContext.delete(clazz)
        
        do {
            try viewContext.save()
            onDeleteClass()
        } catch {
            print("Error occured: \(error)")
        }
    }
}

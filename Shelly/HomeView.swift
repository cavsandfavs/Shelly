//
//  HomeView.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 1/2/25.
//
import SwiftUI
import CoreData

// MARK: - HomeView

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appData: AppData
    
    @State private var newTaskTitle: String = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var selectedClassID: NSManagedObjectID? = nil
    @State private var selectedTaskClassID: NSManagedObjectID? = nil
    @State private var newClassName: String = ""
    @State private var showingClassPopover = false
    @State private var showingAddPopover = false
    
    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true),
            NSSortDescriptor(keyPath: \AssignmentTask.taskTime, ascending: true)
        ],
        animation: .default
    ) var tasksFetched: FetchedResults<AssignmentTask>
    
    @FetchRequest(
        entity: Classes.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Classes.name, ascending: true)],
        animation: .default
    ) var classesFetched: FetchedResults<Classes>
    
    private var selectedClass: Classes? {
        guard let selectedClassID else { return nil }
        return classesFetched.first { $0.objectID == selectedClassID }
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedClassID: $selectedClassID,
                newClassName: $newClassName,
                showingClassPopover: $showingClassPopover,
                classes: classesFetched,
                onAddClass: { addNewClass(name: newClassName) }
            )
        } detail: {
            ZStack(alignment: .topTrailing) {
                if let selectedClass {
                    ClassView(clazz: selectedClass) {
                        selectedClassID = nil
                    }
                } else {
                    AssignmentsDetailView(
                        tasksFetched: tasksFetched,
                        classes: classesFetched,
                        newTaskTitle: $newTaskTitle,
                        date: $date,
                        time: $time,
                        selectedTaskClassID: $selectedTaskClassID,
                        showingAddPopover: $showingAddPopover,
                        onDelete: { task in
                            viewContext.delete(task)
                            appData.tasksDueToday.removeAll { $0.objectID == task.objectID }
                            do {
                                try viewContext.save()
                            } catch {
                                print("Error occured: \(error)")
                            }
                        },
                        onAddTask: addTask,
                        onAppear: dailyGoalCount
                    )
                }
            }
        }
    }
}

// MARK: - Subviews

private struct SidebarView: View {
    @Binding var selectedClassID: NSManagedObjectID?
    @Binding var newClassName: String
    @Binding var showingClassPopover: Bool
    let classes: FetchedResults<Classes>
    let onAddClass: () -> Void
    
    var body: some View {
        Button(action: { selectedClassID = nil }) {
            Text("Home").font(.title)
                .foregroundStyle(Color.blue)
        }
        
        Text("My Classes").font(.title)
        List(selection: $selectedClassID) {
            ForEach(classes, id: \.objectID) { clazz in
                ClassSidebarRow(clazz: clazz)
                    .tag(clazz.objectID as NSManagedObjectID?)
            }
        }
        .listStyle(.sidebar)
        .foregroundStyle(.orange)
        .navigationSplitViewColumnWidth(min: 150, ideal: 250, max: .infinity)
        
        Button(action: { showingClassPopover.toggle() }) {
            Image(systemName: "plus")
                .foregroundStyle(Color.green)
        }
        .padding()
        .popover(isPresented: $showingClassPopover) {
            VStack(alignment: .leading, spacing: 16) {
                Text("New Class")
                    .font(.headline)
                TextField("Class name", text: $newClassName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                    .onSubmit {
                        onAddClass()
                    }
                
                HStack {
                    Button("Cancel") {
                        newClassName = ""
                        showingClassPopover = false
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Add") {
                        onAddClass()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newClassName.isEmpty)
                }
            }
            .padding(20)
        }
    }
}

private struct ClassSidebarRow: View {
    @ObservedObject var clazz: Classes

    var body: some View {
        Text(clazz.name ?? "Untitled")
            .bold()
    }
}
    
private struct AssignmentsDetailView: View {
    let tasksFetched: FetchedResults<AssignmentTask>
    let classes: FetchedResults<Classes>
    @Binding var newTaskTitle: String
    @Binding var date: Date
    @Binding var time: Date
    @Binding var selectedTaskClassID: NSManagedObjectID?
    @Binding var showingAddPopover: Bool
    let onDelete: (AssignmentTask) -> Void
    let onAddTask: () -> Void
    let onAppear: () -> Void
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            Text("Assignments")
                .font(.largeTitle)
                .bold()
                .padding()
                .foregroundStyle(.blue)
            
            Text("Assignments Due For Today: \(appData.tasksDueToday.count)")
                .padding()
            
            Button(action: { showingAddPopover = true }) {
                Text("Add Task")
                    .font(.headline)
                    .padding()
                    .foregroundStyle(.white)
                    .frame(width: 100)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PlainButtonStyle())
            List {
                ForEach(tasksFetched, id: \.objectID) { task in
                    TaskRowView(task: task, onDelete: onDelete)
                }
            }
            .onAppear(perform: onAppear)
            .popover(isPresented: $showingAddPopover) {
                AddTaskPopover(
                    newTaskTitle: $newTaskTitle,
                    date: $date,
                    time: $time,
                    selectedTaskClassID: $selectedTaskClassID,
                    classes: classes,
                    onAdd: onAddTask
                )
            }
        }
    }
}

private struct TaskRowView: View {
    let task: AssignmentTask
    let onDelete: (AssignmentTask) -> Void
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        HStack(spacing: 10) {
            Text(task.taskTitle ?? "Untitled")
            Text(appData.dateFormatter.string(from: task.taskDate ?? Date()))
            Text(appData.timeFormatter.string(from: task.taskTime ?? Date()))
            Text(task.clazz?.name ?? "")
            Button("Completed") { onDelete(task) }
                .font(.caption)
                .foregroundStyle(Color.green)
        }
    }
}

private struct AddTaskPopover: View {
    @Binding var newTaskTitle: String
    @Binding var date: Date
    @Binding var time: Date
    @Binding var selectedTaskClassID: NSManagedObjectID?
    let classes: FetchedResults<Classes>
    let onAdd: () -> Void
    
    private var selectedClassName: String {
        guard let selectedTaskClassID,
              let clazz = classes.first(where: { $0.objectID == selectedTaskClassID }) else {
            return "Current Classes"
        }
        return clazz.name ?? "Untitled"
    }
    
    var body: some View {
        VStack {
            TextField("Task", text: $newTaskTitle)
            DatePicker("Select a date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
            DatePicker("Select a time", selection: $time, displayedComponents: .hourAndMinute)
            Menu {
                ForEach(classes, id: \.objectID) { clazz in
                    Button(clazz.name ?? "Untitled") {
                        selectedTaskClassID = clazz.objectID
                    }
                }
            } label: {
                Text(selectedClassName)
            }
            Button("Add", action: onAdd)
                .disabled(newTaskTitle.isEmpty)
                .disabled(selectedTaskClassID == nil)
        }
        .padding()
    }
}

// MARK: - Helpers

private extension HomeView {
    func dailyGoalCount() {
        appData.tasksDueToday = []
        for task in tasksFetched {
            let isToday = Calendar.current.isDate(task.taskDate ?? Date(), inSameDayAs: Date.now)
            if isToday {
                appData.tasksDueToday.append(task)
            }
        }
    }

    func addNewClass(name: String) {
        let newClass = Classes(context: viewContext)
        newClass.name = name

        do {
            try viewContext.obtainPermanentIDs(for: [newClass])
            try viewContext.save()
            newClassName = ""
            showingClassPopover = false
        } catch {
            print("Failed to save class: \(error.localizedDescription)")
        }
    }

    func addTask() {
        guard !newTaskTitle.isEmpty,
              let selectedClassID = selectedTaskClassID,
              let selectedTaskClass = classesFetched.first(where: { $0.objectID == selectedClassID }) else {
            return
        }

        let newTask = AssignmentTask(context: viewContext)
        newTask.taskTitle = newTaskTitle
        newTask.taskDate = date
        newTask.taskTime = time
        newTask.clazz = selectedTaskClass

        do {
            try viewContext.save()
            dailyGoalCount()
            newTaskTitle = ""
            date = .now
            selectedTaskClassID = nil
            showingAddPopover = false
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}

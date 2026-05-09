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
    @State private var selectedClass: String? = nil
    @State private var newClassName: String = ""
    @State private var className: String = ""
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
        sortDescriptors: [],
        animation: .default
    ) var classesFetched: FetchedResults<Classes>

    private var classes: [String] {
        Array(Set(classesFetched.map { $0.name ?? "None" })).sorted()
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedClass: $selectedClass,
                newClassName: $newClassName,
                showingClassPopover: $showingClassPopover,
                classes: classes,
                onAddClass: { addNewClass(name: newClassName) }
            )
        } detail: {
            ZStack(alignment: .topTrailing) {
                if let name = selectedClass {
                    ClassView(name: name)
                } else {
                    AssignmentsDetailView(
                        tasksFetched: tasksFetched,
                        classes: classes,
                        newTaskTitle: $newTaskTitle,
                        date: $date,
                        time: $time,
                        className: $className,
                        showingAddPopover: $showingAddPopover,
                        onDelete: { delete(task: $0) },
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
    @Binding var selectedClass: String?
    @Binding var newClassName: String
    @Binding var showingClassPopover: Bool
    let classes: [String]
    let onAddClass: () -> Void

    var body: some View {
        Button(action: { selectedClass = nil }) {
            Text("Home").font(.title)
                .foregroundStyle(Color.blue)
        }

        Text("My Classes").font(.title)

        HStack {
            Button(action: { showingClassPopover.toggle() }) {
                Text("Add Class").font(.subheadline)
            }
        }
        .popover(isPresented: $showingClassPopover) {
            VStack {
                TextField("Class Name: ", text: $newClassName)
                Button("Add", action: onAddClass)
                    .disabled(newClassName.isEmpty)
            }
        }

        List(classes, id: \.self, selection: $selectedClass) { name in
            Text(name).bold()
        }
        .listStyle(.sidebar)
        .foregroundStyle(.orange)
        .navigationSplitViewColumnWidth(min: 150, ideal: 250, max: .infinity)
    }
}

private struct AssignmentsDetailView: View {
    let tasksFetched: FetchedResults<AssignmentTask>
    let classes: [String]
    @Binding var newTaskTitle: String
    @Binding var date: Date
    @Binding var time: Date
    @Binding var className: String
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
                    className: $className,
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
            Text(task.class_name ?? "")
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
    @Binding var className: String
    let classes: [String]
    let onAdd: () -> Void

    var body: some View {
        VStack {
            TextField("Task", text: $newTaskTitle)
            DatePicker("Select a date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
            DatePicker("Select a time", selection: $time, displayedComponents: .hourAndMinute)
            TextField("Class", text: $className)
            Menu {
                ForEach(classes, id: \.self) { name in
                    Button(name) { className = name }
                }
            } label: {
                Text("Current Classes")
            }
            Button("Add", action: onAdd)
                .disabled(newTaskTitle.isEmpty)
                .disabled(className.isEmpty)
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

    func delete(task: AssignmentTask) {
        viewContext.delete(task)
        appData.tasksDueToday.removeAll { $0.objectID == task.objectID }
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }

    func addNewClass(name: String) {
        let newClass = Classes(context: viewContext)
        newClass.name = name
        do {
            try viewContext.save()
            newClassName = ""
            showingClassPopover = false
        } catch {
            print("Failed to save class: \(error.localizedDescription)")
        }
    }

    func addTask() {
        let newTask = AssignmentTask(context: viewContext)
        newTask.taskTitle = newTaskTitle
        newTask.taskDate = date
        newTask.taskTime = time
        newTask.class_name = className
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
        dailyGoalCount()
        newTaskTitle = ""
        date = .now
        className = ""
        showingAddPopover = false
    }
}


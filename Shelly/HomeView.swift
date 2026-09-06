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
    @State private var selectedClassID: UUID? = nil
    @State private var newClassName: String = ""
    @State private var taskClassName: String = ""
    @State private var showingClassPopover = false
    @State private var showingAddPopover = false
    private var selectedClass: Classes? {
        guard let selectedClassID else { return nil }
        return classesFetched.first { $0.id == selectedClassID }
    }
    
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

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedClassID: $selectedClassID,
                newClassName: $newClassName,
                showingClassPopover: $showingClassPopover,
                classes: classesFetched,
                onAddClass: { addClass(name: newClassName) }
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
                        taskClassName: $taskClassName,
                        showingAddPopover: $showingAddPopover,
                        onDelete: { task in
                            viewContext.delete(task)
                            appData.tasksDueToday.removeAll { $0.id == task.id }
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
    @Binding var selectedClassID: UUID?
    @Binding var newClassName: String
    @Binding var showingClassPopover: Bool
    let classes: FetchedResults<Classes>
    let onAddClass: () -> Void
    
    var body: some View {
        Button(action: { selectedClassID = nil }) {
            Image(systemName: "house.fill")
            .foregroundStyle(.blue)
        }
        
        Divider()
        HStack {
            Text("My Classes")
                .font(.title)
                .foregroundStyle(Color.blue)
            
            Button(action: { showingClassPopover.toggle() }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
            List(selection: $selectedClassID) {
                ForEach(classes, id: \.id) { clazz in
                    ClassSidebarRow(clazz: clazz)
                        .tag(clazz.id)
                }
            }
        .listStyle(.sidebar)
        .foregroundStyle(.orange)
        .navigationSplitViewColumnWidth(min: 150, ideal: 250, max: .infinity)

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
    @Binding var taskClassName: String
    @Binding var showingAddPopover: Bool
    let onDelete: (AssignmentTask) -> Void
    let onAddTask: () -> Void
    let onAppear: () -> Void
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assignments")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.blue)
                    
                    Text("\(appData.tasksDueToday.count) due today")
                        .contentTransition(.numericText())
                        .animation(.default, value: appData.tasksDueToday.count)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingAddPopover = true }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            Divider()
            
            List {
                ForEach(tasksFetched, id: \.id) { task in
                    TaskRowView(task: task, onDelete: onDelete)
                }
            }
            .onAppear(perform: onAppear)
            .popover(isPresented: $showingAddPopover) {
                AddTaskPopover(
                    newTaskTitle: $newTaskTitle,
                    date: $date,
                    time: $time,
                    taskClassName: $taskClassName,
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
            Button(action: { onDelete(task) }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

        }
    }
}
    
    private struct AddTaskPopover: View {
        @Binding var newTaskTitle: String
        @Binding var date: Date
        @Binding var time: Date
        @Binding var taskClassName: String
        let classes: FetchedResults<Classes>
        let onAdd: () -> Void
        
        // Used for comparing for automcomplete
        private var trimmedClassName: String {
            taskClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Autocomplete suggestions from current classes
        private var suggestedClasses: [Classes] {
            classes.filter { clazz in
                let name = clazz.name ?? ""
                return !trimmedClassName.isEmpty && name.localizedCaseInsensitiveContains(trimmedClassName)
            }
        }
        
        var body: some View {
            VStack {
                TextField("Task", text: $newTaskTitle)
                DatePicker("Select a date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                DatePicker("Select a due time", selection: $time, displayedComponents: .hourAndMinute)
                TextField("Class", text: $taskClassName)
                    .textFieldStyle(.roundedBorder)
                    .textInputSuggestions {
                        ForEach(suggestedClasses, id: \.id) { clazz in
                            let name = clazz.name ?? "Untitled"
                            Text(name)
                                .textInputCompletion(name)
                        }
                    }
                Button("Add", action: onAdd)
                    .foregroundStyle(.blue)
                    .disabled(newTaskTitle.isEmpty)
                    .disabled(trimmedClassName.isEmpty)
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

    func addClass(name: String) {
        let newClass = Classes(context: viewContext)
        newClass.id = UUID()
        newClass.name = name

        do {
            try viewContext.save()
            newClassName = ""
            showingClassPopover = false
        } catch {
            print("Failed to save class: \(error.localizedDescription)")
        }
    }

    func existingClass(named name: String) -> Classes? {
        classesFetched.first {
            ($0.name ?? "").localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }

    func createClass(name: String) -> Classes {
        let newClass = Classes(context: viewContext)
        newClass.id = UUID()
        newClass.name = name
        return newClass
    }

    func addTask() {
        let trimmedClassName = taskClassName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTaskTitle.isEmpty, !trimmedClassName.isEmpty else {
            return
        }

        let taskClass = existingClass(named: trimmedClassName) ?? createClass(name: trimmedClassName)
        let newTask = AssignmentTask(context: viewContext)
        newTask.id = UUID()
        newTask.taskTitle = newTaskTitle
        newTask.taskDate = date
        newTask.taskTime = time
        newTask.clazz = taskClass

        do {
            try viewContext.save()
            dailyGoalCount()
            newTaskTitle = ""
            date = .now
            taskClassName = ""
            showingAddPopover = false
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}

//
//  HomeView.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 1/2/25.
//
import SwiftUI
import CoreData

struct HomeView: View {
    // Injects the CorData context object to be used for fetching, saving, or deleting from disk
    @Environment(\.managedObjectContext) private var viewContext
    // Environment object that stores attribute variables that are accessible across the project
    @EnvironmentObject var appData: AppData
    @State private var newTaskTitle: String = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var NSVClassNameSelection: String? = nil
    @State private var newClassName: String = ""
    @State private var className: String = ""
    @State private var showingClassPopover = false
    @State private var showingAddPopover = false
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
    
    // Continously fetches CoreData changes into the view and sorts these in earliest due order
    @FetchRequest(
        entity: AssignmentTask.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AssignmentTask.taskDate, ascending: true),
            NSSortDescriptor(keyPath: \AssignmentTask.taskTime, ascending: true)
        ],
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
        // Define the side menu with our Home Button and list of classes
        NavigationSplitView {
            Button(action: {
                NSVClassNameSelection = nil
            }){
                Text("Home")
                    .font(.title)
            }
            
            Text("My Tasks")
                .font(.title)
            
            Text("My Classes")
                .font(.title)
            HStack {
                Button(action: {
                    showingClassPopover.toggle()
                }) {
                    Text("Add Class")
                        .font(.subheadline)
                }
            }
            .popover(isPresented: $showingClassPopover) {
                VStack {
                    TextField("Class Name: ", text: $newClassName)
                    Button("Add") {
                        addNewClass(name: newClassName)
                    }
                    .disabled(newClassName.isEmpty)
                }
            }
            List(classes, id: \.self, selection: $NSVClassNameSelection) { name in
                Text(name).bold()
            }
            .listStyle(.sidebar)
            .foregroundStyle(.orange)
            .navigationSplitViewColumnWidth(min: 150, ideal: 250, max: .infinity)
        } detail: {
            ZStack(alignment: .topTrailing) {
                if let className = NSVClassNameSelection {
                    ClassView(name: className)
                } else {
                    VStack {
                        Text("Assignments")
                            .font(.largeTitle)
                            
                            .bold()
                            .padding()
                            .foregroundStyle(.blue)
                        // Call our Environment object to access a global state wide array
                        Text("Assignments Due For Today: \(appData.tasksDueToday.count)")
                            .padding()
                        
                        Button(action: {
                            showingAddPopover = true
                        }) {
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
                                HStack(spacing: 10) {
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
                        .onAppear {
                            dailyGoalCount()
                        }
                        .popover(isPresented: $showingAddPopover) {
                            // Your popover view content
                            VStack {
                                TextField("Task", text: $newTaskTitle)
                                DatePicker("Select a date", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                DatePicker("Select a time", selection: $time, displayedComponents: .hourAndMinute)
                                TextField("Class", text:$className)
                                Menu {
                                    ForEach(classes, id: \.self) { name in
                                        Button(name) {
                                            className = name
                                        }
                                    }
                                } label: {
                                    Text("Current Classes")
                                }
                                Button("Add") {
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
                                .disabled(newTaskTitle.isEmpty)
                                .disabled(className.isEmpty)
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
    // Function to count the number of daily tasks to complete
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
    // Deletes the completed task from the list when it is called
    public func delete(task: AssignmentTask) {
        viewContext.delete(task)
        appData.tasksDueToday.removeAll { $0.objectID == task.objectID }
        
        do {
            try viewContext.save()
        } catch {
            print("Error occured: \(error)")
        }
    }
    
    private func addNewClass(name: String) {
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
}


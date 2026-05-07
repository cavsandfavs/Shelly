//
//  AppData.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 10/15/25.
//

import SwiftUI

class AppData: ObservableObject {
    @Published var tasksDueToday: [AssignmentTask] = []
    
    // Shared date/time formatters for a single source of truth
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

//
//  AppData.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 10/15/25.
//

import SwiftUI

class AppData: ObservableObject {
    @Published var tasksDueToday: [AssignmentTask] = []
}

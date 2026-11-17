//
//  AssignmentTask+Overdue.swift
//  Shelly
//
//  Created by Assistant on 11/4/26.
//

import Foundation

extension AssignmentTask {
    // Combines taskDate and taskTime into a single Date for comparison
    var dueDateTime: Date? {
        guard let date = taskDate, let time = taskTime else { return taskDate ?? taskTime }
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute, .second], from: time)
        return cal.date(
            bySettingHour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            second: comps.second ?? 0,
            of: date
        )
    }

    // True if the combined due date/time is in the past
    var isOverdue: Bool {
        guard let due = dueDateTime else { return false }
        return due < Date()
    }
}

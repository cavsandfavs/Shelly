//
//  ShellyApp.swift
//  Shelly
//
//  Created by Christopher Wallrauch on 12/29/24.
//
import SwiftUI
@main

struct ShellyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }

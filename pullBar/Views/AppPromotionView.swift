//
//  AppPromotionView.swift
//  pullBar
//
//  Created by Pavel Makhov on 2025-03-08.
//

import SwiftUI

struct AppPromotionView: View {
    let apps: [MyApp] = [
        MyApp(name: "ToDoBar",
            description: "Description for App One",
            iconName: "todobar",
            appStoreURL: "https://apps.apple.com/app/id1641624925"),
        MyApp(name: "GojiBar",
            description: "Description for App Two",
            iconName: "gojibar",
            appStoreURL: "https://apps.apple.com/app/id6471348025"),
        MyApp(name: "PullBar Pro",
            description: "Description for App Three",
            iconName: "pullbarpro",
            appStoreURL: "https://apps.apple.com/app/id6462591649"),
        MyApp(name: "StreakBar",
            description: "Description for App Four",
            iconName: "streakbar",
            appStoreURL: "https://apps.apple.com/app/id6464448808"),
    ]
    
    var body: some View {
        Text("More apps")
            .font(.headline)
        
        HStack {
            ForEach(apps, id:\.id) { app in
                AppView(app: app)
            }
            
        }
    }
}

#Preview {
    AppPromotionView()
}

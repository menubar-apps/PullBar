//
//  AppView.swift
//  pullBar
//
//  Created by Pavel Makhov on 2025-03-08.
//

import SwiftUI

struct AppView: View {
    @Environment(\.openURL) var openURL

    let app: MyApp
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            Image(app.iconName)
                .resizable()
                .frame(width: 64, height: 64)
            
            Text(app.name)
                .font(.caption)
        }
        .padding(8)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            openURL(URL(string: app.appStoreURL)!)
        }
    }
}

struct MyApp: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let appStoreURL: String
}

#Preview {
    AppView(app: MyApp(name: "GojiBar",
                           description: "Descriptxion for App One",
                           iconName: "gojibar",
                           appStoreURL: "https://apps.apple.com/app/id6471348025"))
}


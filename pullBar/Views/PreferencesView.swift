//
//  GeneralTab.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-14.
//

import SwiftUI
import Defaults
import KeychainAccess
import LaunchAtLogin

struct PreferencesView: View {

    @Default(.bitbucketBaseUrl) var bitbucketBaseUrl
    @FromKeychain(.bitbucketToken) var bitbucketToken
    @FromKeychain(.bitbucketUsername) var bitbucketUsername

    @Default(.categories) var categories

    @Default(.showAvatar) var showAvatar
    @Default(.showLabels) var showLabels

    @Default(.refreshRate) var refreshRate
    @Default(.buildType) var builtType
    @Default(.counterSelection) var counterSelection

    @State private var showGhAlert = false

    @StateObject private var githubTokenValidator = GithubTokenValidator()

    var body: some View {

        TabView {
            Form {
                HStack(alignment: .center) {
                    Text("Build Information:").frame(width: 120, alignment: .trailing)
                    Picker("", selection: $builtType, content: {
                        ForEach(BuildType.allCases) { bt in
                            Text(bt.description)
                        }
                    })
                    .labelsHidden()
                    .pickerStyle(RadioGroupPickerStyle())
                    .frame(width: 120)
                }

                HStack(alignment: .center) {
                    Text("Show Avatar:").frame(width: 120, alignment: .trailing)
                    Toggle("", isOn: $showAvatar)
                }

                HStack(alignment: .center) {
                    Text("Show Labels:").frame(width: 120, alignment: .trailing)
                    Toggle("", isOn: $showLabels)
                }

                HStack(alignment: .center) {
                    Text("Refresh Rate:").frame(width: 120, alignment: .trailing)
                    Picker("", selection: $refreshRate, content: {
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }).labelsHidden()
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                }

                HStack(alignment: .center) {
                    Text("Launch at login:").frame(width: 120, alignment: .trailing)
                    LaunchAtLogin.Toggle {
                        Text("")
                    }
                }

            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .tabItem{Text("General")}

            categoriesTab
                .tabItem{Text("Categories")}

            Form {
                HStack(alignment: .center) {
                    Text("Bitbucket Base URL:").frame(width: 130, alignment: .trailing)
                    TextField("https://bitbucket.example.com", text: $bitbucketBaseUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .frame(width: 430)
                        .onChange(of: bitbucketBaseUrl) { _ in
                            githubTokenValidator.validate()
                        }
                }
                HStack(alignment: .center) {
                    Text("Username:").frame(width: 130, alignment: .trailing)
                    TextField("", text: $bitbucketUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .frame(width: 430)
                        .onChange(of: bitbucketUsername) { _ in
                            githubTokenValidator.validate()
                        }
                }
                HStack(alignment: .center) {
                    Text("HTTP Token:").frame(width: 130, alignment: .trailing)
                    VStack(alignment: .leading) {
                        HStack() {
                            SecureField("", text: $bitbucketToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    Image(systemName: githubTokenValidator.iconName).foregroundColor(githubTokenValidator.iconColor)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .padding(.trailing, 8)
                                )
                                .frame(width: 380)
                                .onChange(of: bitbucketToken) { _ in
                                    githubTokenValidator.validate()
                                }
                            Button {
                                githubTokenValidator.validate()
                            } label: {
                                Image(systemName: "repeat")
                            }
                            .help("Retry")
                        }
                        if let errorMessage = githubTokenValidator.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: 420, alignment: .leading)
                                .padding(.leading, 8)
                        }
                        Text("Use your Bitbucket user's HTTP access token (create one under Account settings > HTTP access tokens). Basic auth with your username is used.")
                            .font(.footnote)
                            .padding(.leading, 8)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .onAppear() {
                githubTokenValidator.validate()
            }
            .tabItem{Text("Authentication")}

        }
        .frame(width: 780)
        .padding()

    }

    /// Categories management tab: a reorderable list of role-based categories.
    /// Bitbucket Data Center filters pull requests by the viewer's role, so
    /// each category simply selects a role.
    private var categoriesTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories appear in the menu in this order. Drag to reorder. Tick Menubar to show a category's count next to the icon.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            List {
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16, height: 1)
                    Text("Category name").frame(width: 150, alignment: .leading)
                    Text("Role").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Show in").frame(width: 120, alignment: .leading)
                    Text("Menubar").frame(width: 60, alignment: .center)
                    Color.clear.frame(width: 24, height: 1)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                ForEach($categories) { $category in
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal")
                            .frame(width: 16)
                            .foregroundColor(.secondary)
                            .help("Drag to reorder")
                        TextField("name", text: $category.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                        Picker("", selection: $category.role) {
                            ForEach(BitbucketRole.allCases, id: \.self) { role in
                                Text(role.displayName).tag(role)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                        Picker("", selection: $category.asSubmenu) {
                            Text("Main menu").tag(false)
                            Text("Submenu").tag(true)
                        }
                        .labelsHidden()
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        .help("Where this category's pull requests appear in the menu")
                        Toggle("", isOn: Binding(
                            get: { counterSelection == category.id },
                            set: { counterSelection = $0 ? category.id : SearchCategory.counterNone }
                        ))
                        .labelsHidden()
                        .frame(width: 60)
                        .help("Show this category's count next to the menubar icon")
                        Button {
                            if counterSelection == category.id {
                                counterSelection = SearchCategory.counterNone
                            }
                            categories.removeAll { $0.id == category.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: 24)
                        .help("Delete category")
                    }
                    .padding(.vertical, 2)
                }
                .onMove { indices, newOffset in
                    categories.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .frame(height: 260)

            HStack(spacing: 8) {
                Menu {
                    ForEach(BuiltinTemplate.allCases) { template in
                        Button(template.name) {
                            categories.append(template.makeCategory(id: UUID().uuidString))
                        }
                    }
                    Divider()
                    Button("Custom") {
                        categories.append(SearchCategory(id: UUID().uuidString, name: "", role: .all))
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .frame(width: 60)

                Text("Each category maps to a Bitbucket dashboard role: Incoming (PRs you are asked to review), Created By Me, or All (any PR you take part in).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
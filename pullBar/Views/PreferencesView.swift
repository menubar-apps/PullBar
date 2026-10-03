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

    @Default(.githubApiBaseUrl) var githubApiBaseUrl
    @Default(.githubUsername) var githubUsername
    @Default(.githubAdditionalQuery) var githubAdditionalQuery
    @FromKeychain(.githubToken) var githubToken

    @Default(.categories) var categories

    @Default(.showAvatar) var showAvatar
    @Default(.showLabels) var showLabels

    @Default(.refreshRate) var refreshRate
    @Default(.buildType) var builtType
    @Default(.counterSelection) var counterSelection

    @State private var showGhAlert = false

    @StateObject private var githubTokenValidator = GithubTokenValidator()
//    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable

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
                    Text("API Base URL:").frame(width: 120, alignment: .trailing)
                    TextField("", text: $githubApiBaseUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .frame(width: 200)
                }
                HStack(alignment: .center) {
                    Text("Username:").frame(width: 120, alignment: .trailing)
                    TextField("", text: $githubUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .frame(width: 200)
                }

                HStack(alignment: .center) {
                    Text("Token:").frame(width: 120, alignment: .trailing)
                    VStack(alignment: .leading) {
                        HStack() {
                            SecureField("", text: $githubToken)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    Image(systemName: githubTokenValidator.iconName).foregroundColor(githubTokenValidator.iconColor)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .padding(.trailing, 8)
                                )
                                .frame(width: 380)
                                .onChange(of: githubToken) { _ in
                                    githubTokenValidator.validate()
                                }
                            Button {
                                githubTokenValidator.validate()
                            } label: {
                                Image(systemName: "repeat")
                            }
                            .help("Retry")
                        }
                        Text("[Generate](https://github.com/settings/tokens/new?scopes=repo) a personal access token, make sure to select **repo** scope")
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

            Form {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Counter:")
                        Text("Number of pull requests next to the icon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Picker("", selection: $counterSelection, content: {
                        Section {
                            Text("None").tag(SearchCategory.counterNone)
                            Text("My team").tag(SearchCategory.counterMyTeam)
                        }
                        Section {
                            ForEach(categories) { category in
                                Text(category.name.isEmpty ? "(unnamed)" : category.name).tag(category.id)
                            }
                        }
                    })
                    .labelsHidden()
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .tabItem{Text("Menubar icon")}

            Form {
                HStack(alignment: .top) {
                    Text("Additional Query:").frame(width: 120, alignment: .trailing)
                    TextField("", text: $githubAdditionalQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textContentType(.password)
                        .frame(width: 380)

                }
                Text("See the GitHub [search documentation](https://docs.github.com/en/search-github/getting-started-with-searching-on-github/understanding-the-search-syntax) for more information on advanced queries")
                    .font(.footnote)
                    .padding(.leading, 8)
                    .foregroundColor(.secondary)
            }.padding(8)
                .frame(maxWidth: .infinity)
                .tabItem{Text("Advanced")}

        }
        .frame(width: 780)
        .padding()

    }

    /// Categories management tab: a scrollable, reorderable list of categories
    /// with per-row name/filter editing and deletion, plus a "+" menu to add
    /// builtin templates or a blank custom category.
    private var categoriesTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories appear in the menu in this order. Drag to reorder.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            List {
                HStack(spacing: 8) {
                    Color.clear.frame(width: 16, height: 1)
                    Text("Category name").frame(width: 150, alignment: .leading)
                    Text("Search query").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Show in").frame(width: 120, alignment: .leading)
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
                        TextField("filter, e.g. review-requested:@me", text: $category.filter)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        Picker("", selection: $category.asSubmenu) {
                            Text("Main menu").tag(false)
                            Text("Submenu").tag(true)
                        }
                        .labelsHidden()
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        .help("Where this category's pull requests appear in the menu")
                        Button {
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
                .onDelete { offsets in
                    categories.remove(atOffsets: offsets)
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
                        categories.append(SearchCategory(id: UUID().uuidString, name: "", filter: ""))
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .frame(width: 60)

                Text("Use \(SearchCategory.usernamePlaceholder) in a filter to insert your username.")
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

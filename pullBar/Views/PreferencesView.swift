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

    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested

    @Default(.showAvatar) var showAvatar
    @Default(.showLabels) var showLabels

    @Default(.refreshRate) var refreshRate
    @Default(.buildType) var builtType
    @Default(.counterType) var counterType

    @State private var showGhAlert = false

    @StateObject private var githubTokenValidator = GithubTokenValidator()
//    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    
    @State private var isExpanded: Bool = false

    var body: some View {

        TabView {
            Form {
                HStack(alignment: .center) {
                    Text("Pull Requests:").frame(width: 120, alignment: .trailing)
                    VStack(alignment: .leading){
                        Toggle("assigned", isOn: $showAssigned)
                        Toggle("created", isOn: $showCreated)
                        Toggle("review requested", isOn: $showRequested)
                    }
                }

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
                    Picker("", selection: $counterType, content: {
                        ForEach(CounterType.allCases) { bt in
                            Text(bt.description)
                        }
                    })
                    .labelsHidden()
                    .pickerStyle(RadioGroupPickerStyle())
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
        .frame(width: 600)
        .padding()

    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

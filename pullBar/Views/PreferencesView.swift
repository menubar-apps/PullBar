//
//  GeneralTab.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-14.
//

import SwiftUI
import Defaults
import LaunchAtLogin

struct PreferencesView: View {
    @Environment(\.openURL) var openURL

    @Default(.githubApiBaseUrl) var githubApiBaseUrl
    @Default(.githubUsername) var githubUsername
    @Default(.githubAdditionalQuery) var githubAdditionalQuery

    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested

    @Default(.showAvatar) var showAvatar
    @Default(.showLabels) var showLabels

    @Default(.refreshRate) var refreshRate
    @Default(.buildType) var builtType
    @Default(.counterType) var counterType

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
                HStack(alignment: .top) {
                    Text("GitHub CLI:").frame(width: 120, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PullBar uses your local GitHub CLI login.")
                        Text("Run `gh auth login --web` in Terminal and grant repository read access.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button("Open gh auth docs") {
                            guard let url = URL(string: "https://cli.github.com/manual/gh_auth_login") else { return }
                            openURL(url)
                        }
                    }
                }
                HStack(alignment: .center) {
                    Text("GitHub Username:").frame(width: 120, alignment: .trailing)
                    TextField("", text: $githubUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .frame(width: 240)
                }
                HStack(alignment: .top) {
                    Text("Legacy API URL:").frame(width: 120, alignment: .trailing)
                    TextField("", text: $githubApiBaseUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .frame(width: 200)
                    Text("unused by gh mode")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
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

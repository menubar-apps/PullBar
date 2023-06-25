//
//  GeneralTab.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-14.
//

import SwiftUI
import Defaults
import KeychainAccess

struct PreferencesView: View {
    
    @Default(.githubUsername) var githubUsername
    @FromKeychain(.githubToken) var githubToken
    
    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested
    
    @Default(.showAvatar) var showAvatar
    @Default(.showChecks) var showChecks
    @Default(.showCommitStatus) var showCommitStatus
    @Default(.showLabels) var showLabels
    
    @Default(.refreshRate) var refreshRate
    
    @State private var showGhAlert = false
    
    @StateObject private var githubTokenValidator = GithubTokenValidator()
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("Authentication")
                        .font(.callout)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                    Form {
                        Section {
                            HStack(alignment: .center) {
                                Text("GitHub username:").frame(width: 120, alignment: .trailing)
                                TextField("", text: $githubUsername)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disableAutocorrection(true)
                                    .textContentType(.password)
                                    .frame(width: 200)
                            }
                            
                            HStack(alignment: .center) {
                                Text("GitHub token:").frame(width: 120, alignment: .trailing)
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
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.lightGray), lineWidth: 1)
                    )
                    

                    HStack(alignment: .center) {
                        Text("Show pull requests:").frame(width: 120, alignment: .trailing)
                        VStack(alignment: .leading){
                            Toggle("assigned", isOn: $showAssigned)
                            Toggle("created", isOn: $showCreated)
                            Toggle("review requested", isOn: $showRequested)
                        }
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
                        Text("Build:").frame(width: 120, alignment: .trailing)
                        VStack(alignment: .leading){
                            Toggle("checks", isOn: $showChecks)
                            Toggle("commit status", isOn: $showCommitStatus)
                        }
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
                }
            }
        }
        .padding()
        .onAppear() {
            githubTokenValidator.validate()
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

//
//  GeneralTab.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-14.
//

import SwiftUI
import Defaults

struct PreferencesView: View {
    
    @Default(.githubUsername) var githubUsername
    @Default(.githubToken) var githubToken
    
    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested
    
    @Default(.showAvatar) var showAvatar
    
    @Default(.refreshRate) var refreshRate
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text("GitHub username:").frame(width: 120, alignment: .trailing)
                        TextField("", text: $githubUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    
                    HStack(alignment: .center) {
                        Text("GitHub token:").frame(width: 120, alignment: .trailing)
                        SecureField("", text: $githubToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 340)
                    }
                    Divider()
                    HStack(alignment: .center) {
                        Text("Show pull requests:").frame(width: 120, alignment: .trailing)
                        VStack(alignment: .leading){
                            Toggle("assigned", isOn: $showAssigned)
                            Toggle("created", isOn: $showCreated)
                            Toggle("review requested", isOn: $showRequested)
                        }
                    }
                    
                    HStack(alignment: .center) {
                        Text("Show avatar:").frame(width: 120, alignment: .trailing)
                        Toggle("", isOn: $showAvatar)
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
        .frame(width: 500)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

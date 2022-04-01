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
//    @Default(.githubToken) var githubToken
    
    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested
    
    @Default(.showAvatar) var showAvatar
    @Default(.showChecks) var showChecks
    
    @Default(.refreshRate) var refreshRate
    
    @State var val = ""
    @KeychainStorage("githubToken") var githubTokenSec

    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text("GitHub Username:").frame(width: 120, alignment: .trailing)
                        TextField("", text: $githubUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 200)
                    }
                    
                    HStack(alignment: .center) {
                        Text("GitHub Token:").frame(width: 120, alignment: .trailing)
                        VStack(alignment: .leading) {
//                            SecureField("", text: $githubToken)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .frame(width: 340)
                            SecureField("", text: $githubTokenSec)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 340)
                            Text("[Generate](https://github.com/settings/tokens/new?scopes=repo) a personal access token, make sure to select **repo** scope")
                                .font(.footnote)
                        }
                    }
                    Divider()
                    HStack(alignment: .center) {
                        Text("Show Pull Requests:").frame(width: 120, alignment: .trailing)
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
                        Text("Show Checks:").frame(width: 120, alignment: .trailing)
                        Toggle("", isOn: $showChecks)
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
//        .onAppear{
//            print("on appear")
//            val = githubTokenSec
//            print("a-val=\(val)")
//            print("a-githubTokenSec=\(githubTokenSec)")
//        }
//        .onDisappear{print("disappear")}
//        .onExitCommand {
//            githubTokenSec = val
//            print("d-val=\(val)")
//            print("d-githubTokenSec=\(githubTokenSec)")
//        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}


@propertyWrapper
struct KeychainStorage: DynamicProperty {
  let key: String
  @State private var value: String
  init(wrappedValue: String = "", _ key: String) {
    self.key = key
    let initialValue = (try? Keychain().get(key)) ?? wrappedValue
    self._value = State<String>(initialValue: initialValue)
  }
  var wrappedValue: String {
      get { (try? Keychain().get(key)) ?? "" }

    nonmutating set {
      value = newValue
      do {
        try Keychain().set(value, key: key)
          print("setting new value \(value)")
      } catch let error {
        fatalError("\(error)")
      }
    }
  }
  var projectedValue: Binding<String> {
    Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }
}

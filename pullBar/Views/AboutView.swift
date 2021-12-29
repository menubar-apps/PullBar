//
//  AboutView.swift
//  pullBar
//
//  Created by Casey Jones on 2021-12-11.
//

import SwiftUI

import SwiftUI

struct AboutView: View {
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    var body: some View {
        VStack {
            Image(nsImage: NSImage(named: "AppIcon")!)
            Text("PullBar").font(.title)
            Text("by Pavel Makhov").font(.caption)
            Text("version " + currentVersion).font(.footnote)
            Divider()
            Link("PullBar on GitHub", destination: URL(string: "https://github.com/menubar-apps/PullBar")!)
        }.padding()
    }
}

struct AboutTab_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

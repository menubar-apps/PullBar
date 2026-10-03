//
//  AboutView.swift
//  pullBar
//
//  Created by Casey Jones on 2021-12-11.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    var body: some View {
        VStack {
            Image(nsImage: NSImage(named: "AppIcon")!)
            Text("PullBar").font(.title)
            Text("by Pavel Makhov").font(.caption)
            Text("version " + currentVersion).font(.footnote)
            Divider()
            
            VStack(spacing: 8) {
                linkButton("Feature Request", url: "https://github.com/menubar-apps/PullBar/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.md&title=") {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
                linkButton("Bug Report", url: "https://github.com/menubar-apps/PullBar/issues/new?assignees=&labels=bug&projects=&template=bug_report.md&title=") {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(.red)
                }
                linkButton("Buy me a coffee", url: "https://www.buymeacoffee.com/streetturtle") {
                    Image("bmc-logo-no-background")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 200)
            .padding(.vertical, 4)

            Divider()
            AppPromotionView()
        }.padding()
    }

    private func linkButton<Icon: View>(_ title: String, url: String, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: {
            openURL(URL(string: url)!)
        }) {
            HStack(spacing: 8) {
                icon()
                    .frame(width: 16, height: 16)
                Text(title)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct AboutTab_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

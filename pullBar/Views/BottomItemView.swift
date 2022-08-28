//
//  BottomItemView.swift
//  pullBar
//
//  Created by Casey Jones on 2022-08-18.
//

import SwiftUI


struct BottomItemView: View {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some View {
        
        HStack {
            
//            VStack(alignment: .leading) {
                
                Button{
                    print("pressed")
                    appDelegate.refreshMenu()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.secondary)
                        
                        Image(systemName: "repeat")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(Text("Close"))
//            }
            Spacer()
            HStack(alignment: .bottom){
                Button{
                    print("pressed")
                    appDelegate.openPrefecencesWindow(nil)
                    
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.secondary)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(Text("Close"))
                
                
                Button{
                    print("pressed")
                    appDelegate.openAboutWindow(nil)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.secondary)
                        
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(Text("Close"))
                
                
                Button{
                    print("pressed")
                    appDelegate.quit()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.secondary)
                        
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(Text("Close"))
            }
            
        }.border(Color.pink)
            .frame(maxWidth: .infinity, alignment: .trailing)
        
        
    }
}

struct BottomItemView_Previews: PreviewProvider {
    static var previews: some View {
        BottomItemView()
    }
}

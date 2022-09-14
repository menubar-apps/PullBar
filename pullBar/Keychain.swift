//
//  Keychain.swift
//  pullBar
//
//  Created by Pavel Makhov on 2022-09-14.
//

import SwiftUI
import Defaults
import KeychainAccess
import Foundation

typealias FromKeychain = KeychainStorage
typealias KeychainKeys = KeychainAccessKey

@propertyWrapper
struct KeychainStorage: DynamicProperty {
    
    private let key: KeychainAccessKey
    @ObservedObject
    private var observable: ObservableString
    
    init(wrappedValue: String = "", _ key: KeychainAccessKey) {
        self.key = key
        
        let presentObservable: ObservableString? = ObservablesStore.store[key]
        
        if presentObservable != nil {
            self.observable = presentObservable!
        } else {
            self.observable = ObservableString(key)
            ObservablesStore.store[key] = self.observable
        }
    }
    
    var wrappedValue: String {
        get  { observable.value }
        
        nonmutating set {
            observable.value = newValue
        }
    }
    
    var projectedValue: Binding<String> { $observable.value }
}

private class ObservableString: ObservableObject {

    let key: KeychainAccessKey
    var currentValue: String? = nil
    
    init(_ key: KeychainAccessKey) {
        self.key = key
    }
    
    var value: String {
        get {
            if currentValue == nil {
                currentValue = try? Keychain().get(key.keyName) ?? ""
            }
            
            return currentValue!
        }
        
        set {
            objectWillChange.send()
            
            do {
                currentValue = newValue

                if currentValue!.isEmpty {
                    // Keychain does not want to save empty value
                    try Keychain().remove(key.keyName)
                } else {
                    try Keychain().set(currentValue!, key: key.keyName)
                }
            } catch let error {
                fatalError("\(error)")
            }
        }
    }
}

struct KeychainAccessKey: Hashable {
    let keyName: String
    
    init(key: String) {
        self.keyName = key
    }
}

private struct ObservablesStore {
    static var store: [KeychainAccessKey: ObservableString] = [:]
}

//
//  Mirror+toDictionary.swift
//  WUtilities
//
//  Created by aramik on 7/10/16.
//
//

// MARK: - Extens the Mirror class to add the toDictionary func.

/** Usuage:

 Mirror(reflecting: self).toDictionary()

 **/


public extension Mirror {

    public func toDictionary() -> [String: Any] {
        var dict = [String: Any]()

        // Properties of this instance:
        for attr in self.children {
            if let propertyName = attr.label {
                dict[propertyName] = attr.value
            }
        }

        // Add properties of superclass:
        if let parent = self.superclassMirror {
            for (propertyName, value) in parent.toDictionary() {
                dict[propertyName] = value
            }
        }

        return dict
    }
}

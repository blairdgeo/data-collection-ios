//// Copyright 2018 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import ArcGIS

extension AGSArcGISFeatureTable {
    
    /// Add or update a feature, if possible.
    ///
    /// - Parameters:
    ///     - feature: the modified feature to persist.
    ///     - completion: closure containing an `Error`, if one occured.
    ///
    /// - SeeAlso: `private func performEdit(type: EditType, forFeature feature: AGSArcGISFeature, completion: @escaping (Error?)->Void)`
    
    func performEdit(feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        // Update
        if canUpdate(feature) {
            performEdit(type: .update, forFeature: feature, completion: completion)
        }
        // Add
        else if canAddFeature {
            performEdit(type: .add, forFeature: feature, completion: completion)
        }
        else {
            completion(FeatureTableError.cannotEditFeature)
        }
    }
    
    /// Delete a feature, if possible.
    ///
    /// - Parameters:
    ///     - feature: The feature to delete.
    ///     - completion: Closure containing an `Error`, if one occured.
    ///
    /// - SeeAlso: `private func performEdit(type: EditType, forFeature feature: AGSArcGISFeature, completion: @escaping (Error?)->Void)`
    
    func performDelete(feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        if canDelete(feature) {
            performEdit(type: .delete, forFeature: feature, completion: completion)
        }
        else {
            completion(FeatureTableError.cannotEditFeature)
        }
    }
    
    /// A private enum for communicating edit operation type.
    
    private enum EditType: String {
        
        case add, update, delete
        
        var asAction: String {
            switch self {
            case .add:
                return "adding"
            case .update:
                return "updating"
            case .delete:
                return "deleting"
            }
        }
    }
    
    /// Perform edits of a feature.
    ///
    /// If the feature table is a service feature table (online), the function will also apply the edits remotely,
    /// refreshing the local record in the process.
    ///
    /// - Parameters:
    ///     - type: `.add`, `.update` or `.delete` the record.
    ///     - forFeature: The feature to edit.
    ///     - completion: Closure containing an `Error`, if one occured.
    
    private func performEdit(type: EditType, forFeature feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        func updateObjectID() {
            
            if type != .delete {
                feature.refresh()
            }
            else {
                feature.objectID = nil
            }
        }
        
        func editCompletion(_ error: Error?) {
            
            guard error == nil else {
                print("[Error: Feature Table] could not edit:", error!.localizedDescription)
                completion(error!)
                return
            }
            
            // If online, apply edits.
            guard let serviceFeatureTable = self as? AGSServiceFeatureTable else {
                updateObjectID()
                completion(nil)
                return
            }
            
            serviceFeatureTable.applyEdits() { (results, error) in

                updateObjectID()
                completion(error)
            }
        }
        
        switch type {
        case .update: update(feature, completion: editCompletion)
        case .delete: delete(feature, completion: editCompletion)
        case .add: add(feature, completion: editCompletion)
        }
    }
}

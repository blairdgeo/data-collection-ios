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

import Alamofire

extension Notification.Name {    
    static let reachabilityDidChange = Notification.Name("reachabilityDidChange")
}

extension NetworkReachabilityManager {
    
    /// A singleton `NetworkReachabilityManager` configured with the base portal domain.
    ///
    /// - Note: The first notification is ignored and all subsequent changes are posted to the NotificationCenter.
    ///
    /// - SeeAlso: AppContextChangeHandler.swift
    static let shared: NetworkReachabilityManager = {
        guard let manager = NetworkReachabilityManager(host: .basePortalDomain) else {
            fatalError("Network Reachability Manager must be constructed using a valid service url.")
        }
        return manager
    }()
    
    /// A flag for ignoring the initial reachability change status notification,
    /// only publishing subsequent changes.
    private static var firstReachabilityChangeObserved = false
    
    func resetAndStartListening() {
        stopListening()
        NetworkReachabilityManager.firstReachabilityChangeObserved = false
        startListening { (status) in
            // Print
            switch status {
            case .unknown:
                print("[Reachability] Network reachability is unknown.")
            case .notReachable:
                print("[Reachability] Network is not reachable.")
            case .reachable(let type):
                switch type {
                case .ethernetOrWiFi:
                    print("[Reachability] Network is reachable on Ethernet/WiFi.")
                case .cellular:
                    print("[Reachability] Network is reachable on cellular network.")
                }
            }
            // Notify
            if NetworkReachabilityManager.firstReachabilityChangeObserved {
                NotificationCenter.default.post(name: .reachabilityDidChange, object: nil)
            } else {
                NetworkReachabilityManager.firstReachabilityChangeObserved = true
            }
        }
    }
}

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

/// A `UINavigationController` concrete subclass that monitors changes to the app context's work mode
/// and adjusts the bar's tint color accordingly.
///
class AppContextAwareNavigationController: UINavigationController {
    
    private let changeHandler = AppContextChangeHandler()
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        
        subscribeToWorkModeChange()
        adjustNavigationBarTintForWorkMode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        subscribeToWorkModeChange()
        adjustNavigationBarTintForWorkMode()
    }
    
    private func adjustNavigationBarTintForWorkMode() {
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.contrasting]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.contrasting]
            navBarAppearance.backgroundColor = appContext.workMode == .online ? .primary : .offline
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
            navigationBar.compactAppearance = navBarAppearance
        }
        else {
            navigationBar.barTintColor = appContext.workMode == .online ? .primary : .offline
        }
        
        // Hiding then un-hiding the navigation bar appears to force a redraw.
        // This fixes an issue with iOS 13 where the background color doesn't update.
        isNavigationBarHidden = true
        isNavigationBarHidden = false
    }
    
    private func subscribeToWorkModeChange() {
        
        let workModeChange: AppContextChange = .workMode { [weak self] (_) in
            self?.adjustNavigationBarTintForWorkMode()
        }
        
        changeHandler.subscribe(toChange: workModeChange)
    }
}

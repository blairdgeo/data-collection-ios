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
import UIKit
import ArcGIS

protocol DrawerViewControllerDelegate: AnyObject {

    func drawerViewController(didRequestWorkOnline drawerViewController: DrawerViewController)
    func drawerViewController(didRequestLoginLogout drawerViewController: DrawerViewController)
    func drawerViewController(didRequestSyncJob drawerViewController: DrawerViewController)
    func drawerViewController(didRequestWorkOffline drawerViewController: DrawerViewController)
    func drawerViewController(didRequestDeleteMap drawerViewController: DrawerViewController)
}

class DrawerViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInBannerView: UIView!
    @IBOutlet weak var workOnlineButton: UIButton!
    @IBOutlet weak var workOfflineButton: UIButton!
    @IBOutlet weak var synchronizeOfflineMapButton: UIButton!
    @IBOutlet weak var deleteOfflineMapButton: UIButton!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    weak var delegate: DrawerViewControllerDelegate?
    
    private let changeHandler = AppContextChangeHandler()
    
    private let signInSignOutButtonControlStateColors: [UIControl.State: UIColor] = [.normal: .white, .highlighted: .gray]
    private let workModeControlStateColors: [UIControl.State: UIColor] = [.normal: .darkGray, .highlighted: .gray, .selected: .white, .disabled: UIColor(white: 0.5, alpha: 1)]
    private let offlineActivityControlStateColors: [UIControl.State: UIColor] = [.normal: .darkGray, .highlighted: .gray, .selected: .gray, .disabled: UIColor(white: 0.5, alpha: 1)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInBannerView.backgroundColor = .gray
        
        setAppVersionLabel()
        configureButtonTitleLabels()
        setButtonImageTints()
        setButtonAttributedTitles()
        subscribeToAppContextChanges()
    }
    
    private func setAppVersionLabel() {
        
        appVersionLabel.text = String(format: "%@\n%@", Bundle.AppNameVersionString, Bundle.ArcGISSDKVersionString)
    }
    
    private func configureButtonTitleLabels() {
        [signInButton, workOnlineButton, workOfflineButton, synchronizeOfflineMapButton, deleteOfflineMapButton].forEach { (button) in
            button!.titleLabel?.numberOfLines = 0
            button!.titleLabel?.adjustsFontForContentSizeCategory = true
            button!.titleLabel?.allowsDefaultTighteningForTruncation = true
            button!.titleLabel?.minimumScaleFactor = 0.5
        }
    }
    
    private func setButtonImageTints() {
        
        workOnlineButton.buildImagesWithTintColors(forControlStateColors: workModeControlStateColors)
        workOfflineButton.buildImagesWithTintColors(forControlStateColors: workModeControlStateColors)
        synchronizeOfflineMapButton.buildImagesWithTintColors(forControlStateColors: offlineActivityControlStateColors)
        deleteOfflineMapButton.buildImagesWithTintColors(forControlStateColors: offlineActivityControlStateColors)
    }
    
    private func setButtonAttributedTitles() {
        
        updateLoginButtonForAuthenticatedUsername(user: appContext.portal.user)
        workOnlineButton.setAttributed(header: (title: "Work Online", font: .drawerButtonHeader), forControlStateColors: workModeControlStateColors)
        workOfflineButton.setAttributed(header: (title: "Work Offline", font: .drawerButtonHeader), forControlStateColors: workModeControlStateColors)
        updateSynchronizeButtonForLastSync(date: appContext.mobileMapPackage?.lastSyncDate)
        deleteOfflineMapButton.setAttributed(header: (title: "Delete Offline Map", font: .drawerButtonHeader), forControlStateColors: offlineActivityControlStateColors)
    }
    
    @IBAction func userRequestsLoginLogout(_ sender: Any) {
        delegate?.drawerViewController(didRequestLoginLogout: self)
    }
    
    @IBAction func userRequestsWorkOnline(_ sender: Any) {
        
        guard appContext.workMode == .offline else {
            return
        }
        
        guard appReachability.isReachable else {
            present(simpleAlertMessage: "Your device must be connected to a network to work online.", animated: true, completion: nil)
            return
        }
        
        delegate?.drawerViewController(didRequestWorkOnline: self)
    }
    
    @IBAction func userRequestsWorkOffline(_ sender: Any) {
        
        guard appContext.workMode == .online else {
            return
        }
        
        if !appContext.hasOfflineMap && !appReachability.isReachable {
            present(simpleAlertMessage: "Your device must be connected to a network to work online.", animated: true, completion: nil)
            return
        }
        
        if !appContext.hasOfflineMap && !appContext.isCurrentMapLoaded {
            present(simpleAlertMessage: "Map must be loaded to work offline.", animated: true, completion: nil)
            return
        }

        delegate?.drawerViewController(didRequestWorkOffline: self)
    }
    
    @IBAction func userRequestsSynchronizeOfflineMap(_ sender: Any) {
        
        guard appReachability.isReachable else {
            present(simpleAlertMessage: "Your device must be connected to a network to synchronize the offline map.", animated: true, completion: nil)
            return
        }
        
        guard appContext.hasOfflineMap else {
            present(simpleAlertMessage: "Unknown Error: your device doesn't have an offline map.", animated: true, completion: nil)
            return
        }
        
        delegate?.drawerViewController(didRequestSyncJob: self)
    }
    
    @IBAction func userRequestsDeleteOfflineMap(_ sender: Any) {
        
        guard appContext.hasOfflineMap else {
            present(simpleAlertMessage: "Unknown Error: your device doesn't have an offline map.", animated: true, completion: nil)
            return
        }
        
        delegate?.drawerViewController(didRequestDeleteMap: self)
    }
    
    func adjustContextDrawerUI() {
        
        workOnlineButton.isEnabled = appContext.workMode == .offline ? appReachability.isReachable : true
        workOnlineButton.isSelected = appContext.workMode == .online
        workOnlineButton.backgroundColor = appContext.workMode == .online ? .accent : .clear

        if appReachability.isReachable {
            workOnlineButton.setAttributed(header: (title: appContext.workMode == .online ? "Working Online" : "Work Online", font: .drawerButtonHeader), forControlStateColors: workModeControlStateColors)
        }
        else {
            workOnlineButton.setAttributed(header: (title: appContext.workMode == .online ? "Working Online" : "Work Online", font: .drawerButtonHeader), subheader: (title: "no network connectivity", font: .drawerButtonSubheader) , forControlStateColors: workModeControlStateColors)
        }
        
        workOfflineButton.isEnabled = appContext.hasOfflineMap || appReachability.isReachable
        workOfflineButton.isSelected = appContext.workMode == .offline
        workOfflineButton.backgroundColor = appContext.workMode == .offline ? .accent : .clear
        
        if !appContext.hasOfflineMap {
            workOfflineButton.setAttributed(header: (title: appContext.workMode == .offline ? "Working Offline" : "Work Offline", font: .drawerButtonHeader),
                                            subheader: (title: "download map", font: .drawerButtonSubheader),
                                            forControlStateColors: workModeControlStateColors)
        }
        else {
            workOfflineButton.setAttributed(header: (title: appContext.workMode == .offline ? "Working Offline" : "Work Offline", font: .drawerButtonHeader),
                                            forControlStateColors: workModeControlStateColors)
        }

        synchronizeOfflineMapButton.isEnabled = appContext.hasOfflineMap && appReachability.isReachable
        synchronizeOfflineMapButton.isSelected = false
        
        deleteOfflineMapButton.isEnabled = appContext.hasOfflineMap
        deleteOfflineMapButton.isSelected = false
    }    
    
    private func updateLoginButtonForAuthenticatedUserProfileImage(user: AGSPortalUser?) {
        
        if let currentUser = user {
            
            let fallbackProfileImage = UIImage(named: "MissingProfile")!.withRenderingMode(.alwaysOriginal).circularThumbnail(ofSize: 36, stroke: (color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), weight: 1))
            
            guard let image = currentUser.thumbnail else {
                signInButton.setImage(fallbackProfileImage, for: .normal)
                return
            }
            
            image.load(completion: { [weak self] (error: Error?) in
                
                self?.signInButton.setImage(fallbackProfileImage, for: .normal)
                
                guard error == nil else {
                    print("[Error: User Thumbnail Image Load]", error!.localizedDescription)
                    return
                }
                
                guard let img = image.image, let profImage = img.circularThumbnail(ofSize: 36, stroke: (color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), weight: 1)) else {
                    print("[Error: User Thumbnail Image Load] image processing error.")
                    return
                }
                
                self?.signInButton.setImage(profImage.withRenderingMode(.alwaysOriginal), for: .normal)
            })
        }
        else {
            signInButton.setImage(UIImage(named: "UserLoginIcon"), for: .normal)
        }
    }
    
    private func updateLoginButtonForAuthenticatedUsername(user: AGSPortalUser?) {
        
        if let currentUser = user {
            signInButton.setAttributed(header: (title: currentUser.username ?? currentUser.email ?? "User", font: .drawerButtonHeader), subheader: (title: "Log out", font: .drawerButtonSubheader), forControlStateColors: signInSignOutButtonControlStateColors)
        }
        else {
            signInButton.setAttributed(header: (title: "Log in", font: .drawerButtonHeader), forControlStateColors: signInSignOutButtonControlStateColors)
        }
    }
    
    private func subscribeToAppContextChanges() {
        
        let currentPortalChange: AppContextChange = .currentPortal { [weak self] portal in
            self?.updateLoginButtonForAuthenticatedUserProfileImage(user: portal.user)
            self?.updateLoginButtonForAuthenticatedUsername(user: portal.user)
        }
        
        let workModeChange: AppContextChange = .workMode { [weak self] _ in
            self?.adjustContextDrawerUI()
        }
        
        let reachabilityChange: AppContextChange = .reachability { [weak self] _ in
            self?.adjustContextDrawerUI()
        }
        
        let lastSyncChange: AppContextChange = .lastSync { [weak self] date in
            self?.updateSynchronizeButtonForLastSync(date: date)
        }
        
        let hasOfflineMapChange: AppContextChange = .hasOfflineMap { [weak self] _ in
            self?.adjustContextDrawerUI()
        }
        
        changeHandler.subscribe(toChanges: [currentPortalChange, workModeChange, reachabilityChange, lastSyncChange, hasOfflineMapChange])
    }
    
    private func updateSynchronizeButtonForLastSync(date: Date?) {
        
        if let lastSynchronized = date {
            synchronizeOfflineMapButton.setAttributed(header: (title: "Synchronize Offline Map", font: .drawerButtonHeader),
                                                      subheader: (title: String(format: "last sync %@", AppDateFormatter.format(shortDateTime: lastSynchronized)), font: .drawerButtonSubheader),
                                                      forControlStateColors: offlineActivityControlStateColors)
        }
        else {
            synchronizeOfflineMapButton.setAttributed(header: (title: "Synchronize Offline Map", font: .drawerButtonHeader),
                                                      forControlStateColors: offlineActivityControlStateColors)
        }
    }
}


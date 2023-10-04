//
//  LivenessSDK.swift
//  LivenessSDK
//
//  Created by Anh Loc Mascom on 12/09/2023.
//

import Foundation
import UIKit

@objc public class LivienesSDK: NSObject {
    private override init() {}
    @objc public static let shared = LivienesSDK()
    
    @objc public func openSDKin(superView: UIView) {
        let vc = MainSDKViewController.instance()
        vc.view.frame = superView.bounds
        superView.addSubview(vc.view)
        
    }
}

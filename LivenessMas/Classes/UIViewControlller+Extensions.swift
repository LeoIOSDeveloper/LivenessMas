//
//  UIViewControlller+Extensions.swift
//  UnitelSDK
//
//  Created by admin on 1/18/21.
//

import UIKit

extension UIViewController {
    private static func getInstance<T: UIViewController>() -> T {
        let bundle = Bundle(identifier: "com.mascom.miniapp.sdk.Liveness")
        print("Bundle: ", bundle ?? "")
        return T.init(nibName: String(describing: self), bundle: bundle)
    }
    
    static func instance() -> Self {
        return getInstance()
    }
    
    func addDismissKeyboardGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

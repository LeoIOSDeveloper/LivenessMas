//
//  UIViewControlller+Extensions.swift
//  UnitelSDK
//
//  Created by admin on 1/18/21.
//

import UIKit

extension UIViewController {
    private static func getInstance<T: UIViewController>() -> T {
        return T.init(nibName: String(describing: self), bundle: Bundle(for: self))
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

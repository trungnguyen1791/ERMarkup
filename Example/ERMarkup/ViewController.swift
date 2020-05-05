//
//  ViewController.swift
//  ERMarkup
//
//  Created by trungnguyen1791 on 07/12/2019.
//  Copyright (c) 2019 trungnguyen1791. All rights reserved.
//

import UIKit
import ERMarkup

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(named: "test") {
            let vc = ERMarkupViewController(image: image)
            //        let vc = ERMarkupViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.present(nav, animated: true, completion: nil)
            }
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


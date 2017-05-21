//
//  WebViewController.swift
//  Single View Application
//
//  Created by txm on 2017/05/21.
//  Copyright © 2017年 txm. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    var itemUrl: String?
    
    @IBOutlet weak var webView: UIWebView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard let itemUrl = itemUrl else {
            return
        }
        
        guard let url = URL(string: itemUrl) else {
            return
        }
        
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

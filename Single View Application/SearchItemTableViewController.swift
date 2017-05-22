//
//  SearchItemTableViewController.swift
//  Single View Application
//
//  Created by txm on 2017/05/21.
//  Copyright © 2017年 txm. All rights reserved.
//

import UIKit

class SearchItemTableViewController: UITableViewController, UISearchBarDelegate {

    var itemDataArray: [ItemData] = [ItemData]()
    var imageCache = NSCache<AnyObject, UIImage>()
    var lockScreen: Bool = false
    
    var inputText: String = ""
    let queryLimit: Int = 50
    var queryOffset: Int = 0
    var oldOffset: Int = 0
    let entryUrl: String = "https://api.photozou.jp/rest/search_public.json"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemDataArray.count
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let inputText = searchBar.text else{
            // No input
            return
        }
        guard inputText.lengthOfBytes(using: String.Encoding.utf8) > 0 else{
            // Input text <= 0
            return
        }

        // Delete all data
        itemDataArray.removeAll()
        
        // Initialize offset
        queryOffset = 0;

        // Set parameter for query
        let parameter = ["keyword": inputText, "limit": String(queryLimit), "offset": String(queryOffset)]
        
        //Create URL with encoded parameter
        let requestUrl = createRequestUrl(parameter: parameter)
        
        // Request API
        request(requestUrl: requestUrl)
        
        self.inputText = inputText
        
        // Close key board
        searchBar.resignFirstResponder()
        
    }
    
    //URL encoding of parameter
    func encodeParameter(key: String, value: String) -> String? {
        guard let escapedValue = value.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                // Fail to encode
                return nil
        }
        let param: String = "\(key)=\(escapedValue)"
        return param
    }
    
    // Create URL
    func createRequestUrl(parameter: [String: String]) -> String {
        var parameterString = ""
        for key in parameter.keys {
            guard let value = parameter[key] else {
                continue
            }
            
            if parameterString.lengthOfBytes(using: String.Encoding.utf8) > 0 {
                parameterString += "&"
            }
            
            guard let encodedValue = encodeParameter(key: key, value: value) else {
                continue
            }
            
            parameterString += encodedValue
        }
        let requestUrl = entryUrl + "?" + parameterString
        return requestUrl
    }
    
    // Do request
    func request(requestUrl: String) {
        
        if (lockScreen) {
            return;
        }
        lockScreen = true;
        
        // Create URL
        guard let url: URL = URL(string: requestUrl) else {
            // Fail to create URL
            self.lockScreen = false;
            return
        }
        
        // Create a request
        let request = URLRequest(url: url)
        
        // Call WebAPI
        let session = URLSession.shared
        let task = session.dataTask(with: request) {
            (data:Data?, response:URLResponse?, error:Error?) in
            
            //Error check
            guard error == nil else {
                let alert = UIAlertController(title: "Error",
                                              message: error?.localizedDescription,
                                              preferredStyle: UIAlertControllerStyle.alert)
            
                // Do any work on UI thread
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                    self.lockScreen = false;
                }
                return
            }
            
             guard let data = data else {
                // No data
                self.lockScreen = false;
                return
            }
            
            // Convert to JSON
            guard let jsonData = try! JSONSerialization.jsonObject(
                with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else {
                        // Fail to convert
                        self.lockScreen = false;
                        return
            }
            
           guard let info = jsonData["info"] as? [String: Any] else {
                // No data
                self.lockScreen = false;
                return
            }
                        
            guard let photo: [[String: Any]] = info["photo"] as? [[String: Any]] else {
                self.lockScreen = false;
                return
            }
            
            for i in 0..<photo.count {
                let itemData = ItemData()
                
                let targetPhoto: [String: Any] = (photo[i] )
                
                let targetTitle: String = (targetPhoto["photo_title"] as! String)
                let view_num: Int = (targetPhoto["view_num"] as! Int)
                let targetPhotoImageURL: String = (targetPhoto["image_url"] as! String)
                let targetThumnailURL: String = (targetPhoto["thumbnail_image_url"] as! String)
                
                itemData.itemImageUrl = targetThumnailURL
                itemData.itemUrl = targetPhotoImageURL
                itemData.itemTitle = targetTitle
                itemData.itemAccess = String(view_num)
                
                //Add to the list
                self.itemDataArray.append(itemData)
            }
            
            self.oldOffset = self.queryOffset;
            self.queryOffset = self.oldOffset + self.queryLimit;
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.lockScreen = false;
            }
        }
        
        // Start
        task.resume()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemTableViewCell else {
            return UITableViewCell()
        }

        // Configure the cell...
        let itemData = itemDataArray[indexPath.row]
        
        // Title
        cell.itemTitleLabel.text = itemData.itemTitle
        
        // Access number
        cell.itemPriceLabel.text = itemData.itemAccess

        // URL
        cell.itemUrl = itemData.itemUrl
        
        guard let itemImageUrl = itemData.itemImageUrl else {
            // No picture but return cell
            return cell
        }
        
        // Use cache if exists
        if let cacheImage = imageCache.object(forKey: itemImageUrl as AnyObject) {
            cell.itemImageView.image = cacheImage
            return cell
        }
        
        // In case of no cache, download image
        guard let url = URL(string: itemImageUrl) else {
            return cell
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            guard let image = UIImage(data: data) else {
                // Couldn't create an image from data
                return
            }
            
            // Add downloaded image to cache.
            self.imageCache.setObject(image, forKey: itemImageUrl as AnyObject)
            
            DispatchQueue.main.async {
                cell.itemImageView.image = image
            }
        }
        task.resume()
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let cell = sender as? ItemTableViewCell {
            if let webViewController = segue.destination as? WebViewController {
                webViewController.itemUrl = cell.itemUrl
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if tableView.contentOffset.y + tableView.frame.size.height > tableView.contentSize.height && tableView.isDragging {
            // Set parameter for query
            let parameter = ["keyword": inputText, "limit": String(queryLimit), "offset": String(queryOffset + 1)]
            
            //Create URL with encoded parameter
            let requestUrl = createRequestUrl(parameter: parameter)
            
            // Request API
            request(requestUrl: requestUrl)
            
        }
    }
}

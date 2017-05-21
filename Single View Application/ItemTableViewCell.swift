//
//  ItemTableViewCell.swift
//  Single View Application
//
//  Created by txm on 2017/05/21.
//  Copyright © 2017年 txm. All rights reserved.
//

import UIKit

class ItemTableViewCell: UITableViewCell {

    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    
    var itemUrl: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        itemImageView.image = nil
    }

}

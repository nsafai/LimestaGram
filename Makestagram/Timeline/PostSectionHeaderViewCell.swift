//
//  PostSectionHeaderViewCell.swift
//  Makestagram
//
//  Created by Nicolai Safai on 7/27/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import UIKit

class PostSectionHeaderViewCell: UITableViewCell {


    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var postTimeLabel: UILabel!
    
    var post: Post? {
        didSet {
            if let post = post {
                usernameLabel.text = post.user?.username
                // 1
                postTimeLabel.text = post.createdAt?.shortTimeAgoSinceDate(NSDate()) ?? ""
            }
        }
    }}

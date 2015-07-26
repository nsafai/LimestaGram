//
//  ParseHelperTableViewCell.swift
//  Makestagram
//
//  Created by Nicolai Safai on 7/23/15.
//  Copyright (c) 2015 Make School. All rights reserved.
//

import Foundation
import Parse

// 1
class ParseHelper {
    
    // 1
    static func timelineRequestforCurrentUser(range: Range<Int>, completionBlock: PFArrayResultBlock) {
        let followingQuery = PFQuery(className: ParseFollowClass)
        followingQuery.whereKey(ParseLikeFromUser, equalTo:PFUser.currentUser()!)
        
        let postsFromFollowedUsers = Post.query()
        postsFromFollowedUsers!.whereKey(ParsePostUser, matchesKey: ParseFollowToUser, inQuery: followingQuery)
        
        let postsFromThisUser = Post.query()
        postsFromThisUser!.whereKey(ParsePostUser, equalTo: PFUser.currentUser()!)
        
        let query = PFQuery.orQueryWithSubqueries([postsFromFollowedUsers!, postsFromThisUser!])
        query.includeKey(ParsePostUser)
        query.orderByDescending(ParsePostCreatedAt)
        
        // 2
        query.skip = range.startIndex
        // 3
        query.limit = range.endIndex - range.startIndex
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    // Creating Likes
    static func likePost(user: PFUser, post: Post) { // the method takes a PFUser and a Post reference.
        let likeObject = PFObject(className: ParseLikeClass)
        // Then it generates a likeObject based on these two input parameters and saves it.
        likeObject[ParseLikeFromUser] = user
        likeObject[ParseLikeToPost] = post
        
        likeObject.saveInBackgroundWithBlock(nil)
    }
    
    // Deleting Likes
    static func unlikePost(user: PFUser, post: Post) {
        // 1 We build a query to find the like of a given user that belongs to a given post
        let query = PFQuery(className: ParseLikeClass)
        query.whereKey(ParseLikeFromUser, equalTo: user)
        query.whereKey(ParseLikeToPost, equalTo: post)
        
        query.findObjectsInBackgroundWithBlock {
            (results: [AnyObject]?, error: NSError?) -> Void in
            // 2 We iterate over all like objects that met our requirements and delete them.
            if let results = results as? [PFObject] {
                for likes in results {
                    likes.deleteInBackgroundWithBlock(nil)
                }
            }
        }
    }
    
    // Fetching Likes
    // Our method is taking a PFArrayResultBlock as an argument. We've used the same approach in our timelineRequestforCurrentUser method. The PFArrayResultBlock has the following signature: ww([AnyObject]?, NSError?) -> Void That's the default signature for the callback of most Parse queries. It takes an optional result and an optional error. By taking this type of block as an argument, we can hand it directly to the findObjectsInBackgroundWithBlock method! This way, whoever has called the likesForPost method will get the results in the callback block that they provide.
    static func likesForPost(post: Post, completionBlock: PFArrayResultBlock) {
        let query = PFQuery(className: ParseLikeClass)
        query.whereKey(ParseLikeToPost, equalTo: post)
        // 2
        query.includeKey(ParseLikeFromUser)
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
        
        // Following Relation
        static let ParseFollowClass       = "Follow"
        static let ParseFollowFromUser    = "fromUser"
        static let ParseFollowToUser      = "toUser"
        
        // Like Relation
        static let ParseLikeClass         = "Like"
        static let ParseLikeToPost        = "toPost"
        static let ParseLikeFromUser      = "fromUser"
        
        // Post Relation
        static let ParsePostUser          = "user"
        static let ParsePostCreatedAt     = "createdAt"
        
        // Flagged Content Relation
        static let ParseFlaggedContentClass    = "FlaggedContent"
        static let ParseFlaggedContentFromUser = "fromUser"
        static let ParseFlaggedContentToPost   = "toPost"
        
        // User Relation
        static let ParseUserUsername      = "username"
        
        // ...
}

extension PFObject : Equatable {
    
}

public func ==(lhs: PFObject, rhs: PFObject) -> Bool {
    return lhs.objectId == rhs.objectId
}
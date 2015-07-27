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
    
    //Deleting Likes
    static func unlikePost(user: PFUser, post: Post) {
        let query = PFQuery(className: ParseLikeClass)
        query.whereKey(ParseLikeFromUser, equalTo: user)
        query.whereKey(ParseLikeToPost, equalTo: post)
        
        query.findObjectsInBackgroundWithBlock {
            (results: [AnyObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorHandling.defaultErrorHandler(error)
            }
            
            if let results = results as? [PFObject] {
                for likes in results {
                    likes.deleteInBackgroundWithBlock(ErrorHandling.errorHandlingCallback)
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
    
    // MARK: Following
    
    /**
    Fetches all users that the provided user is following.
    
    :param: user The user whose followees you want to retrieve
    :param: completionBlock The completion block that is called when the query completes
    */
    static func getFollowingUsersForUser(user: PFUser, completionBlock: PFArrayResultBlock) {
        let query = PFQuery(className: ParseFollowClass)
        
        query.whereKey(ParseFollowFromUser, equalTo:user)
        query.findObjectsInBackgroundWithBlock(completionBlock)
    }
    
    /**
    Establishes a follow relationship between two users.
    
    :param: user    The user that is following
    :param: toUser  The user that is being followed
    */
    static func addFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let followObject = PFObject(className: ParseFollowClass)
        followObject.setObject(user, forKey: ParseFollowFromUser)
        followObject.setObject(toUser, forKey: ParseFollowToUser)
        
        followObject.saveInBackgroundWithBlock(nil)
    }
    
    /**
    Deletes a follow relationship between two users.
    
    :param: user    The user that is following
    :param: toUser  The user that is being followed
    */
    static func removeFollowRelationshipFromUser(user: PFUser, toUser: PFUser) {
        let query = PFQuery(className: ParseFollowClass)
        query.whereKey(ParseFollowFromUser, equalTo:user)
        query.whereKey(ParseFollowToUser, equalTo: toUser)
        
        query.findObjectsInBackgroundWithBlock {
            (results: [AnyObject]?, error: NSError?) -> Void in
            
            let results = results as? [PFObject] ?? []
            
            for follow in results {
                follow.deleteInBackgroundWithBlock(nil)
            }
        }
    }
    
    // MARK: Users
    
    /**
    Fetch all users, except the one that's currently signed in.
    Limits the amount of users returned to 20.
    
    :param: completionBlock The completion block that is called when the query completes
    
    :returns: The generated PFQuery
    */
    static func allUsers(completionBlock: PFArrayResultBlock) -> PFQuery {
        let query = PFUser.query()!
        // exclude the current user
        query.whereKey(ParseHelper.ParseUserUsername,
            notEqualTo: PFUser.currentUser()!.username!)
        query.orderByAscending(ParseHelper.ParseUserUsername)
        query.limit = 20
        
        query.findObjectsInBackgroundWithBlock(completionBlock)
        
        return query
    }
    
    /**
    Fetch users whose usernames match the provided search term.
    
    :param: searchText The text that should be used to search for users
    :param: completionBlock The completion block that is called when the query completes
    
    :returns: The generated PFQuery
    */
    static func searchUsers(searchText: String, completionBlock: PFArrayResultBlock)
        -> PFQuery {
            /*
            NOTE: We are using a Regex to allow for a case insensitive compare of usernames.
            Regex can be slow on large datasets. For large amount of data it's better to store
            lowercased username in a separate column and perform a regular string compare.
            */
            let query = PFUser.query()!.whereKey(ParseHelper.ParseUserUsername,
                matchesRegex: searchText, modifiers: "i")
            
            query.whereKey(ParseHelper.ParseUserUsername,
                notEqualTo: PFUser.currentUser()!.username!)
            
            query.orderByAscending(ParseHelper.ParseUserUsername)
            query.limit = 20
            
            query.findObjectsInBackgroundWithBlock(completionBlock)
            
            return query
    }
    
}

extension PFObject : Equatable {
    
}

public func ==(lhs: PFObject, rhs: PFObject) -> Bool {
    return lhs.objectId == rhs.objectId
}
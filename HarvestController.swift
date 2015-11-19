//
//  HarvestController.swift
//  HarvestKit
//
//  Created by Matthew Cheetham on 19/11/2015.
//  Copyright © 2015 Matt Cheetham. All rights reserved.
//

#if os(iOS)
    import ThunderRequest
#elseif os(tvOS)
    import ThunderRequestTV
#else
    
#endif

/**
The Harvest controller is responsible for all interactions with the Harvest API. It must be initialised with a TSCRequestCredential containing the API username and password
*/
public class HarvestController {
    
    let requestController: TSCRequestController
    
    /**
    Initialises a new harvest controller with the given credential. You must supply a credential to correctly initialise.
     
    - parameters:
        - accountName: The name of the account as used when logging into the website as 'https://xxxx.harvestapp.com' where xxxx is your account name
        - credential: A TSCRequestCredential initialised with an email address and password
    */
    public init(accountName: String!, credential: TSCRequestCredential!) {
        
        requestController = TSCRequestController(baseAddress: "https://\(accountName).harvestapp.com")

        requestController.sharedRequestCredential = credential
        requestController.sharedRequestHeaders["Accept"] = "application/json"
        
    }
    
    /**
    Gets all registered users for the given account
    
    - parameters:
        - completionHandler: The completion handler to return users and errors to
    */
    public func getUsers(completionHandler: (users: [User]?, requestError: NSError?) -> ()) {
        
        requestController.get("people") { (response: TSCRequestResponse?, requestError: NSError?) -> Void in
        
            if let error = requestError {
                completionHandler(users: nil, requestError: error)
                return;
            }
            
            if let usersArray = response?.array as? [[String: AnyObject]] {
                
                let users = usersArray.map({
                    
                    User(dictionary: $0)
                    
                })
                
                completionHandler(users: users, requestError: nil)
                
            }
            
        }
        
    }
    
    /**
    Gets timers for a user for the current day
     
    - parameters:
        - user: The user to look up the data for
        - completionHandler: The completion handler to return timers and errors to
    */
    public func getTimers(user: User?, completionHandler: (timers: [Timer]?, requestError: NSError?) -> ()) {
        
        guard let givenUser = user, let userId = givenUser.identifier else {
            let error = NSError(domain: "co.uk.mattcheetham.harvestkit", code: 1000, userInfo: [NSLocalizedDescriptionKey: "No user supplied or user did not have an ID"])
            completionHandler(timers: nil, requestError: error)
            return
        }
        
        requestController.get("daily?of_user=#(:userIdentifier)", withURLParamDictionary: ["userIdentifier":userId]) { (response: TSCRequestResponse?, requestError: NSError?) -> Void in
            
            if let error = requestError {
                completionHandler(timers: nil, requestError: error)
                return;
            }
            
            if let timerResponseDictionary = response?.dictionary as? [String: AnyObject], let timerEntriesArray = timerResponseDictionary["day_entries"] as? [[String: AnyObject]] {
                
                let timersArray = timerEntriesArray.map({
                    Timer(dictionary: $0)
                })
                
                completionHandler(timers: timersArray, requestError: nil)
                
            }
            
        }
    }
    
    /**
    Gets projects for the account
     
    - parameters:
        - completionHandler: The completion handler to return projects and errors to
    */
    public func getProjects(completionHandler: (projects: [Project]?, requestError: NSError?) -> ()) {
        
        requestController.get("projects") { (response: TSCRequestResponse?, requestError: NSError?) -> Void in
            
            if let error = requestError {
                completionHandler(projects: nil, requestError: error)
                return;
            }
            
            if let projectsArray = response?.array as? [[String: AnyObject]] {
             
                let projects = projectsArray.map({
                    Project(dictionary: $0)
                })
                
                completionHandler(projects: projects, requestError: nil)
            }
            
        }
        
    }
    
    /**
    Gets clients for the account
    
    - parameters:
        - completionHandler: The completion handler to return clients and errors to
    */
    public func getClients(completionHandler: (clients: [Client]?, requestError: NSError?) -> ()) {
        
        requestController.get("clients") { (response: TSCRequestResponse?, requestError: NSError?) -> Void in
            
            if let error = requestError {
                completionHandler(clients: nil, requestError: error)
                return;
            }
            
            if let clientsArray = response?.array as? [[String: AnyObject]] {
                
                let clients = clientsArray.map({
                    Client(dictionary: $0)
                })
                
                completionHandler(clients: clients, requestError: nil)
            }
            
        }
        
    }
}

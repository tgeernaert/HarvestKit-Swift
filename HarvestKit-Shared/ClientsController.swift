//
//  ClientController.swift
//  HarvestKit
//
//  Created by Matthew Cheetham on 06/05/2016.
//  Copyright © 2016 Matt Cheetham. All rights reserved.
//

import Foundation

#if os(iOS)
    import ThunderRequest
#elseif os(tvOS)
    import ThunderRequestTV
#elseif os (OSX)
    import ThunderRequestMac
#endif

/** The client controller is responsible for adding, deleting and updating client information with the Harvest API. This controller will only work if your account has the client module enabled
 */
public final class ClientsController {
    
    /**
     The request controller used to load contact information. This is shared with other controllers
     */
    let requestController: TSCRequestController
    
    /**
     Initialises a new controller.
     - parameter requestController: The request controller to use when loading client information. This must be passed down from HarvestController so that authentication may be shared
     */
    internal init(requestController: TSCRequestController) {
        
        self.requestController = requestController
    }
    
    //MARK - Creating Clients
    
    /**
     Creates a new client entry in the Harvest system. You may configure any of the parameters on the contact object you are creating and they will be saved.
     
     - parameter client: The new client object to send to the API
     - parameter completion: The completion handler to return any errors to
     - requires: `name` on the client object as a minimum
     */
    public func create(client: Client, completion: (error: ErrorType?) -> ()) {
        
        guard let _ = client.name else {
            completion(error: ClientError.MissingName)
            return
        }
        
        requestController.post("clients", bodyParams: client.serialisedObject) { (response: TSCRequestResponse?, error: NSError?) in
            
            if let _error = error {
                completion(error: _error)
                return
            }
            
            if let responseStatus = response?.status where responseStatus == 201 {
                completion(error: nil)
                return
            }
            
            completion(error: ClientError.UnexpectedResponseCode)
        }
    }
    
    //MARK - Requesting Clients
    
    /**
     Requests a specific client from the API by identifier
     
     - parameter clientIdentifier: The identifier of the client to look up in the system
     */
    public func get(clientIdentifier: Int, completion: (client: Client?, error: ErrorType?) -> ()) {
        
        requestController.get("clients/\(clientIdentifier)") { (response: TSCRequestResponse?, error: NSError?) in
            
            if let _error = error {
                completion(client: nil, error: _error)
                return
            }
            
            if let responseDictionary = response?.dictionary as? [String: AnyObject] {
                
                let returnedClient = Client(dictionary: responseDictionary)
                completion(client: returnedClient, error: nil)
                return
            }
            
            completion(client: nil, error: ClientError.MalformedData)
        }
    }
    
    /**
     Requests all clients in the system for this company
     
     - parameter completion: A closure to call with an optional array of `clients` and an optional `error`
     */
    public func getClients(completion: (clients: [Client]?, error: ErrorType?) -> ()) {
        
        requestController.get("clients") { (response: TSCRequestResponse?, error: NSError?) in
            
            if let _error = error {
                completion(clients: nil, error: _error)
                return
            }
            
            if let responseArray = response?.array as? [[String: AnyObject]] {
                
                let returnedClients = responseArray.flatMap({Client(dictionary: $0)})
                completion(clients: returnedClients, error: nil)
                return
            }
            
            completion(clients: nil, error: ClientError.MalformedData)
        }
    }
    
    //MARK - Modifying Clients
    
    /**
     Updates a client in the API. Any properties set on the client object will be sent to the server in an attempt to overwrite them. Not all properties are modifyable but Harvest does not make it clear which are so for now it will attempt all of them
     
     - parameter client: The client object to update
     - parameter completion: The closure to call to return any errors to or indicate success
     - requires: `identifier` on the client object as a minimum
     */
    public func update(client: Client, completion: (error: ErrorType?) -> ()) {
        
        guard let clientIdentifier = client.identifier else {
            completion(error: ClientError.MissingIdentifier)
            return
        }
        
        requestController.put("clients/\(clientIdentifier)", bodyParams: client.serialisedObject) { (response: TSCRequestResponse?, error: NSError?) in
            
            if let _error = error {
                completion(error: _error)
                return
            }
            
            if let responseStatus = response?.status where responseStatus == 200 {
                completion(error: nil)
                return
            }
            
            completion(error: ClientError.UnexpectedResponseCode)
        }
        
    }
    
    /**
     Deletes a client from the Harvest API.
     
     - parameter client: The client to delete in the API
     - parameter completion: The closure to call with potential errors
     - requires: `identifier` on the client object as a minimum
     - note: You will not be able to delete a client if they have assosciated projects or invoices
     */
    public func delete(client: Client, completion: (error: ErrorType?) -> ()) {
        
        guard let clientIdentifier = client.identifier else {
            completion(error: ClientError.MissingIdentifier)
            return
        }
        
        requestController.delete("clients/\(clientIdentifier)") { (response: TSCRequestResponse?, error: NSError?) in
            
            if let _error = error {
                
                if let responseStatus = response?.status where responseStatus == 400 {
                    completion(error: ClientError.HasProjectsOrInvoices)
                    return
                }
                
                completion(error: _error)
                return
            }
            
            if let responseStatus = response?.status where responseStatus == 200 {
                completion(error: nil)
                return
            }
            
            completion(error: ClientError.UnexpectedResponseCode)
        }
        
    }
    
    /**
     Toggles the active status of a client.
     
     - parameter client: The client to toggle the active status of in the API
     - parameter completion: The closure to call with potential errors
     - requires: `identifier` on the client object as a minimum
     - note: You will not be able to toggle a client if they have active projects
     */
    public func toggle(client: Client, completion: (error: ErrorType?) -> ()) {
        
        guard let clientIdentifier = client.identifier else {
            completion(error: ClientError.MissingIdentifier)
            return
        }
        
        requestController.post("clients/\(clientIdentifier)/toggle", bodyParams: nil) { (response: TSCRequestResponse?, error: NSError?) in
            
            if let _error = error {
                
                if let responseStatus = response?.status where responseStatus == 400 {
                    completion(error: ClientError.HasActiveProjects)
                    return
                }
                
                completion(error: _error)
                return
            }
            
            if let responseStatus = response?.status where responseStatus == 200 {
                completion(error: nil)
                return
            }
            
            completion(error: ClientError.UnexpectedResponseCode)
        }
    }
}

/** An enum detailing the errors possible when dealing with client data */
enum ClientError: ErrorType {
    /** The data we got back from the server was not suitable to be converted into a client object */
    case MalformedData
    /** The client object given did not have a name set so could not be saved */
    case MissingName
    /** The client object given did not have an identifier so cannot be updated in the system */
    case MissingIdentifier
    /** We got an unexpected response */
    case UnexpectedResponseCode
    /** The client has assosciated projects or invoices and cannot be deleted */
    case HasProjectsOrInvoices
    /** The client has active projects and cannot be disabled */
    case HasActiveProjects
}
//
//  GuidedMeditationsRequest.swift
//  RinglyAPI
//
//  Created by Daniel Katz on 5/11/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit


    public class GuidedMeditationsRequest {
        public init() {}
    }
    
    extension GuidedMeditationsRequest: RequestProviding, ResponseProcessing {
        // MARK: - Request
        public func request(for baseURL: URL) -> URLRequest?
        {
            return URLRequest(method: .get, baseURL: baseURL, relativeURLString: "guided-meditations", queryItems: nil)
        }
        
        public typealias Output = GuidedMeditationResult
    } 
    



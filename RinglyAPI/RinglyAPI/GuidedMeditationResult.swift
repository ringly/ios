//
//  GuidedMeditation.swift
//  RinglyAPI
//
//  Created by Daniel Katz on 5/11/17.
//  Copyright © 2017 Ringly. All rights reserved.
//

import UIKit

public struct GuidedMeditationResult: Equatable {
    public let meditations: [GuidedMeditation]
}

extension GuidedMeditationResult: Decoding {
    // MARK: - Decodable
    public typealias Encoded = [[String:AnyObject]]
    
    public static func decode(_ encoded: Encoded) throws -> GuidedMeditationResult
    {
        let guidedMeditations = try encoded.map(GuidedMeditation.decode)
        
        return GuidedMeditationResult(
            meditations: guidedMeditations
        )
    }
}

public func ==(lhs: GuidedMeditationResult, rhs: GuidedMeditationResult) -> Bool
{
    return lhs.meditations == rhs.meditations
}

public struct GuidedMeditation: Equatable {
    public let title:String
    public let subtitle:String
    public let sessionDescription:String
    public let audioFile: URL
    fileprivate let iconImage1x: URL
    fileprivate let iconImage2x: URL
    fileprivate let iconImage3x: URL
    public let lengthSeconds: Int
    public let author: GuidedAudioAuthor?
    
    public var iconUrl: URL {
        if UIScreen.main.scale == 1 {
            return self.iconImage1x
        } else if UIScreen.main.scale == 2 {
            return self.iconImage2x
        } else if UIScreen.main.scale == 3 {
            return self.iconImage3x
        } else {
            return self.iconImage2x
        }
    }
}

public struct GuidedAudioAuthor: Equatable {
    public let name:String
    public let image:URL
}

public func ==(lhs: GuidedAudioAuthor, rhs: GuidedAudioAuthor) -> Bool
{
    return lhs.name == rhs.name && lhs.image == rhs.image
}

extension GuidedAudioAuthor: Coding {
    // MARK: - Codable
    public typealias Encoded = [String:Any]
    
    public static func decode(_ encoded: Encoded) throws -> GuidedAudioAuthor
    {
        return GuidedAudioAuthor(
            name: try encoded.decode("name"),
            image: try encoded.decodeURL("image")
        )
    }
    
    public var encoded: Encoded
    {
        return [
            "name": name,
            "image": image
        ]
    }
}

extension GuidedMeditation: Coding
{
    // MARK: - Codable
    public typealias Encoded = [String:Any]
    
    public static func decode(_ encoded: Encoded) throws -> GuidedMeditation
    {
        return GuidedMeditation(
            title: try encoded.decode("title"),
            subtitle: try encoded.decode("subtitle"),
            sessionDescription: try encoded.decode("description"),
            audioFile: try encoded.decodeURL("audio_file"),
            iconImage1x: try encoded.decodeURL("icon_image_1x"),
            iconImage2x: try encoded.decodeURL("icon_image_2x"),
            iconImage3x: try encoded.decodeURL("icon_image_3x"),
            lengthSeconds: try encoded.decode("length_seconds"),
            author: try GuidedAudioAuthor.decode(encoded["author"] as! GuidedAudioAuthor.Encoded)
        )
    }
    
    public var encoded: Encoded
    {
        return [
            "audio_file": audioFile,
            "icon_image_1x": iconImage1x,
            "icon_image_2x": iconImage2x,
            "icon_image_3x": iconImage3x,
            "length_seconds": lengthSeconds,
            "description": sessionDescription,
            "subtitle": subtitle,
            "title": title,
            "author": author
        ]
    }
}

public func ==(lhs: GuidedMeditation, rhs: GuidedMeditation) -> Bool
{
    return lhs.audioFile == rhs.audioFile && lhs.title == rhs.title
}

//
//  Track.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//

import Foundation

struct Track: Identifiable, Codable, TrackProtocol {
    let id: String
    let title: String
    let artist: String
    let thumbnailURL: String
    let videoId: String
    let durationISO8601: String
}

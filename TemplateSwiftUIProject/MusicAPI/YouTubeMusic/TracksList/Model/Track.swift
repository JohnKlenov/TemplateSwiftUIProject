//
//  Track.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//


//  Модель трека с поддержкой воспроизведения



import Foundation

struct Track: Identifiable, Codable, TrackProtocol {
    let id: String
    let title: String
    let artist: String
    let thumbnailURL: String
    let videoId: String
    let durationISO8601: String
}

// MARK: - Расширение для отображения продолжительности
extension Track {
    var formattedDuration: String {
        // Парсим ISO8601 длительность (формат "PT3M45S")
        let isoString = durationISO8601
        var minutes = 0
        var seconds = 0
        
        let pattern = "PT(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: isoString, range: NSRange(isoString.startIndex..., in: isoString)) {
            
            if let minuteRange = Range(match.range(at: 2), in: isoString) {
                minutes = Int(isoString[minuteRange]) ?? 0
            }
            if let secondRange = Range(match.range(at: 3), in: isoString) {
                seconds = Int(isoString[secondRange]) ?? 0
            }
        }
        
        return String(format: "%d:%02d", minutes, seconds)
    }
}



// MARK: - not PlaylistTrackRow

//struct Track: Identifiable, Codable, TrackProtocol {
//    let id: String
//    let title: String
//    let artist: String
//    let thumbnailURL: String
//    let videoId: String
//    let durationISO8601: String
//}

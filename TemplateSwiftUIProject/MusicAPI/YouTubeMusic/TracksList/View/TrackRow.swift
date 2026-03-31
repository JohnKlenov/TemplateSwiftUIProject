//
//  TrackRow.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//

import SwiftUI

struct TrackRow<T: TrackProtocol>: View {
    let track: T
    let onPlusTap: () -> Void

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: track.thumbnailURL)) { img in
                img.resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onPlusTap) {
                Image(systemName: "plus.circle")
                    .font(.title2)
            }
        }
        .padding(.vertical, 6)
    }
}


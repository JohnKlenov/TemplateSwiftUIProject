//
//  LibraryContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 21.11.2026.
//


import SwiftUI

struct LibraryContentView: View {

    // MARK: - Environment

    @EnvironmentObject private var localization: LocalizationService

    // MARK: - ViewModel

    @ObservedObject var viewModel: LibraryContentViewModel

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: 28
            ) {
                collectionSection
                genresSection
                otherSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var collectionSection: some View {
        librarySection(
            title: "Collection",
            items: [
                LibraryItem(title: "All Tracks", destination: .allTracks),
                LibraryItem(title: "DropTop", destination: .topDrops),
                LibraryItem(title: "Artists", destination: .artists)
            ]
        )
    }

    private var genresSection: some View {
        librarySection(
            title: "Genres",
            items: [
                LibraryItem(title: "Gym", destination: .gym),
                LibraryItem(title: "Party", destination: .party),
                LibraryItem(title: "R&B", destination: .rnb)
            ]
        )
    }

    private var otherSection: some View {
        librarySection(
            title: "Other",
            items: [
                LibraryItem(title: "Unpublished", destination: .unpublished)
            ]
        )
    }

    // MARK: - Section Builder

    private func librarySection(
        title: String,
        items: [LibraryItem]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.primary)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    libraryRow(item)

                    if item.id != items.last?.id {
                        Divider()
                    }
                }
            }
            .background(AppColors.secondarySystemBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
        }
    }

    // MARK: - Row

    private func libraryRow(
        _ item: LibraryItem
    ) -> some View {
        Button {
            // Навигация будет добавлена через Coordinator.
        } label: {
            HStack {
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(AppColors.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Item

private struct LibraryItem: Identifiable {

    let title: String
    let destination: DroplistFlow

    var id: String { title }
}

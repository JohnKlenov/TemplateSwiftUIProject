//
//  DropTopContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//


import SwiftUI

struct DropTopContentView: View {

    @ObservedObject var viewModel: DropTopViewModel

    @EnvironmentObject var droplistCoordinator: DroplistCoordinator

    var body: some View {
        VStack(spacing: 0) {
            tagSelector

            Divider()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.background)
        .navigationTitle("DropTop")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            Task {
                await viewModel.setupViewModel()
            }
        }
    }
}

// =================================================
// MARK: - TAG SELECTOR
// =================================================

private extension DropTopContentView {

    var tagSelector: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(DropTopTag.allCases) { tag in
                    Button {
                        print("tag - \(tag)")

                        Task {
                            await viewModel.selectTag(tag)
                        }
                    } label: {
                        Text(tag.title)
                            .font(
                                .subheadline.weight(
                                    .medium
                                )
                            )
                            .foregroundColor(
                                viewModel.selectedTag == tag
                                    ? .white
                                    : .primary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(
                                        viewModel.selectedTag == tag
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.12)
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// =================================================
// MARK: - CONTENT
// =================================================

private extension DropTopContentView {

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {

        case .loading:
            ProgressView()

        case .error(let error):
            ContentErrorView(error: error) {
                Task {
                    await viewModel.retry()
                }
            }

        case .contentList(let page):
            dropTopList(page)
        }
    }
}

// =================================================
// MARK: - LIST
// =================================================

private extension DropTopContentView {

    func dropTopList(
        _ page: DropTopPage
    ) -> some View {
        ScrollView {
            LazyVStack(
                spacing: 0
            ) {
                ForEach(page.items) { item in
                    dropTopRow(item)
                        .onAppear {
                            guard item.id == page.items.last?.id else {
                                return
                            }

                            print(
                                "onAppear - viewModel.loadNextPage()"
                            )

                            viewModel.loadNextPage()
                        }
                }

                if page.hasMore {
                    ProgressView()
                        .padding(.vertical, 20)
                }
            }
        }
        .refreshable {
            await viewModel.retry()
        }
    }
}

// =================================================
// MARK: - ROW
// =================================================

private extension DropTopContentView {

    func dropTopRow(
        _ item: DropTopItem
    ) -> some View {
        Button {
            openPlaylist(item)
        } label: {
            HStack(spacing: 12) {
                WebImageView(
                    url: item.imageURL,
                    placeholderColor:
                        AppColors.secondarySystemBackground,
                    displayStyle:
                        .fixedFrame(
                            width: 60,
                            height: 60
                        ),
                    context:
                        "DropTop_\(item.id)"
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )

                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// =================================================
// MARK: - NAVIGATION
// =================================================

private extension DropTopContentView {

    func openPlaylist(
        _ item: DropTopItem
    ) {
        // droplistCoordinator.navigate(
        //     to: .topDropDetails(
        //         playlistId: item.id,
        //         title: item.title,
        //         imageURL: item.imageURL
        //     )
        // )
    }
}

//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//
//    var body: some View {
//        VStack(spacing: 0) {
//
//            tagSelector
//
//            Divider()
//
//            content
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//    }
//}
//
//private extension DropTopContentView {
//
//    var tagSelector: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//
//                ForEach(DropTopTag.allCases) { tag in
//
//                    Button {
//                        print("tag - \(tag)")
//                        Task {
//                            await viewModel.selectTag(tag)
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(
//                                .subheadline.weight(
//                                    .medium
//                                )
//                            )
//                            .foregroundColor(
//                                viewModel.selectedTag == tag
//                                    ? .white
//                                    : .primary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background {
//                                Capsule()
//                                    .fill(
//                                        viewModel.selectedTag == tag
//                                            ? Color.accentColor
//                                            : Color.secondary.opacity(0.12)
//                                    )
//                            }
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//        }
//    }
//}
//
//
//private extension DropTopContentView {
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.viewState {
//
//        case .loading:
//            ProgressView()
//
//        case .error(let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//
//        case .contentList(let page):
//            dropTopList(page)
//        }
//    }
//}
//
//private extension DropTopContentView {
//
//    func dropTopList(
//        _ page: DropTopPage
//    ) -> some View {
//
//        ScrollView {
//            LazyVStack(
//                spacing: 0
//            ) {
//                ForEach(page.items) { item in
//
//                    dropTopRow(item)
//
//                        .onAppear {
//                            guard item.id == page.items.last?.id else {
//                                return
//                            }
//                            print("onAppear - viewModel.loadNextPage()")
//                            viewModel.loadNextPage()
//                        }
//                }
//
//                // всегда крутится?
//                if page.hasMore {
//                    ProgressView()
//                        .padding(.vertical, 20)
//                        .onAppear {
//                            print("onAppear - if page.hasMore {")
//                        }
//                        .onDisappear {
//                            print("onDisappear - if page.hasMore {")
//                        }
//                }
//            }
//        }
//        .refreshable {
//            await viewModel.retry()
//        }
//    }
//}
//
//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//
//        Button {
//            openPlaylist(item)
//        } label: {
//
//            HStack(spacing: 12) {
//
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor:
//                        AppColors.secondarySystemBackground,
//                    displayStyle:
//                        .fixedFrame(
//                            width: 60,
//                            height: 60
//                        ),
//                    context:
//                        "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                Text(item.title)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .lineLimit(2)
//                    .multilineTextAlignment(.leading)
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
////        droplistCoordinator.navigate(
////            to: .topDropDetails(
////                playlistId: item.id,
////                title: item.title,
////                imageURL: item.imageURL
////            )
////        )
//    }
//}

//
//  SafariView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.05.26.
//


import SafariServices
import SwiftUI



// MARK: - SafariView (unchanged)

struct SafariView: UIViewControllerRepresentable {
   let url: URL

   func makeUIViewController(context: Context) -> SFSafariViewController {
       SFSafariViewController(url: url)
   }

   func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

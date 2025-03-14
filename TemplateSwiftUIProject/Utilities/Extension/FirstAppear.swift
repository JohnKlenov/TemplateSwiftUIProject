//
//  FirstAppear.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.01.25.
//

import SwiftUI

public extension View {
    func onFirstAppear(action: @escaping () -> Void) -> some View {
        modifier(FirstAppear(action: action))
    }
}

private struct FirstAppear: ViewModifier {
    let action: () -> Void
    // Use this to only fire your block one time
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        // And then, track it here
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

//
//  OnboardingPageView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//

import SwiftUI

struct OnboardingPageView: View {
    
    let page:OnboardingPage
    var body: some View {
        VStack {
            Image(systemName: page.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
            Text(page.title)
                .font(.largeTitle)
                .padding()
            Text(page.description)
                .font(.body)
                .padding()
        }
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage(title: "Welcome", description: "Welcome to our app", imageName: "house.fill"))
}

//
//  AppIcons.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.01.26.
//

import SwiftUI

enum AppIcons {
    
    // MARK: - Common icons (shared across multiple views)
    enum Common {
        static let appleLogo = "applelogo"
        static let googleLogo = "googlelogo" // кастомный ассет
        static let eye = "eye"
        static let eyeSlash = "eye.slash"
    }
    
    // MARK: - Home View Navigation Stack
//    enum Home {
//        static let homeTab = "house.fill"
//        static let search = "magnifyingglass"
//        static let favorites = "star.fill"
//    }
    
    // MARK: - Gallery Navigation Stack
//    enum Gallery {
//        static let galleryTab = "photo.on.rectangle"
//        static let addPhoto = "plus.circle.fill"
//        static let share = "square.and.arrow.up"
//    }
    
    // MARK: - Profile Navigation Stack
    enum Profile {
        
        // MARK: - UserInfoCellView
        enum UserInfoCellView {
            static let avatarPlaceholder = "person.circle.fill"
            static let retry = "arrow.clockwise.circle.fill"
            static let chevron = "chevron.right"
        }
        
        // MARK: - ToggleCellView
        enum ToggleCellView {
            static let notification = "bell.fill"
            static let darkMode = "moon.fill"
        }
        
        // MARK: - NavigationCellView
        enum NavigationCellView {
            static let changeLanguage = "globe"
            static let aboutUs = "info.circle"
            static let createAccount = "person.crop.circle.badge.plus"
            static let chevron = "chevron.right"
        }
        
        // MARK: - DeleteAccountCellView
        enum DeleteAccountCellView {
            static let deleteAccount = "trash"
            static let loading = "hourglass"
        }
    }
    
    enum ChangeLanguageView {
        static let checkmark = "checkmark"
    }
    
    enum UserInfoEditView {
        static let avatarPlaceholder = "person.crop.circle.fill"
    }
}


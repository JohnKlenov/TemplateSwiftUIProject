//
//  AppIcons.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.01.26.
//

import SwiftUI

enum AppIcons {
    
    
    // MARK: - Onboarding View
    enum Onboarding {
        /// Иконка для приветственного экрана
        static let welcome = "house.fill"
        
        /// Иконка для экрана Discover
        static let discover = "safari.fill"
        
        /// Иконка для экрана Get Started
        static let getStarted = "flag.fill"
    }

    
    // MARK: - TabBar icons
    enum TabBar {
        static let home = "house.fill"
        static let gallery = "photo.on.rectangle.fill"
        static let profile = "person.crop.circle.fill"
    }
    
    // MARK: - Common icons (shared across multiple views)
    enum Common {
        static let appleLogo = "applelogo"
        static let googleLogo = "googlelogo" // кастомный ассет
        static let eye = "eye"
        static let eyeSlash = "eye.slash"
    }
    
    /// ContentErrorView — заглушка при критичной системной ошибке,
    /// которая делает невозможным дальнейшее использование стека View.
    enum ContentErrorView {
        static let warning = "exclamationmark.triangle"
    }
    
    
    // MARK: - Home View Navigation Stack

    enum Home {
        enum EmptyStateView {
            static let documentPlaceholder = "swift"
        }
        enum BookRowView {
            /// Иконка удаления книги в списке
            static let deleteBook = "trash.fill"
        }
    }

    enum BookEditView {
        static let swift = "swift"
    }
    
    
    
    
    
    
    // MARK: - Gallery Navigation Stack
//    enum Gallery {
//        static let galleryTab = "photo.on.rectangle"
//        static let addPhoto = "plus.circle.fill"
//        static let share = "square.and.arrow.up"
//    }
    
    
    
    
    
    
    
    // MARK: - Profile Navigation Stack
    enum Profile {
        
        enum UserInfoCellView {
            static let avatarPlaceholder = "person.circle.fill"
            static let retry = "arrow.clockwise.circle.fill"
            static let chevron = "chevron.right"
        }
        
        enum ToggleCellView {
            static let notification = "bell.fill"
            static let darkMode = "moon.fill"
        }
        
        enum NavigationCellView {
            static let changeLanguage = "globe"
            static let aboutUs = "info.circle"
            static let createAccount = "person.crop.circle.badge.plus"
            static let chevron = "chevron.right"
        }
        
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


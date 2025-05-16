//
//  SecureTextField.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.05.25.
//



// MARK: - StackOverflow example


//import SwiftUI
//
//struct PasswordField: View {
//
//    let placeholder: String
//
//    @Binding
//    var text: String
//
//    @State
//    private var showText: Bool = false
//
//    private enum Focus {
//        case secure, text
//    }
//
//    @FocusState
//    private var focus: Focus?
//
//    @Environment(\.scenePhase)
//    private var scenePhase
//
//    var body: some View {
//        HStack {
//            ZStack {
//                SecureField(placeholder, text: $text)
//                    .focused($focus, equals: .secure)
//                    .opacity(showText ? 0 : 1)
//                TextField(placeholder, text: $text)
//                    .focused($focus, equals: .text)
//                    .opacity(showText ? 1 : 0)
//            }
//
//            Button(action: {
//                showText.toggle()
//            }) {
//                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
//            }
//        }
//        .onChange(of: focus) { newValue in
//            // if the PasswordField is focused externally, then make sure the correct field is actually focused
//            if newValue != nil {
//                focus = showText ? .text : .secure
//            }
//        }
//        .onChange(of: scenePhase) { newValue in
//            if newValue != .active {
//                showText = false
//            }
//        }
//        .onChange(of: showText) { newValue in
//            if focus != nil { // Prevents stealing focus to this field if another field is focused, or nothing is focused
//                DispatchQueue.main.async { // Needed for general iOS 16 bug with focus
//                    focus = newValue ? .text : .secure
//                }
//            }
//        }
//    }
//}
//
//struct LoginView: View {
//
//    private enum Focus {
//        case email, password
//    }
//
//    @FocusState
//    private var focus: Focus?
//
//    @State
//    private var email: String = ""
//
//    @State
//    private var password: String = ""
//
//    var body: some View {
//        VStack {
//            TextField("your@email.com", text: $email)
//                .focused($focus, equals: .email)
//            PasswordField(placeholder: "*****", text: $password)
//                .focused($focus, equals: .password)
//        }
//        .onSubmit {
//            if focus == .email {
//                focus = .password
//            } else if focus == .password {
//                // do login
//            }
//        }
//    }
//}
//
//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}

// MARK: - Medium example

///https://medium.com/@chinthaka01/swiftui-show-hide-password-text-input-field-86fc8fea4660

//import Foundation
//import SwiftUI
//
///// Properties and functionalities to assign and  perform in the parent view of the SecuredTextFieldView.
//protocol SecuredTextFieldParentProtocol {
//    
//    /// Assign SecuredTextFieldView hideKeyboard method to this and
//    /// then parent can excute it when needed..
//    var hideKeyboard: (() -> Void)? { get set }
//}
//
//
///// The identity of the TextField and the SecureField.
//enum Field: Hashable {
//    case showPasswordField
//    case hidePasswordField
//}
//
///// This view supports for have a secured filed with show / hide functionality.
/////
///// We have managed show / hide functionality by using
///// A SecureField for hide the text, and
///// A TextField for show the text.
/////
///// Please note that,
///// hide -> show -> hide senario with reset the text by the new input value.
///// It's common even in the other apps. eg: LinkedIn, MoneyGram
//struct SecuredTextFieldView: View {
//
//    /// Options for opacity of the fields.
//    enum Opacity: Double {
//
//        case hide = 0.0
//        case show = 1.0
//
//        /// Toggle the field opacity.
//        mutating func toggle() {
//            switch self {
//            case .hide:
//                self = .show
//            case .show:
//                self = .hide
//            }
//        }
//    }
//
//    /// The property wrapper type that can read and write a value that
//    /// SwiftUI updates as the placement of focus.
//    @FocusState private var focusedField: Field?
//
//    /// The show / hide state of the text.
//    @State private var isSecured: Bool = true
//
//    /// The opacity of the SecureField.
//    @State private var hidePasswordFieldOpacity = Opacity.show
//
//    /// The opacity of the TextField.
//    @State private var showPasswordFieldOpacity = Opacity.hide
//
//    /// The text value of the SecureFiled and TextField which can be
//    /// binded with the @State property of the parent view of SecuredTextFieldView.
//    @Binding var text: String
//    
//    /// Parent view of this SecuredTextFieldView.
//    /// Also this is a struct and structs are value type.
//    @State var parent: SecuredTextFieldParentProtocol
//
//    var body: some View {
//        VStack {
//            ZStack(alignment: .trailing) {
//                securedTextField
//
//                Button(action: {
//                    performToggle()
//                }, label: {
//                    Image(systemName: self.isSecured ? "eye.slash" : "eye")
//                        .accentColor(.gray)
//                })
//            }
//        }
//        .onAppear {
//            self.parent.hideKeyboard = hideKeyboard
//        }
//    }
//
//    /// Secured field with the show / hide capability.
//    var securedTextField: some View {
//        Group {
//            SecureField("Enter Text", text: $text)
//                .textInputAutocapitalization(.never)
//                .keyboardType(.asciiCapable) // This avoids suggestions bar on the keyboard.
//                .autocorrectionDisabled(true)
//                .padding(.bottom, 7)
//                .overlay(
//                    Rectangle().frame(width: nil, height: 1, alignment: .bottom)
//                        .foregroundColor(Color.gray),
//                    alignment: .bottom
//                )
//                .focused($focusedField, equals: .hidePasswordField)
//                .opacity(hidePasswordFieldOpacity.rawValue)
//
//            TextField("Enter Text", text: $text)
//                .textInputAutocapitalization(.never)
//                .keyboardType(.asciiCapable)
//                .autocorrectionDisabled(true)
//                .padding(.bottom, 7)
//                .overlay(
//                    Rectangle().frame(width: nil, height: 1, alignment: .bottom)
//                        .foregroundColor(Color.gray),
//                    alignment: .bottom
//                )
//                .focused($focusedField, equals: .showPasswordField)
//                .opacity(showPasswordFieldOpacity.rawValue)
//        }
//        .padding(.trailing, 32)
//    }
//    
//    /// This supports the parent view to perform hide the keyboard.
//    func hideKeyboard() {
//        self.focusedField = nil
//    }
//    
//    /// Perform the show / hide toggle by changing the properties.
//    private func performToggle() {
//        isSecured.toggle()
//
//        if isSecured {
//            focusedField = .hidePasswordField
//        } else {
//            focusedField = .showPasswordField
//        }
//
//        hidePasswordFieldOpacity.toggle()
//        showPasswordFieldOpacity.toggle()
//    }
//}
//
//struct ContentView1: View, SecuredTextFieldParentProtocol {
//    
//    /// This is getting assigned to the method in SecuredTextFieldView to
//    /// execute hide keyboard.
//    @State var hideKeyboard: (() -> Void)?
//    
//    /// The secured tex the usert inputed in SecuredTextFieldView
//    @State private var password = ""
//    
//    /// State of alert apearance.
//    @State private var showingAlert = false
//    
//    var body: some View {
//        GeometryReader { geometry in
//            VStack {
//                Group {
//                    VStack {
//                        SecuredTextFieldView(text: $password, parent: self)
//                            .frame(maxWidth: geometry.size.width * 0.9)
//
//                        Button(action: {
//                            showingAlert.toggle()
//                            performHideKeyboard()
//                        }, label: {
//                            HStack {
//                                Text("Show Text")
//                            }
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                            .frame(maxWidth: geometry.size.width * 0.6)
//                        })
//                        .buttonStyle(.borderedProminent)
//                        .tint(.black)
//                        .alert(password, isPresented: $showingAlert) {
//                            Button("OK", role: .cancel) { }
//                        }
//                    }
//                }
//                .frame(maxHeight: geometry.size.height * 0.33)
//            }
//        }
//        .padding()
//    }
//    
//    /// Execute the clouser and perform hide keyboard in SecuredTextFieldView.
//    private func performHideKeyboard() {
//        
//        guard let hideKeyboard = self.hideKeyboard else {
//            return
//        }
//        
//        hideKeyboard()
//    }
//}
//
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView1()
//    }
//}

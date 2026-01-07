//
//  ForgotPasswordView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.11.25.
//


import SwiftUI

struct ForgotPasswordView: View {
    
    @EnvironmentObject var localization: LocalizationService
    @ObservedObject var viewModel: ForgotPasswordViewModel
    @FocusState private var isFieldFocus: FieldToFocusAuth?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Поле "Email"
                VStack(alignment: .leading, spacing: 5) {
                    Text(Localized.ForgotPasswordView.email.localized())
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                    
                    TextField(Localized.ForgotPasswordView.emailPlaceholder.localized(), text: $viewModel.email)
                        .submitLabel(.done)
                        .focused($isFieldFocus, equals: .emailField)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .onTapGesture {
                            viewModel.emailError = nil
                        }
                    
                    if let error = viewModel.emailError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Кнопка "Send Reset Link"
                Button(action: sendResetLink) {
                    Group {
                        if viewModel.forgotPasswordState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(Localized.ForgotPasswordView.sendResetLink.localized())
                            // Отключаем implicit‑анимацию при появлении/исчезновении текста ошибки,
                            // чтобы кнопка не "прыгала" и содержимое не смещалось с задержкой
                                .animation(nil, value: viewModel.emailError)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .fontWeight(.semibold)
                .padding()
                .background(AppColors.activeColor)
                .foregroundColor(AppColors.primary)
                .cornerRadius(8)
                .padding(.horizontal)
                .disabled(viewModel.isAuthOperationInProgress)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localized.ForgotPasswordView.title.localized())
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
    }
    
    private func sendResetLink() {
        // Валидация email
        viewModel.updateValidationEmail()
        
        if viewModel.emailError == nil {
            print("Email валиден. Отправляем reset link.")
            viewModel.sendResetLink()
        } else {
            print("Email некорректный.")
        }
    }
}


//struct ForgotPasswordView: View {
//    @ObservedObject var viewModel: ForgotPasswordViewModel
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Reset your password")
//                .font(.title2)
//                .fontWeight(.semibold)
//            
//            TextField("Email", text: $viewModel.email)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .autocapitalization(.none)
//                .disableAutocorrection(true)
//                .onChange(of: viewModel.email) {  _ , _ in
//                    viewModel.updateValidationEmail()
//                }
//            
//            if let error = viewModel.emailError {
//                Text(error)
//                    .foregroundColor(.red)
//                    .font(.caption)
//            }
//            
//            Button(action: {
//                viewModel.sendResetLink()
//            }) {
//                if viewModel.forgotPasswordState == .loading {
//                    ProgressView()
//                } else {
//                    Text("Send Reset Link")
//                        .fontWeight(.semibold)
//                }
//            }
//            .disabled(viewModel.isAuthOperationInProgress || !viewModel.email.isValidEmail)
//        }
//        .padding()
//    }
//}

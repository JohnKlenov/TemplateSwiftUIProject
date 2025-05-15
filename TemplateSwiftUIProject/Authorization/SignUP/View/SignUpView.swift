//
//  SignUpView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.05.25.
//

import SwiftUI

struct CreateAccountView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    // Новое состояние для переключения видимости пароля
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Заголовок экрана
                Text("Создать аккаунт")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Форма регистрации с метками
                VStack(spacing: 15) {
                    // Поле "Имя"
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Имя")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        TextField("Введите имя", text: $username)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                    }
                    
                    // Поле "Email"
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        TextField("Введите email", text: $email)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Поле "Пароль" с кнопкой "eye" для переключения видимости
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Пароль")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("Введите пароль", text: $password)
                                } else {
                                    SecureField("Введите пароль", text: $password)
                                }
                            }
                            // Кнопка-переключатель
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }  // End of password field
                }
                .padding(.horizontal)
                
                // Кнопка регистрации
                Button(action: {
                    // Обработка регистрации пользователя
                }, label: {
                    Text("Зарегистрироваться")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                })
                .padding(.horizontal)
                
                // Разделитель между регистрацией и альтернативными способами входа
                HStack {
                    VStack { Divider().frame(height: 1).background(Color.primary) }
                    Text("ИЛИ")
                        .font(.footnote)
                        .foregroundColor(.primary)
                    VStack { Divider().frame(height: 1).background(Color.primary) }
                }
                .padding([.horizontal, .vertical])
                
                // Блок альтернативной регистрации
                HStack(spacing: 40) {
                    // Кнопка регистрации через Apple
                    Button(action: {
                        // Реализуйте регистрацию через Apple
                    }) {
                        Image(systemName: "applelogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding()
                            .tint(AppColors.primary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                    
                    // Кнопка регистрации через Google
                    Button(action: {
                        // Реализуйте регистрацию через Google
                    }) {
                        Image("googlelogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding()
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                }
                .padding(.vertical, 10)
                
                // Ссылка для входа
                HStack {
                    Text("Уже есть аккаунт?")
                    Button(action: {
                        // Переход на экран входа
                    }) {
                        Text("Войти")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateAccountView()
                .previewDevice("iPhone 12")
            CreateAccountView()
                .previewDevice("iPhone SE (2nd generation)")
        }
    }
}




// MARK: - Code


//var body: some View {
//    // GeometryReader позволяет получать размеры экрана
////        GeometryReader { geometry in
//        // ScrollView помогает избежать обрезания контента на маленьких экранах
////            ScrollView {
//            VStack(spacing: 20) {
//                // Заголовок экрана
//                Text("Создать аккаунт")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding(.top, 20)
//                
//                // Форма регистрации
//                VStack(spacing: 15) {
//                    TextField("Имя пользователя", text: $username)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                        .autocapitalization(.none)
//                    
//                    TextField("Email", text: $email)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                        .keyboardType(.emailAddress)
//                        .autocapitalization(.none)
//                    
//                    SecureField("Пароль", text: $password)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                }
//                .padding(.horizontal)
//                
//                // Кнопка регистрации
//                Button(action: {
//                    // Обработка регистрации пользователя
//                }, label: {
//                    Text("Зарегистрироваться")
//                        .fontWeight(.semibold)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.pink)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                })
//                .padding(.horizontal)
//                
//                // Разделитель между регистрацией и альтернативными способами входа
//                HStack {
//                    VStack { Divider().frame(height: 1).background(Color.primary) }
//                    Text("ИЛИ")
//                        .font(.footnote)
//                        .foregroundColor(.primary)
//                    VStack { Divider().frame(height: 1).background(Color.primary) }
//                }
//                .padding([.horizontal, .vertical])
//                
//                // Блок альтернативной регистрации
//                HStack(spacing: 40) {
//                    // Кнопка регистрации через Apple
//                    Button(action: {
//                        // Реализуйте регистрацию через Apple
//                    }) {
//                        Image(systemName: "applelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 30, height: 30)
//                            .padding()
//                            .tint(AppColors.primary)
//                            .clipShape(Circle())
//                            .overlay(
//                                Circle().stroke(Color.gray, lineWidth: 1)
//                            )
//                    }
//                    
//                    // Кнопка регистрации через Google
//                    Button(action: {
//                        // Реализуйте регистрацию через Google
//                    }) {
//                        // Создайте в Assets иконку с названием "google" или замените на существующую
//                        Image("googlelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 30, height: 30)
//                            .padding()
//                            .clipShape(Circle())
//                            .overlay(
//                                Circle().stroke(Color.gray, lineWidth: 1)
//                            )
//                    }
//                }
//                .padding(.vertical, 10)
//                
//                // Ссылка для перехода на экран входа
//                HStack {
//                    Text("Уже есть аккаунт?")
//                    Button(action: {
//                        // Переход на экран входа
//                    }) {
//                        Text("Войти")
//                            .foregroundColor(.blue)
//                            .fontWeight(.semibold)
//                    }
//                }
//                .padding(.bottom, 20)
//            }
//            // Заставляем VStack занимать всю ширину
////                .frame(minWidth: 0, maxWidth: .infinity)
////            }
//        // Устанавливаем ширину ScrollView равной экрану
////            .frame(width: geometry.size.width)
////        }
//}

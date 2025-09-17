//
//  TasksView.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SwiftUI

struct TasksView: View {
    @Binding var isPresented: Bool
    @State private var showSettings = false
    @State private var coins: Int = 500 // Монеты для тестирования

    var body: some View {
        ZStack {
            // Фоновое изображение
            Image("main_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.all)
            
            VStack {
                // Верхняя панель с навигацией
                HStack {
                    // Кнопка назад
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("back_button")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    
                    Spacer()
                    
                    // Лейбл задач по центру
                    Image("tasks_label")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                    
                    Spacer()
                    
                    // Правая группа элементов
                    HStack(spacing: 10) {
                        // Панель для монет
                        Image("money_panel")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text("\(coins)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
                            )
                        
                        // Кнопка настроек
                        Button(action: {
                            showSettings = true
                        }) {
                            Image("settings_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Контент задач
                VStack(spacing: -20) {
                    // Задание 1
                    Image("task_panel")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 350, height: 100)
                        .overlay(
                            VStack(spacing: 4) {
                                Text("First Act")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Text("Complete 1 level")
                                    .font(.system(size: 15))
                                    .foregroundColor(.orange)
                            }
                        )
                    
                    // Задание 2
                    Image("task_panel")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 350, height: 100)
                        .overlay(
                            VStack(spacing: 4) {
                                Text("Trainer")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Text("Keep three animals until the end")
                                    .font(.system(size: 15))
                                    .foregroundColor(.orange)
                            }
                        )
                    
                    // Задание 3
                    Image("task_panel")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 350, height: 100)
                        .overlay(
                            VStack(spacing: 4) {
                                Text("Success Scene")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Text("Complete level with three stars")
                                    .font(.system(size: 15))
                                    .foregroundColor(.orange)
                            }
                        )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSettings) {
            // Переход к настройкам
            SettingsView(isPresented: $showSettings)
        }
    }
}

#Preview {
    TasksView(isPresented: .constant(true))
}

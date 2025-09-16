//
//  MainMenuView.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SwiftUI

struct MainMenuView: View {
    @State private var showGame = false
    @State private var showSettings = false
    @State private var showShop = false
    @State private var showTasks = false
    
    var body: some View {
        ZStack {
            // Фоновое изображение
            Image("main_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.all)
            
            // Навигационная панель
            VStack {
             // Spacer()
                HStack {
                    // Левая группа кнопок
                    HStack(spacing: 10) {
                        // Кнопка задач
                        Button(action: {
                            showTasks = true
                        }) {
                            Image("tasks_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                        }
                        
                        // Кнопка магазина рядом справа
                        Button(action: {
                            showShop = true
                        }) {
                            Image("shop_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70, height: 70)
                        }
                    }
                    
                    Spacer()
                    
                    // Правая группа элементов
                    HStack(spacing: 10) {
                        // Панель для монет
                        Image("money_panel")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                        
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
            }
            // Основной контент меню
            VStack(spacing: 30) {
                // Spacer()
                
                // Логотип игры
                Image("logo_image ")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 150)
                    .shadow(color: .black, radius: 3, x: 2, y: 2)
                
                Spacer()
                
                // Кнопки меню
                VStack(spacing: 20) {
                    // Кнопка "Играть"
                 
                    
                    // Кнопка "Настройки"
                   
                    
                    // Кнопка "Выход"
              
                }
                
                //Spacer()
                
                // Система уровней
                VStack(spacing: 10) {
                    // Верхняя полоса уровней
                    HStack(spacing: 15) {
                        // Уровень 1 (пройден - 2 звезды)
                        Image("unlockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .overlay(
                                VStack {
                                    HStack(spacing: 2) {
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(y: -8)
                                  //  Spacer()
                                    Text("1")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        // Уровень 2 (пройден - 3 звезды)
                        Image("unlockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .overlay(
                                VStack {
                                    HStack(spacing: 2) {
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(y: -8)
                                    //Spacer()
                                    Text("2")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        // Уровень 3 (пройден - 1 звезда)
                        Image("unlockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .overlay(
                                VStack {
                                    HStack(spacing: 2) {
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(y: -8)
                                    //Spacer()
                                    Text("3")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        // Уровень 4 (пройден - 2 звезды)
                        Image("unlockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .overlay(
                                VStack {
                                    HStack(spacing: 2) {
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(y: -8)
                                    //Spacer()
                                    Text("4")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        // Уровень 5 (пройден - 2 звезды)
                        Image("unlockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .overlay(
                                VStack {
                                    HStack(spacing: 2) {
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("fillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(y: -8)
                                   // Spacer()
                                    Text("5")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        // Уровень 6 (доступен, но не пройден)
                        Image("unlockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .overlay(
                                VStack {
                                    HStack(spacing: 2) {
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                        Image("notFillStar_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 12, height: 12)
                                    }
                                    .offset(y: -8)
                                   // Spacer()
                                    Text("6")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        // Заблокированный уровень 7
                        Image("lockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                        
                        // Заблокированный уровень 8
                        Image("lockLvlPanel_image")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    
                    // Нижняя полоса уровней (все заблокированы)
                    HStack(spacing: 15) {
                        ForEach(9...16, id: \.self) { level in
                            Image("lockLvlPanel_image")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showGame) {
            // Переход к игровой сцене
            ContentView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            // Переход к настройкам
            SettingsView(isPresented: $showSettings)
        }
        .fullScreenCover(isPresented: $showShop) {
            // Переход к магазину
            ShopView(isPresented: $showShop)
        }
        .fullScreenCover(isPresented: $showTasks) {
            // Переход к задачам
            TasksView(isPresented: $showTasks)
        }
    }
}

#Preview {
    MainMenuView()
}

//
//  ShopView.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SwiftUI

struct ShopView: View {
    @Binding var isPresented: Bool
    @State private var showSettings = false
    
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
                    
                    // Лейбл магазина по центру
                    Image("shop_label")
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
                
                // Контент магазина - панели скинов
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        // Скин 1 - доступен для покупки
                        VStack(spacing: 10) {
                            // Панель скина
                            Image("skinPanel_image")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 250)
                                .overlay(
                                    VStack {
                                        // Скин сверху
                                        Image("skin1_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)
                                        
                                        Spacer()
                                        
                                        // Кнопка покупки внизу панели
                                        Button(action: {
                                            // Действие покупки скина 1
                                        }) {
                                            Image("buy_button")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 40)
                                                
                                        }
                                    }
                                    .padding(.vertical, 20)
                                )
                        }
                        
                        // Скин 2 - в использовании
                        VStack(spacing: 10) {
                            // Панель скина
                            Image("skinPanel_image")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 250)
                                .overlay(
                                    VStack {
                                        // Скин сверху
                                        Image("skin2_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)
                                        
                                        Spacer()
                                        
                                        // Кнопка "В использовании" внизу панели
                                        Image("inUse_button")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 120, height: 40)
                                    }
                                    .padding(.vertical, 20)
                                )
                        }
                        
                        // Скин 3 - куплен, но не используется
                        VStack(spacing: 10) {
                            // Панель скина
                            Image("skinPanel_image")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 250)
                                .overlay(
                                    VStack {
                                        // Скин сверху
                                        Image("skin3_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)
                                        
                                        Spacer()
                                        
                                        // Кнопка "Использовать" внизу панели
                                        Button(action: {
                                            // Действие смены скина на 3
                                        }) {
                                            Image("use_button")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 40)
                                               
                                        }
                                    }
                                    .padding(.vertical, 20)
                                )
                        }
                        
                        // Скин 4 - доступен для покупки
                        VStack(spacing: 10) {
                            // Панель скина
                            Image("skinPanel_image")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 250)
                                .overlay(
                                    VStack {
                                        // Скин сверху
                                        Image("skin4_icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)
                                        
                                        Spacer()
                                        
                                        // Кнопка покупки внизу панели
                                        Button(action: {
                                            // Действие покупки скина 4
                                        }) {
                                            Image("buy_button")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 40)
                                        }
                                    }
                                    .padding(.vertical, 20)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
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
    ShopView(isPresented: .constant(true))
}

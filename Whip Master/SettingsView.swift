//
//  SettingsView.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var musicVolume: Double = 0.0
    @State private var soundVolume: Double = 100.0
    
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
                // Верхняя панель с заголовком и кнопкой назад
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
                    
                    // Лейбл настроек
                    Image("settings_label")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                    
                    Spacer()
                    
                    // Невидимая кнопка для баланса
                    Image("back_button")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Панели с настройками
                VStack(spacing: 20) {
                    // Панель для слайдера музыки
                    Image("sidersPanel_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 80)
                        .overlay(
                            HStack {
                                // Иконка музыки
                                Image(systemName: musicVolume > 0 ? "music.note" : "music.note.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                
                                // Слайдер музыки
                                Slider(value: $musicVolume, in: 0...100)
                                    .accentColor(.blue)
                                
                                // Процент музыки
                                Text("\(Int(musicVolume))%")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(width: 40)
                            }
                            .padding(.horizontal, 30)
                        )
                    
                    // Панель для слайдера звука
                    Image("sidersPanel_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 80)
                        .overlay(
                            HStack {
                                // Иконка звука
                                Image(systemName: soundVolume > 0 ? "speaker.wave.3" : "speaker.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                
                                // Слайдер звука
                                Slider(value: $soundVolume, in: 0...100)
                                    .accentColor(.blue)
                                
                                // Процент звука
                                Text("\(Int(soundVolume))%")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(width: 40)
                            }
                            .padding(.horizontal, 30)
                        )
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}

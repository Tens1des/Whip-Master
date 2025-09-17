//
//  ContentView.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SwiftUI
import SpriteKit

struct SKViewRepresentable: UIViewRepresentable {
    var scene: SKScene
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.isMultipleTouchEnabled = true
        view.presentScene(scene)
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Обновления, если необходимо
    }
}

struct ContentView: View {
    @State private var gameScene: GameScene?
    
    var body: some View {
        ZStack {
            // Фоновый цвет или изображение (опционально)
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Игровая сцена
            if let scene = gameScene {
                GameSceneView(scene: scene)
            } else {
                // Показываем загрузочный индикатор, пока сцена не готова
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .onAppear {
            // Инициализируем сцену при появлении представления
            if gameScene == nil {
                let screenSize = UIScreen.main.bounds.size
                let scene = GameScene(size: screenSize)
                scene.scaleMode = .resizeFill
                gameScene = scene
            } else {
                // Обновляем скин при возврате в игру
                gameScene?.updateSkin()
            }
        }
        .navigationBarHidden(true)
    }
}

// Отдельное представление для игровой сцены и интерфейса
struct GameSceneView: View {
    @ObservedObject var scene: GameScene
    @Environment(\.dismiss) private var dismiss
    @State private var musicVolume: Double = 50
    @State private var soundVolume: Double = 100
    
    var body: some View {
        ZStack {
            // Игровая сцена
            SKViewRepresentable(scene: scene)
                .ignoresSafeArea()
            
            // HUD поверх сцены
            VStack {
                HStack {
                    // Таймер слева
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TIME LEFT:")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(Color.yellow)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                        Text(timeString(scene.remainingSeconds))
                            .font(.system(size: 44, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // Кнопка паузы справа
                    Button(action: {
                        scene.setPausedByUser(!scene.isPausedByUser)
                    }) {
                        Image("pause_button")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .padding(.trailing, 16)
                    }
                }
                .padding(.top, 10)
                Spacer()
            }

            // Алерт победы
            if scene.showWinAlert {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                VStack(spacing: 30) {
                    // Логотип победы
                    Image("win_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 2, y: 2)
                    
                    Spacer()
                    
                    // Кнопки победы
                    HStack(spacing: 20) {
                        // Кнопка "Домой"
                        Button(action: {
                            dismiss()
                        }) {
                            Image("homeAlert_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 60)
                        }
                        
                        // Кнопка "Следующий уровень"
                        Button(action: {
                            // TODO: Переход на следующий уровень
                            scene.showWinAlert = false
                        }) {
                            Image("nextLvl_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140, height: 60)
                        }
                        
                        // Кнопка "Снова"
                        Button(action: {
                            scene.resetGame()
                        }) {
                            Image("again_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 60)
                        }
                    }
                }
                .padding()
            }
            
            // Алерт поражения
            if scene.showLoseAlert {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                VStack(spacing: 30) {
                    // Логотип поражения
                    Image("lost_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .shadow(color: .black.opacity(0.7), radius: 3, x: 2, y: 2)
                    
                    Spacer()
                    
                    // Кнопки поражения
                    HStack(spacing: 20) {
                        // Кнопка "Домой"
                        Button(action: {
                            dismiss()
                        }) {
                            Image("homeAlert_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 60)
                        }
                        
                        // Кнопка "Снова"
                        Button(action: {
                            scene.resetGame()
                        }) {
                            Image("again_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 60)
                        }
                    }
                }
                .padding()
            }

            // Пауза — модальный оверлей
            if scene.isPausedByUser {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                VStack(spacing: 10) {
                    // Заголовок PAUSED
                    Image("pause_label")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 40)
                        .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
                    
                    // Панель музыки
                    Image("sidersPanel_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320, height: 90)
                        .overlay(
                            HStack {
                                Image(systemName: musicVolume > 0 ? "music.note" : "music.note.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                Slider(value: $musicVolume, in: 0...100)
                                    .accentColor(.orange)
                                Text("\(Int(musicVolume))%")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(width: 48)
                            }
                            .padding(.horizontal, 28)
                        )
                    
                    // Панель звука
                    Image("sidersPanel_image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320, height: 90)
                        .overlay(
                            HStack {
                                Image(systemName: soundVolume > 0 ? "speaker.wave.3" : "speaker.slash")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                Slider(value: $soundVolume, in: 0...100)
                                    .accentColor(.blue)
                                Text("\(Int(soundVolume))%")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(width: 48)
                            }
                            .padding(.horizontal, 28)
                        )
                    
                    HStack(spacing: 24) {
                        // Кнопка Домой
                        Button(action: { dismiss() }) {
                            Image("homePause_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180, height: 68)
                        }
                        // Кнопка Продолжить
                        Button(action: { scene.setPausedByUser(false) }) {
                            Image("resume_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 72)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Helpers
private func timeString(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

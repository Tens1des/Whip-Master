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
                let scene = GameScene()
                scene.scaleMode = .aspectFill
                gameScene = scene
            }
        }
        .navigationBarHidden(true)
    }
}

// Отдельное представление для игровой сцены и интерфейса
struct GameSceneView: View {
    @ObservedObject var scene: GameScene
    
    var body: some View {
        ZStack {
            // Игровая сцена
            SKViewRepresentable(scene: scene)
                .ignoresSafeArea()
            
            // Игровой интерфейс поверх сцены
            VStack {
                // Здесь будет игровой интерфейс сцены
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}

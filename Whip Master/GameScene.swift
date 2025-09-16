//
//  GameScene.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, ObservableObject {
    
    override func didMove(to view: SKView) {
        // Устанавливаем размер сцены для горизонтальной ориентации
        size = view.bounds.size
        setupScene()
    }
    
    private func setupScene() {
        // Устанавливаем цвет фона
        backgroundColor = SKColor.black
        
        // Создаем и настраиваем текст "Hello!"
        let helloLabel = SKLabelNode(fontNamed: "Arial-Bold")
        helloLabel.text = "Hello!"
        helloLabel.fontSize = 48
        helloLabel.fontColor = SKColor.white
        helloLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        helloLabel.zPosition = 1
        
        // Добавляем текст на сцену
        addChild(helloLabel)
        
        // Добавляем анимацию для текста
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        let repeatPulse = SKAction.repeatForever(pulse)
        
        helloLabel.run(repeatPulse)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Обработка касаний (можно добавить позже)
        for touch in touches {
            let location = touch.location(in: self)
            print("Touch at: \(location)")
        }
    }
}

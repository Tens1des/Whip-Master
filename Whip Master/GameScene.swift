//
//  GameScene.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SpriteKit
import UIKit
import GameplayKit

class GameScene: SKScene, ObservableObject {
    private var backgroundNode: SKSpriteNode?
    private var clownNode: SKSpriteNode?
    private var clownOffsetY: CGFloat = 40
    
    // MARK: - Animals
    private var animals: [SKSpriteNode] = []
    private let animalNames = ["bear_object", "monkey_object", "tiger_object", "elephan_object", "lev_object"]
    private let animalDarkNames = ["bear_dark", "monkey_dark", "tiger_dark", "elephant_dark", "lion_dark"]
    private struct AnimalUI {
        let panel: SKSpriteNode
        let dots: [SKSpriteNode]
        let clock: SKSpriteNode
        let timeLabel: SKLabelNode
        let progressBar: SKSpriteNode
    }
    private var animalUIs: [AnimalUI] = []
    
    // MARK: - Animal timers
    private var animalTimers: [Int] = [30, 30, 30, 30, 30] // 30 секунд для каждого животного
    private var animalFirstAppearance: [Bool] = [] // флаг первого появления для каждого животного
    private var animalVanish: [Bool] = [] // флаг исчезновения животного навсегда
    
    // MARK: - Animal sequences
    private var animalSequences: [[String]] = [] // последовательности цветов для каждого животного
    private var animalTargetSequences: [[String]] = [] // целевые последовательности (правильные)
    private let availableColors = ["red_circle", "yellow_circle", "blue_circle", "green_circle"]
    private var animalVisible: [Bool] = [] // текущее состояние видимости
    private var animalActive: [Bool] = [] // активное состояние животного (светлое/темное)
    private var animalShowingSequence: [Bool] = [] // показывает ли животное последовательность
    private var animalSequenceTimer: [TimeInterval] = [] // таймер показа последовательности
    private var animalCurrentTapIndex: [Int] = [] // текущий индекс в последовательности тапов
    private var animalSequenceOrder: [[Int]] = [] // порядок показа больших шаров для каждого животного
    private var animalCurrentSequenceIndex: [Int] = [] // текущий индекс в анимации последовательности
    private var animalSequenceAnimationTimer: [TimeInterval] = [] // таймер анимации последовательности
    
    // MARK: - Spotlights
    private var animalSpotlights: [SKSpriteNode] = [] // прожектор для каждого животного
    private var spotlightTargetIndex: Int = -1 // на какое животное направлен прожектор
    private var spotlightTimer: TimeInterval = 0
    private var spotlightChangeInterval: TimeInterval = 3.0 // интервал смены направления (3 секунды)
    private var spotlightAngle: CGFloat = 0 // текущий угол прожектора
    private var spotlightRotationSpeed: CGFloat = 0.02 // скорость вращения прожектора (радиан за кадр)
    
    // Хаотичные прожекторы
    private var chaoticSpotlights: [SKSpriteNode] = [] // хаотичные прожекторы
    private var chaoticSpotlightPositions: [CGPoint] = [] // текущие позиции хаотичных прожекторов
    private var chaoticSpotlightVelocities: [CGPoint] = [] // скорости хаотичных прожекторов
    private var chaoticSpotlightTargetPositions: [CGPoint] = [] // целевые позиции хаотичных прожекторов
    private var chaoticSpotlightChangeTimers: [TimeInterval] = [] // таймеры смены направления
    private var chaoticSpotlightChangeInterval: TimeInterval = 2.0 // интервал смены направления (2 секунды)
    private var chaoticSpotlightSpeed: CGFloat = 80 // скорость движения хаотичных прожекторов
    
    // MARK: - Level timer
    @Published var remainingSeconds: Int = 90
    @Published var isPausedByUser: Bool = false
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Game state
    @Published var showWinAlert: Bool = false
    @Published var showLoseAlert: Bool = false
    private var gameEnded: Bool = false
    
    // MARK: - Skin system
    @Published var currentSkinSprite: String = "clown_default"
    private let skinManager = SkinManager.shared
    
    private var isSceneSetup = false
    
    override func didMove(to view: SKView) {
        print("[GameScene] didMove. view.bounds=\(view.bounds.size), scene.size=\(size)")
        // Не вызываем setupScene здесь, ждём корректного размера в didChangeSize
    }
    
    private func setupScene() {
        // Фон арены (fallback на main_bg если game_bg отсутствует)
        let bgName = UIImage(named: "game_bg") != nil ? "game_bg" : "main_bg"
        let background = SKSpriteNode(imageNamed: bgName)
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.zPosition = -100
        background.size = size
        addChild(background)
        backgroundNode = background

        // Персонаж в центре под центральным светом (используем выбранный скин)
        let selectedSkin = skinManager.getCurrentSkinSprite()
        let clownImageName: String
        if UIImage(named: selectedSkin) != nil {
            clownImageName = selectedSkin
        } else if UIImage(named: "clown_default") != nil {
            clownImageName = "clown_default"
        } else {
            // Временный плейсхолдер: используем логотип, если клоун ещё не импортирован
            clownImageName = "logo_image "
            print("[GameScene] Warning: asset '\(selectedSkin)' not found. Using placeholder '", clownImageName, "'.")
        }
        let clown = SKSpriteNode(imageNamed: clownImageName)
        clown.position = CGPoint(x: frame.midX, y: frame.midY + clownOffsetY)
        clown.zPosition = 5
        // Адаптивный масштаб персонажа относительно высоты экрана
        if let texture = clown.texture {
            let targetHeight = frame.height * 0.28
            let scale = max(0.01, targetHeight / texture.size().height)
            clown.xScale = scale
            clown.yScale = scale
        }
        addChild(clown)
        clownNode = clown
        print("[GameScene] BG name=\(bgName), clown=\(clownImageName), scene size=\(size)")
        
        // Размещаем животных по секторам арены
        setupAnimals()
        // Создаем прожекторы для каждого животного
        setupAnimalSpotlights()
        
        // Инициализируем флаги видимости - все животные неактивны в начале
        animalVisible = Array(repeating: false, count: animals.count)
        animalActive = Array(repeating: false, count: animals.count)
        animalFirstAppearance = Array(repeating: false, count: animals.count)
        animalVanish = Array(repeating: false, count: animals.count)
        animalShowingSequence = Array(repeating: false, count: animals.count)
        animalSequenceTimer = Array(repeating: 0, count: animals.count)
        showAllAnimalsAsDark()
        
        isSceneSetup = true
    }
    
    private func setupAnimals() {
        print("[GameScene] setupAnimals called. Frame size: \(frame.size)")
        
        let centerX = frame.midX
        let centerY = frame.midY
        let radius = min(frame.width, frame.height) * 0.35
        
        print("[GameScene] Center: (\(centerX), \(centerY)), Radius: \(radius)")
        
        // Позиции для 5 животных по кругу
        let angles: [CGFloat] = [0, 72, 144, 216, 288] // 360/5 = 72 градуса между животными
        
        for (index, rawName) in animalNames.enumerated() {
            // Используем темную версию животного в начале
            let darkName = animalDarkNames[index]
            let darkAssetExists = UIImage(named: darkName) != nil
            let imageName = darkAssetExists ? darkName : "logo_image "
            if !darkAssetExists {
                print("[GameScene] Warning: dark animal asset not found: \(darkName). Using placeholder \(imageName)")
            }
            
            let animal = SKSpriteNode(imageNamed: imageName)
            
            // Проверяем, что спрайт создался
            if animal.texture == nil {
                print("[GameScene] ERROR: Failed to create sprite for \(rawName) -> \(imageName)")
                continue
            }
            
            let angle = angles[index] * .pi / 180 // конвертируем в радианы
            
            // Позиция по кругу
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            animal.position = CGPoint(x: x, y: y)
            
            // Масштабируем животное (увеличиваем размер)
            if let texture = animal.texture {
                let targetHeight = frame.height * 0.25  // увеличили с 0.15 до 0.25
                let scale = max(0.01, targetHeight / texture.size().height)
                animal.xScale = scale
                animal.yScale = scale
                print("[GameScene] Animal \(rawName) texture size: \(texture.size()), scale: \(scale)")
            }
            
            animal.zPosition = 10 // Поднимаем выше клоуна
            animal.name = "animal_\(index)" // Добавляем имя для отладки
            addChild(animal)
            animals.append(animal)
            
            // UI: панель + 5 цветных кругов
            let panel = SKSpriteNode(imageNamed: "panelColor_panel")
            panel.zPosition = 12
            addChild(panel)
            
            let colors = ["red_circle", "yellow_circle", "blue_circle", "green_circle"]
            var dots: [SKSpriteNode] = []
            // Создаем 5 кругов (один цвет будет повторяться)
            for i in 0..<5 {
                let colorIndex = i % colors.count // циклически используем 4 цвета
                let colorName = colors[colorIndex]
                let dot = SKSpriteNode(imageNamed: colorName)
                dot.zPosition = 13
                addChild(dot)
                dots.append(dot)
            }
            
            // Таймер: часы + время + прогресс-бар
            let clock = SKSpriteNode(imageNamed: "clock_icon")
            clock.zPosition = 14
            clock.isHidden = true
            addChild(clock)
            
            let timeLabel = SKLabelNode(fontNamed: "Arial-Bold")
            timeLabel.text = "00:30"
            timeLabel.fontSize = 24
            timeLabel.fontColor = .white
            timeLabel.zPosition = 15
            timeLabel.isHidden = true
            addChild(timeLabel)
            
            // Простой градиентный прогресс-бар
            let progressBar = createGradientProgressBar(size: CGSize(width: 100, height: 20))
            progressBar.zPosition = 14
            progressBar.isHidden = true
            addChild(progressBar)
            
            animalUIs.append(AnimalUI(panel: panel, dots: dots, clock: clock, timeLabel: timeLabel, progressBar: progressBar))
            
            print("[GameScene] Animal \(rawName) added at position: \(animal.position), zPosition: \(animal.zPosition)")
        }
        
        print("[GameScene] Total animals added: \(animals.count)")
        
        // Генерируем рандомные последовательности для всех животных
        generateRandomSequences()
        
        layoutAnimals() // выравниваем панели сразу
    }
    
    
    private func setupAnimalSpotlights() {
        print("[GameScene] setupAnimalSpotlights called. Frame size: \(frame.size)")
        
        // Очищаем массивы прожекторов
        animalSpotlights.removeAll()
        chaoticSpotlights.removeAll()
        chaoticSpotlightPositions.removeAll()
        chaoticSpotlightVelocities.removeAll()
        chaoticSpotlightTargetPositions.removeAll()
        chaoticSpotlightChangeTimers.removeAll()
        
        // Создаем один вращающийся прожектор
        let spotlight = SKSpriteNode(imageNamed: "light_area")
        
        if spotlight.texture == nil {
            print("[GameScene] ERROR: Failed to create spotlight sprite")
            return
        }
        
        // Размещаем прожектор в центре арены
        spotlight.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Масштабируем прожектор (делаем больше)
        if let texture = spotlight.texture {
            let targetHeight = frame.height * 0.3 // размер прожектора
            let scale = max(0.01, targetHeight / texture.size().height)
            spotlight.xScale = scale
            spotlight.yScale = scale
            print("[GameScene] Spotlight texture size: \(texture.size()), scale: \(scale)")
        }
        
        spotlight.zPosition = 15 // выше животных (у них zPosition = 10)
        spotlight.name = "rotating_spotlight"
        spotlight.isHidden = false // всегда видим
        addChild(spotlight)
        animalSpotlights.append(spotlight)
        
        // Инициализируем угол
        spotlightAngle = 0
        
        // Создаем два хаотичных прожектора
        for i in 0..<2 {
            let chaoticSpotlight = SKSpriteNode(imageNamed: "light_area")
            
            if chaoticSpotlight.texture == nil {
                print("[GameScene] ERROR: Failed to create chaotic spotlight sprite \(i)")
                continue
            }
            
            // Размещаем в случайной позиции в пределах арены
            let arenaRadius = min(frame.width, frame.height) * 0.35
            let centerX = frame.midX
            let centerY = frame.midY
            let angle = Double.random(in: 0...(2 * Double.pi))
            let distance = Double.random(in: 0...Double(arenaRadius))
            
            let position = CGPoint(
                x: centerX + CGFloat(distance * cos(angle)),
                y: centerY + CGFloat(distance * sin(angle))
            )
            
            chaoticSpotlight.position = position
            
            // Масштабируем прожектор
            if let texture = chaoticSpotlight.texture {
                let targetHeight = frame.height * 0.25 // немного меньше основного
                let scale = max(0.01, targetHeight / texture.size().height)
                chaoticSpotlight.xScale = scale
                chaoticSpotlight.yScale = scale
            }
            
            chaoticSpotlight.zPosition = 15
            chaoticSpotlight.name = "chaotic_spotlight_\(i)"
            chaoticSpotlight.isHidden = false
            addChild(chaoticSpotlight)
            chaoticSpotlights.append(chaoticSpotlight)
            chaoticSpotlightPositions.append(position)
            chaoticSpotlightVelocities.append(CGPoint.zero)
            chaoticSpotlightTargetPositions.append(position)
            chaoticSpotlightChangeTimers.append(0)
            
            // Генерируем первую целевую позицию
            generateNewChaoticTarget(for: i)
        }
        
        print("[GameScene] Rotating spotlight created at position: \(spotlight.position)")
        print("[GameScene] Created \(chaoticSpotlights.count) chaotic spotlights")
    }
    
    private func generateNewChaoticTarget(for index: Int) {
        guard index < chaoticSpotlightTargetPositions.count else { return }
        
        // Генерируем случайную позицию в пределах арены
        let arenaRadius = min(frame.width, frame.height) * 0.35
        let centerX = frame.midX
        let centerY = frame.midY
        
        // Случайный угол и расстояние
        let angle = Double.random(in: 0...(2 * Double.pi))
        let distance = Double.random(in: 0...Double(arenaRadius))
        
        chaoticSpotlightTargetPositions[index] = CGPoint(
            x: centerX + CGFloat(distance * cos(angle)),
            y: centerY + CGFloat(distance * sin(angle))
        )
        
        print("[GameScene] New chaotic target for spotlight \(index): \(chaoticSpotlightTargetPositions[index])")
    }
    
    private func updateChaoticSpotlights() {
        guard !chaoticSpotlights.isEmpty else { return }
        
        for i in 0..<chaoticSpotlights.count {
            guard i < chaoticSpotlightPositions.count && i < chaoticSpotlightVelocities.count else { continue }
            
            // Обновляем таймер смены направления
            chaoticSpotlightChangeTimers[i] += 1.0 / 60.0 // предполагаем 60 FPS
            
            // Если пришло время сменить направление
            if chaoticSpotlightChangeTimers[i] >= chaoticSpotlightChangeInterval {
                chaoticSpotlightChangeTimers[i] = 0
                generateNewChaoticTarget(for: i)
            }
            
            // Вычисляем направление к целевой позиции
            let targetPos = chaoticSpotlightTargetPositions[i]
            let currentPos = chaoticSpotlightPositions[i]
            let dx = targetPos.x - currentPos.x
            let dy = targetPos.y - currentPos.y
            let distance = sqrt(dx * dx + dy * dy)
            
            // Если мы близко к цели, выбираем новую
            if distance < 20 {
                generateNewChaoticTarget(for: i)
            }
            
            // Нормализуем направление и применяем скорость
            if distance > 0 {
                let normalizedX = dx / distance
                let normalizedY = dy / distance
                
                chaoticSpotlightVelocities[i] = CGPoint(
                    x: normalizedX * chaoticSpotlightSpeed / 60.0, // делим на 60 для FPS
                    y: normalizedY * chaoticSpotlightSpeed / 60.0
                )
            }
            
            // Обновляем позицию
            chaoticSpotlightPositions[i].x += chaoticSpotlightVelocities[i].x
            chaoticSpotlightPositions[i].y += chaoticSpotlightVelocities[i].y
            
            // Ограничиваем движение в пределах арены
            let arenaRadius = min(frame.width, frame.height) * 0.4
            let centerX = frame.midX
            let centerY = frame.midY
            
            let distanceFromCenter = sqrt(
                (chaoticSpotlightPositions[i].x - centerX) * (chaoticSpotlightPositions[i].x - centerX) +
                (chaoticSpotlightPositions[i].y - centerY) * (chaoticSpotlightPositions[i].y - centerY)
            )
            
            if distanceFromCenter > arenaRadius {
                // Возвращаем прожектор в пределы арены
                let angle = atan2(chaoticSpotlightPositions[i].y - centerY, chaoticSpotlightPositions[i].x - centerX)
                chaoticSpotlightPositions[i].x = centerX + arenaRadius * cos(angle)
                chaoticSpotlightPositions[i].y = centerY + arenaRadius * sin(angle)
            }
            
            // Обновляем позицию спрайта
            chaoticSpotlights[i].position = chaoticSpotlightPositions[i]
        }
    }
    
    private func updateSpotlightRotation() {
        guard !animalSpotlights.isEmpty else { return }
        
        // Обновляем угол вращения
        spotlightAngle += spotlightRotationSpeed
        
        // Получаем радиус арены
        let centerX = frame.midX
        let centerY = frame.midY
        let radius = min(frame.width, frame.height) * 0.35
        
        // Вычисляем новую позицию прожектора
        let newX = centerX + radius * cos(spotlightAngle)
        let newY = centerY + radius * sin(spotlightAngle)
        
        // Обновляем позицию прожектора
        if let spotlight = animalSpotlights.first {
            spotlight.position = CGPoint(x: newX, y: newY)
        }
        
        // Проверяем, освещает ли прожектор какое-либо животное
        checkSpotlightIllumination()
    }
    
    private func checkSpotlightIllumination() {
        guard !animals.isEmpty, !animalSpotlights.isEmpty else { return }
        
        let spotlight = animalSpotlights.first!
        let spotlightRadius: CGFloat = frame.height * 0.15 // радиус освещения
        
        // Скрываем таймер предыдущего освещенного животного (но НЕ меняем скин, если животное активно)
        if spotlightTargetIndex >= 0 && spotlightTargetIndex < animals.count {
            hideAnimalTimer(for: spotlightTargetIndex)
            // Меняем скин на темный только если животное НЕ активно (не имеет панели)
            if !animalActive[spotlightTargetIndex] {
                hideAnimalSkin(at: spotlightTargetIndex)
            }
        }
        
        spotlightTargetIndex = -1 // сбрасываем текущую цель
        
        // Проверяем каждое животное на попадание в зону освещения
        for (index, animal) in animals.enumerated() {
            let distance = hypot(animal.position.x - spotlight.position.x, 
                               animal.position.y - spotlight.position.y)
            
            if distance <= spotlightRadius {
                // Прожектор освещает это животное
                spotlightTargetIndex = index
                showAnimalSkin(at: index)
                showAnimalTimer(for: index)
                print("[GameScene] Spotlight illuminating animal \(index)")
                break
            }
        }
    }
    
    private func showAnimalTimer(for index: Int) {
        guard index < animals.count, index < animalUIs.count else { return }
        
        // Показываем таймер и прогресс-бар для освещенного животного
        let ui = animalUIs[index]
        ui.clock.isHidden = false
        ui.timeLabel.isHidden = false
        ui.progressBar.isHidden = false
        // Сразу выставляем корректные позиции/размеры, чтобы избежать мерцания в (0,0)
        updateTimerUI(for: index)
        
        print("[GameScene] Showing timer for animal \(index)")
    }
    
    private func hideAnimalTimer(for index: Int) {
        guard index < animals.count, index < animalUIs.count else { return }
        
        // Скрываем таймер и прогресс-бар
        let ui = animalUIs[index]
        ui.clock.isHidden = true
        ui.timeLabel.isHidden = true
        ui.progressBar.isHidden = true
        
        print("[GameScene] Hiding timer for animal \(index)")
    }
    
    private func generateRandomSequences() {
        animalSequences.removeAll()
        animalTargetSequences.removeAll()
        animalCurrentTapIndex.removeAll()
        animalSequenceOrder.removeAll()
        animalCurrentSequenceIndex.removeAll()
        animalSequenceAnimationTimer.removeAll()
        
        for _ in 0..<animals.count {
            // Генерируем 5 цветов (4 разных + 1 повторяющийся) для кругов (текущее состояние)
            let currentSequence = generateFiveColorSequence()
            animalSequences.append(currentSequence)
            
            // Генерируем целевую последовательность (правильную)
            let targetSequence = generateFiveColorSequence()
            animalTargetSequences.append(targetSequence)
            
            // Генерируем случайный порядок показа больших шаров (все 5 позиций в случайном порядке)
            let sequenceOrder = Array(0..<5).shuffled()
            animalSequenceOrder.append(sequenceOrder)
            
            animalCurrentTapIndex.append(0) // начинаем с первого шара
            animalCurrentSequenceIndex.append(0) // начинаем анимацию с первого шара
            animalSequenceAnimationTimer.append(0) // таймер анимации
        }
        
        print("[GameScene] Generated current sequences: \(animalSequences)")
        print("[GameScene] Generated target sequences: \(animalTargetSequences)")
        print("[GameScene] Generated sequence orders: \(animalSequenceOrder)")
    }
    
    private func generateFiveColorSequence() -> [String] {
        // Берем все 4 цвета
        var sequence = availableColors
        // Добавляем один случайный цвет повторно
        let randomColor = availableColors.randomElement()!
        sequence.append(randomColor)
        // Перемешиваем
        return sequence.shuffled()
    }
    
    
    // MARK: - Helper functions
    private func createGradientProgressBar(size: CGSize) -> SKSpriteNode {
        // Создаем изображение с градиентом
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Создаем градиент от фиолетового к зеленому
            let colors = [
                UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0).cgColor, // светло-фиолетовый
                UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0).cgColor, // красный
                UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0).cgColor, // оранжевый
                UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0).cgColor  // зеленый
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 0.33, 0.66, 1.0])!
            
            // Рисуем закругленный прямоугольник с градиентом
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size.height / 3)
            cgContext.addPath(path.cgPath)
            cgContext.clip()
            
            cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: 0), options: [])
        }
        
        let progressBar = SKSpriteNode(texture: SKTexture(image: image))
        return progressBar
    }
    
    // MARK: - Visibility control
    private func showAllAnimalsAsDark() {
        // Показываем всех животных в темном состоянии (без панелей и таймеров)
        for i in 0..<animals.count {
            guard i < animalUIs.count, i < animalVisible.count else { continue }
            guard !animalVanish[i] else { continue } // Не показываем исчезнувших
            
            animalVisible[i] = true
            animalActive[i] = false // Темное состояние
            animals[i].isHidden = false
            
            // Скрываем панели и таймеры
            let ui = animalUIs[i]
            ui.panel.isHidden = true
            ui.clock.isHidden = true
            ui.timeLabel.isHidden = true
            ui.progressBar.isHidden = true
            for dot in ui.dots { dot.isHidden = true }
        }
    }
    
    private func showAllAnimals() {
        // Показываем всех животных в активном состоянии (с панелями и таймерами)
        for i in 0..<animals.count {
            guard i < animalUIs.count, i < animalVisible.count else { continue }
            guard !animalVanish[i] else { continue } // Не показываем исчезнувших
            
            animalVisible[i] = true
            animalActive[i] = true // Активное состояние
            animals[i].isHidden = false
            
            // Показываем только панели (без таймеров)
            let ui = animalUIs[i]
            ui.panel.isHidden = false
            ui.clock.isHidden = true
            ui.timeLabel.isHidden = true
            ui.progressBar.isHidden = true
            for dot in ui.dots { dot.isHidden = false }
        }
    }
    
    private func activateAnimal(at index: Int) {
        guard index < animals.count, index < animalUIs.count, index < animalActive.count else { return }
        guard !animalVanish[index] else { return }
        
        // Переключаем на светлую версию животного
        let lightName = animalNames[index]
        let lightAssetExists = UIImage(named: lightName) != nil
        let imageName = lightAssetExists ? lightName : "logo_image "
        
        let newTexture = SKTexture(imageNamed: imageName)
        animals[index].texture = newTexture
        
        // Активируем животное
        animalActive[index] = true
        animalVisible[index] = true
        
        // Показываем только панель с цветами (без таймера и прогресс-бара)
        let ui = animalUIs[index]
        ui.panel.isHidden = false
        ui.clock.isHidden = true
        ui.timeLabel.isHidden = true
        ui.progressBar.isHidden = true
        for dot in ui.dots { dot.isHidden = false }
        
        // Запускаем логику показа последовательности
        startSequenceShow(for: index)
        
        print("[GameScene] Animal \(index) activated")
    }
    
    private func startSequenceShow(for index: Int) {
        guard index < animalTargetSequences.count else { return }
        
        // Показываем целевую последовательность (копируем массив)
        animalSequences[index] = Array(animalTargetSequences[index])
        updateAnimalUI(for: index)
        
        // Устанавливаем флаг показа последовательности
        animalShowingSequence[index] = true
        animalSequenceTimer[index] = 50.0 // 25 секунд показа (5 шаров * 4 сек + буфер)
        
        // Запускаем анимацию последовательности
        animalCurrentSequenceIndex[index] = 0
        animalSequenceAnimationTimer[index] = 0
        
        print("[GameScene] Showing sequence animation for animal \(index): \(animalSequenceOrder[index])")
    }
    
    private func shuffleSequence(for index: Int) {
        guard index < animalSequences.count else { return }
        
        // НЕ перемешиваем последовательность - оставляем как есть
        // animalSequences[index] остается неизменной
        
        // Сбрасываем флаг показа последовательности
        animalShowingSequence[index] = false
        
        print("[GameScene] Sequence preserved for animal \(index): \(animalSequences[index])")
    }
    
    private func updateSequenceAnimation(for index: Int, deltaTime: TimeInterval) {
        guard index < animalSequenceAnimationTimer.count && index < animalCurrentSequenceIndex.count else { return }
        guard animalShowingSequence[index] else { return }
        
        animalSequenceAnimationTimer[index] += deltaTime
        
        // Каждый шар показывается 4 секунды
        let timePerDot: TimeInterval = 10
        let totalTime = timePerDot * 5 // 5 шаров
        
        if animalSequenceAnimationTimer[index] >= totalTime {
            // Анимация завершена - сбрасываем флаг показа
            animalShowingSequence[index] = false
            animalCurrentSequenceIndex[index] = 0
            print("[GameScene] Sequence animation completed for animal \(index)")
        } else {
            // Обновляем текущий индекс анимации
            let newIndex = Int(animalSequenceAnimationTimer[index] / timePerDot)
            if newIndex != animalCurrentSequenceIndex[index] {
                animalCurrentSequenceIndex[index] = newIndex
                print("[GameScene] Animation step \(newIndex) for animal \(index)")
            }
        }
    }
    
    private func checkSequenceMatch(for index: Int) {
        guard index < animalSequences.count && index < animalTargetSequences.count else { return }
        
        let currentSequence = animalSequences[index]
        let targetSequence = animalTargetSequences[index]
        let currentTapIndex = index < animalCurrentTapIndex.count ? animalCurrentTapIndex[index] : 0
        
        // Проверяем, завершена ли последовательность тапов (все 5 шаров нажаты)
        if currentTapIndex >= 5 {
            print("[GameScene] Complete sequence tapped for animal \(index)!")
            
            // Продлеваем таймер животного на 10 секунд
            if index < animalTimers.count {
                animalTimers[index] += 10
            }
            
            // Скрываем животное (возвращаем в темное состояние)
            hideAnimal(at: index)
        } else {
            print("[GameScene] Animal \(index) - tapped \(currentTapIndex)/5 dots")
        }
    }
    
    private func hideAnimal(at index: Int) {
        guard index < animals.count, index < animalUIs.count else { return }
        
        // Переключаем на темную версию животного
        let darkName = animalDarkNames[index]
        let darkAssetExists = UIImage(named: darkName) != nil
        let imageName = darkAssetExists ? darkName : "logo_image "
        
        let newTexture = SKTexture(imageNamed: imageName)
        animals[index].texture = newTexture
        
        // Деактивируем животное
        animalActive[index] = false
        
        // Скрываем панель
        let ui = animalUIs[index]
        ui.panel.isHidden = true
        for dot in ui.dots { dot.isHidden = true }
        
        // Сбрасываем флаги последовательности
        animalShowingSequence[index] = false
        animalSequenceTimer[index] = 0
        
        print("[GameScene] Animal \(index) hidden")
    }
    
    private func showAnimalSkin(at index: Int) {
        guard index < animals.count, index < animalActive.count else { return }
        
        // Меняем только скин на светлую версию (без активации панели)
        // Но только если животное еще не активно (не имеет панели)
        if !animalActive[index] {
            let lightName = animalNames[index]
            animals[index].texture = SKTexture(imageNamed: lightName)
            print("[GameScene] Animal \(index) skin shown (light version)")
        } else {
            print("[GameScene] Animal \(index) already active, keeping current skin")
        }
    }
    
    private func hideAnimalSkin(at index: Int) {
        guard index < animals.count, index < animalActive.count else { return }
        
        // Меняем скин обратно на темную версию
        let darkName = animalDarkNames[index]
        animals[index].texture = SKTexture(imageNamed: darkName)
        
        print("[GameScene] Animal \(index) skin hidden (dark version)")
    }
    
    private func hideAllAnimals() {
        for i in 0..<animals.count {
            if i < animalVisible.count {
                animalVisible[i] = false
            }
            animals[i].isHidden = true
            if i < animalUIs.count {
                let ui = animalUIs[i]
                ui.panel.isHidden = true
                ui.clock.isHidden = true
                ui.timeLabel.isHidden = true
                ui.progressBar.isHidden = true
                for dot in ui.dots { dot.isHidden = true }
            }
        }
    }
    
    private func updateAnimalUI(for index: Int) {
        guard index < animalUIs.count && index < animalSequences.count else { return }
        
        let ui = animalUIs[index]
        let sequence = animalSequences[index]
        let isShowingSequence = index < animalShowingSequence.count ? animalShowingSequence[index] : false
        let currentSequenceIndex = index < animalCurrentSequenceIndex.count ? animalCurrentSequenceIndex[index] : 0
        let sequenceOrder = index < animalSequenceOrder.count ? animalSequenceOrder[index] : []
        
        // Обновляем цветные круги согласно последовательности (5 цветов)
        for (i, dot) in ui.dots.enumerated() {
            if i < sequence.count {
                let colorName = sequence[i]
                dot.texture = SKTexture(imageNamed: colorName)
                
                // Устанавливаем размер шара
                var dotSize: CGFloat = frame.height * 0.08 // размер, чтобы поместились в панель
                
                if isShowingSequence && currentSequenceIndex < sequenceOrder.count {
                    // Проверяем, является ли текущий шар тем, который должен увеличиваться в данный момент
                    let currentSequenceDotIndex = sequenceOrder[currentSequenceIndex]
                    if i == currentSequenceDotIndex {
                        // Большой шар в анимации последовательности
                        dotSize = frame.height * 0.12
                    }
                }
                
                dot.size = CGSize(width: dotSize, height: dotSize)
            }
        }
        
        // Кастомные сегменты прогресс-бара остаются фиксированными
        // (фиолетовый, красный, оранжевый, зеленый)
    }
    
    private func layoutAnimals() {
        guard !animals.isEmpty else { return }
        
        // Инициализируем массивы если не инициализированы
        if animalVisible.isEmpty {
            animalVisible = Array(repeating: false, count: animals.count)
        }
        if animalActive.isEmpty {
            animalActive = Array(repeating: false, count: animals.count)
        }
        if animalFirstAppearance.isEmpty {
            animalFirstAppearance = Array(repeating: false, count: animals.count)
        }
        if animalVanish.isEmpty {
            animalVanish = Array(repeating: false, count: animals.count)
        }
        if animalShowingSequence.isEmpty {
            animalShowingSequence = Array(repeating: false, count: animals.count)
        }
        if animalSequenceTimer.isEmpty {
            animalSequenceTimer = Array(repeating: 0, count: animals.count)
        }
        if animalCurrentTapIndex.isEmpty {
            animalCurrentTapIndex = Array(repeating: 0, count: animals.count)
        }
        if animalSequenceOrder.isEmpty {
            animalSequenceOrder = Array(repeating: [], count: animals.count)
        }
        if animalCurrentSequenceIndex.isEmpty {
            animalCurrentSequenceIndex = Array(repeating: 0, count: animals.count)
        }
        if animalSequenceAnimationTimer.isEmpty {
            animalSequenceAnimationTimer = Array(repeating: 0, count: animals.count)
        }
        
        let centerX = frame.midX
        let centerY = frame.midY
        let radius = min(frame.width, frame.height) * 0.35
        let angles: [CGFloat] = [0, 72, 144, 216, 288]
        
        let panelWidth = min(frame.width, frame.height) * 0.40 // увеличиваем ширину панели
        let panelHeight = panelWidth * 0.35 // увеличиваем высоту панели
        let dotSize = panelHeight * 0.7
        let panelOffsetY = frame.height * 0.11 // на сколько выше животного ставим панель
        let timerOffsetY = frame.height * 0.18 // на сколько выше животного ставим таймер
        
        for (index, animal) in animals.enumerated() {
            let angle = angles[index] * .pi / 180
            let x = centerX + radius * cos(angle)
            var y = centerY + radius * sin(angle)
            
            // Сместим обезьяну (index 1) ниже, чтобы UI не выходил за экран
            if index == 1 {
                y += -frame.height * 0.10
            }
            
            animal.position = CGPoint(x: x, y: y)
            if let texture = animal.texture {
                let targetHeight = frame.height * 0.25  // увеличили с 0.15 до 0.25
                let scale = max(0.01, targetHeight / texture.size().height)
                animal.xScale = scale
                animal.yScale = scale
            }
            
            // Панель и кружки (только для активных животных)
            let ui = animalUIs[index]
            let isActive = index < animalActive.count ? animalActive[index] : false
            
            ui.panel.size = CGSize(width: panelWidth, height: panelHeight)
            ui.panel.position = CGPoint(x: x, y: y + panelOffsetY)
            ui.panel.isHidden = !isActive
            
            let spacing = panelWidth * 0.18 // расстояние между кругами, чтобы поместились в панель
            let startX = ui.panel.position.x - (2.0 * spacing) // центрируем 5 кругов
            for (i, dot) in ui.dots.enumerated() {
                // Не перезаписываем размер, если он уже установлен в updateAnimalUI
                if dot.size.width == 0 || dot.size.height == 0 {
                    dot.size = CGSize(width: dotSize, height: dotSize)
                }
                dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: ui.panel.position.y + panelHeight * 0.10)
                dot.isHidden = !isActive
            }
            
            // Таймер и прогресс-бар показываются только для освещенного животного
            let isIlluminated = (index == spotlightTargetIndex)
            ui.clock.isHidden = !isIlluminated
            ui.timeLabel.isHidden = !isIlluminated
            ui.progressBar.isHidden = !isIlluminated
            
            // Если животное освещено, обновляем позицию таймера
            if isIlluminated {
                updateTimerUI(for: index)
            }
            
            // Обновляем UI с рандомными последовательностями
            updateAnimalUI(for: index)
        }
        
        clownNode?.position = CGPoint(x: frame.midX, y: frame.midY + clownOffsetY)
        if let texture = clownNode?.texture {
            let targetHeight = frame.height * 0.20
            let scale = max(0.01, targetHeight / texture.size().height)
            clownNode?.xScale = scale
            clownNode?.yScale = scale
        }
    }

    // Отдельно обновляем геометрию таймера/прогресс-бара для конкретного животного
    private func updateTimerUI(for index: Int) {
        guard index < animals.count, index < animalUIs.count else { return }
        let ui = animalUIs[index]
        let centerX = frame.midX
        let centerY = frame.midY
        let radius = min(frame.width, frame.height) * 0.35
        let angles: [CGFloat] = [0, 72, 144, 216, 288]
        let angle = angles[index] * .pi / 180
        let x = centerX + radius * cos(angle)
        var y = centerY + radius * sin(angle)
        if index == 1 {
            y += -frame.height * 0.10
        }
        let panelWidth = min(frame.width, frame.height) * 0.40
        let panelHeight = panelWidth * 0.35
        let timerOffsetY = frame.height * 0.18
        let timerY = y + timerOffsetY
        let clockSize = frame.height * 0.08
        ui.clock.size = CGSize(width: clockSize, height: clockSize)
        ui.clock.position = CGPoint(x: x - panelWidth * 0.35, y: timerY)
        let barWidth = panelWidth * 0.5
        let barHeight = frame.height * 0.03
        let progressStartX = ui.clock.position.x + (ui.clock.size.width * 0.6) + 5
        let remainingTime = animalTimers[index]
        let totalTime = 30
        let progress = max(0, CGFloat(remainingTime) / CGFloat(totalTime))
        let currentWidth = barWidth * progress
        ui.progressBar.size = CGSize(width: currentWidth, height: barHeight)
        ui.progressBar.position = CGPoint(x: progressStartX + currentWidth / 2, y: timerY)
        ui.timeLabel.text = String(format: "%02d:%02d", animalTimers[index] / 60, animalTimers[index] % 60)
        ui.timeLabel.horizontalAlignmentMode = .center
        ui.timeLabel.verticalAlignmentMode = .center
        ui.timeLabel.fontSize = max(14, frame.height * 0.025)
        ui.timeLabel.position = CGPoint(x: progressStartX + barWidth / 2, y: timerY + barHeight * 1.2)
    }
    
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        backgroundNode?.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode?.size = size
        
        if !isSceneSetup, size.width > 0, size.height > 0 {
            print("[GameScene] didChangeSize -> setupScene, new size=\(size)")
            setupScene()
        } else {
            layoutAnimals()
        }
        print("[GameScene] didChangeSize: old=\(oldSize) new=\(size)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Проверяем нажатие на освещенных животных для активации
        for (index, animal) in animals.enumerated() {
            if !animalVisible.indices.contains(index) || !animalVisible[index] { continue }
            if animalActive.indices.contains(index) && animalActive[index] { continue } // Уже активное
            if spotlightTargetIndex != index { continue } // Только освещенные животные
            
            if animal.contains(location) {
                print("[GameScene] Touched illuminated animal \(index), activating...")
                activateAnimal(at: index)
                return
            }
        }
        
        // Проверяем нажатие на цветные круги (только для активных животных)
        for (index, ui) in animalUIs.enumerated() {
            if !animalVisible.indices.contains(index) || !animalVisible[index] { continue }
            if !animalActive.indices.contains(index) || !animalActive[index] { continue } // Только активные
            
            for (i, dot) in ui.dots.enumerated() {
                if dot.contains(location) {
                    // Проверяем, правильная ли это позиция в последовательности
                    let currentTapIndex = index < animalCurrentTapIndex.count ? animalCurrentTapIndex[index] : 0
                    let sequenceOrder = index < animalSequenceOrder.count ? animalSequenceOrder[index] : []
                    
                    if currentTapIndex < sequenceOrder.count {
                        // Проверяем, совпадает ли позиция текущего шара с нужной позицией в последовательности
                        let expectedPosition = sequenceOrder[currentTapIndex]
                        
                        if i == expectedPosition {
                            // Правильная позиция - переходим к следующему
                            animalCurrentTapIndex[index] = currentTapIndex + 1
                            print("[GameScene] Correct tap \(currentTapIndex + 1) for animal \(index) - position: \(i)")
                            
                            // Проверяем, завершена ли последовательность
                            checkSequenceMatch(for: index)
                        } else {
                            // Неправильная позиция - сбрасываем последовательность
                            animalCurrentTapIndex[index] = 0
                            print("[GameScene] Wrong tap for animal \(index) - expected position \(expectedPosition), got \(i), resetting")
                        }
                    }
                    return
                }
            }
        }
    }
    
    
    // MARK: - Timer loop
    override func update(_ currentTime: TimeInterval) {
        guard !isPausedByUser && !gameEnded else { return }
        if lastUpdateTime == 0 { lastUpdateTime = currentTime; return }
        let dt = currentTime - lastUpdateTime
        
        // Обновляем вращение прожектора каждый кадр
        updateSpotlightRotation()
        
        // Обновляем хаотичные прожекторы каждый кадр
        updateChaoticSpotlights()
        
        // Обновляем анимацию последовательности каждый кадр
        for i in 0..<animalSequenceAnimationTimer.count {
            updateSequenceAnimation(for: i, deltaTime: dt)
        }
        
        // Обновляем UI каждый кадр для плавной анимации
        for i in 0..<animals.count {
            updateAnimalUI(for: i)
        }
        
        if dt >= 1.0 {
            lastUpdateTime = currentTime
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
            
            // Обновляем таймеры животных
            for i in 0..<animalTimers.count {
                if animalTimers[i] > 0 {
                    animalTimers[i] -= 1
                }
            }
            
            // Обрабатываем таймеры показа последовательности
            for i in 0..<animalSequenceTimer.count {
                if animalShowingSequence[i] && animalSequenceTimer[i] > 0 {
                    animalSequenceTimer[i] -= 1.0
                    if animalSequenceTimer[i] <= 0 {
                        // Время показа истекло - перемешиваем последовательность
                        shuffleSequence(for: i)
                    }
                }
            }
            
            // Перерисовываем UI
            layoutAnimals()
            
            // Проверяем условия победы/поражения
            checkGameEndConditions()
        }
    }
    
    private func checkGameEndConditions() {
        guard !gameEnded else { return }
        
        // Проверяем победу: время вышло (1:30 = 90 секунд)
        if remainingSeconds <= 0 {
            print("[GameScene] WIN: Time's up!")
            gameEnded = true
            showWinAlert = true
            return
        }
        
        // Проверяем победу: все животные исчезли
        let allAnimalsVanished = animalVanish.allSatisfy { $0 }
        if allAnimalsVanished {
            print("[GameScene] WIN: All animals vanished!")
            gameEnded = true
            showWinAlert = true
            return
        }
        
        // Проверяем поражение: есть животные, которые не исчезли и их таймер = 0
        for i in 0..<animalTimers.count {
            if !animalVanish[i] && animalTimers[i] <= 0 {
                print("[GameScene] LOSE: Animal \(i) timer expired!")
                gameEnded = true
                showLoseAlert = true
                return
            }
        }
    }
    
    func setPausedByUser(_ paused: Bool) {
        isPausedByUser = paused
        self.isPaused = paused
    }
    
    // MARK: - Game reset
    func resetGame() {
        gameEnded = false
        showWinAlert = false
        showLoseAlert = false
        remainingSeconds = 90
        animalTimers = [30, 30, 30, 30, 30]
        animalVanish = Array(repeating: false, count: animals.count)
        animalVisible = Array(repeating: false, count: animals.count)
        animalActive = Array(repeating: false, count: animals.count)
        animalFirstAppearance = Array(repeating: false, count: animals.count)
        animalShowingSequence = Array(repeating: false, count: animals.count)
        animalSequenceTimer = Array(repeating: 0, count: animals.count)
        animalCurrentTapIndex = Array(repeating: 0, count: animals.count)
        animalSequenceOrder = Array(repeating: [], count: animals.count)
        animalCurrentSequenceIndex = Array(repeating: 0, count: animals.count)
        animalSequenceAnimationTimer = Array(repeating: 0, count: animals.count)
        
        // Сбрасываем состояние прожекторов
        spotlightTargetIndex = -1
        spotlightAngle = 0
        
        // Сбрасываем хаотичные прожекторы
        for i in 0..<chaoticSpotlightPositions.count {
            let arenaRadius = min(frame.width, frame.height) * 0.35
            let centerX = frame.midX
            let centerY = frame.midY
            let angle = Double.random(in: 0...(2 * Double.pi))
            let distance = Double.random(in: 0...Double(arenaRadius))
            
            chaoticSpotlightPositions[i] = CGPoint(
                x: centerX + CGFloat(distance * cos(angle)),
                y: centerY + CGFloat(distance * sin(angle))
            )
            chaoticSpotlightVelocities[i] = CGPoint.zero
            chaoticSpotlightChangeTimers[i] = 0
            generateNewChaoticTarget(for: i)
        }
        
        // Показываем прожектор (он всегда видим)
        for spotlight in animalSpotlights {
            spotlight.isHidden = false
        }
        
        // Показываем всех животных в темном состоянии
        showAllAnimalsAsDark()
        
        print("[GameScene] Game reset")
    }
    
    func updateSkin() {
        let selectedSkin = skinManager.getCurrentSkinSprite()
        currentSkinSprite = selectedSkin
        // Обновляем спрайт клоуна
        if let clown = clownNode {
            let newTexture = SKTexture(imageNamed: selectedSkin)
            if newTexture != nil {
                clown.texture = newTexture
                print("[GameScene] Skin updated to: \(selectedSkin)")
            }
        }
    }
    
    // MARK: - Public functions for animal activation
    func activateAnimalPublic(at index: Int) {
        activateAnimal(at: index)
    }
    
    func isAnimalActive(at index: Int) -> Bool {
        guard index < animalActive.count else { return false }
        return animalActive[index]
    }
    
}

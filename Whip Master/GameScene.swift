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
    
    // MARK: - Spotlights
    private var animalSpotlights: [SKSpriteNode] = [] // прожектор для каждого животного
    private var spotlightTargetIndex: Int = -1 // на какое животное направлен прожектор
    private var spotlightTimer: TimeInterval = 0
    private var spotlightChangeInterval: TimeInterval = 3.0 // интервал смены направления (3 секунды)
    private var spotlightAngle: CGFloat = 0 // текущий угол прожектора
    private var spotlightRotationSpeed: CGFloat = 0.02 // скорость вращения прожектора (радиан за кадр)
    
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
            
            // UI: панель + 4 цветные круги
            let panel = SKSpriteNode(imageNamed: "panelColor_panel")
            panel.zPosition = 12
            addChild(panel)
            
            let colors = ["red_circle", "yellow_circle", "blue_circle", "green_circle"]
            var dots: [SKSpriteNode] = []
            for colorName in colors {
                let dot = SKSpriteNode(imageNamed: colorName)
                dot.zPosition = 13
                addChild(dot)
                dots.append(dot)
            }
            
            // Таймер: часы + время + прогресс-бар
            let clock = SKSpriteNode(imageNamed: "clock_icon")
            clock.zPosition = 14
            addChild(clock)
            
            let timeLabel = SKLabelNode(fontNamed: "Arial-Bold")
            timeLabel.text = "00:30"
            timeLabel.fontSize = 24
            timeLabel.fontColor = .white
            timeLabel.zPosition = 15
            addChild(timeLabel)
            
            // Простой градиентный прогресс-бар
            let progressBar = createGradientProgressBar(size: CGSize(width: 100, height: 20))
            progressBar.zPosition = 14
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
        
        // Очищаем массив прожекторов
        animalSpotlights.removeAll()
        
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
        
        print("[GameScene] Rotating spotlight created at position: \(spotlight.position)")
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
        
        for _ in 0..<animals.count {
            // Генерируем РАЗНЫЕ 4 цвета в случайном порядке для кругов (текущее состояние)
            let currentSequence = Array(availableColors.shuffled().prefix(4))
            animalSequences.append(currentSequence)
            
            // Генерируем целевую последовательность (правильную)
            let targetSequence = Array(availableColors.shuffled().prefix(4))
            animalTargetSequences.append(targetSequence)
        }
        
        print("[GameScene] Generated current sequences: \(animalSequences)")
        print("[GameScene] Generated target sequences: \(animalTargetSequences)")
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
        
        // Показываем целевую последовательность
        animalSequences[index] = animalTargetSequences[index]
        updateAnimalUI(for: index)
        
        // Устанавливаем флаг показа последовательности
        animalShowingSequence[index] = true
        animalSequenceTimer[index] = 5.0 // 5 секунд показа
        
        print("[GameScene] Showing target sequence for animal \(index): \(animalTargetSequences[index])")
    }
    
    private func shuffleSequence(for index: Int) {
        guard index < animalSequences.count else { return }
        
        // Перемешиваем текущую последовательность
        animalSequences[index] = Array(availableColors.shuffled().prefix(4))
        updateAnimalUI(for: index)
        
        // Сбрасываем флаг показа последовательности
        animalShowingSequence[index] = false
        
        print("[GameScene] Shuffled sequence for animal \(index): \(animalSequences[index])")
    }
    
    private func checkSequenceMatch(for index: Int) {
        guard index < animalSequences.count && index < animalTargetSequences.count else { return }
        
        let currentSequence = animalSequences[index]
        let targetSequence = animalTargetSequences[index]
        
        // Проверяем точное совпадение последовательностей
        let isMatch = currentSequence.elementsEqual(targetSequence) { current, target in
            return current == target
        }
        
        if isMatch {
            print("[GameScene] Sequence match! Animal \(index) gets +10 seconds and hides")
            
            // Продлеваем таймер животного на 10 секунд
            if index < animalTimers.count {
                animalTimers[index] += 10
            }
            
            // Скрываем животное (возвращаем в темное состояние)
            hideAnimal(at: index)
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
        
        // Обновляем цветные круги согласно последовательности (всегда 4 разных цвета)
        for (i, dot) in ui.dots.enumerated() {
            if i < sequence.count {
                let colorName = sequence[i]
                dot.texture = SKTexture(imageNamed: colorName)
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
        
        let centerX = frame.midX
        let centerY = frame.midY
        let radius = min(frame.width, frame.height) * 0.35
        let angles: [CGFloat] = [0, 72, 144, 216, 288]
        
        let panelWidth = min(frame.width, frame.height) * 0.28
        let panelHeight = panelWidth * 0.28
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
            
            let spacing = panelWidth * 0.20
            let startX = ui.panel.position.x - (1.5 * spacing)
            for (i, dot) in ui.dots.enumerated() {
                dot.size = CGSize(width: dotSize, height: dotSize)
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
                let timerY = y + timerOffsetY
                let clockSize = frame.height * 0.08
                ui.clock.size = CGSize(width: clockSize, height: clockSize)
                ui.clock.position = CGPoint(x: x - panelWidth * 0.35, y: timerY)
                
                // Простой градиентный прогресс-бар — правее от часов
                let barWidth = panelWidth * 0.5
                let barHeight = frame.height * 0.03
                let progressStartX = ui.clock.position.x + (ui.clock.size.width * 0.6) + 5
                
                // Анимируем прогресс-бар в зависимости от оставшегося времени
                let remainingTime = animalTimers[index]
                let totalTime = 30
                let progress = max(0, CGFloat(remainingTime) / CGFloat(totalTime))
                let currentWidth = barWidth * progress
                
                // Обновляем размер и позицию прогресс-бара
                ui.progressBar.size = CGSize(width: currentWidth, height: barHeight)
                ui.progressBar.position = CGPoint(x: progressStartX + currentWidth / 2, y: timerY)
                
                // Время — над прогресс-баром
                ui.timeLabel.text = String(format: "%02d:%02d", animalTimers[index] / 60, animalTimers[index] % 60)
                ui.timeLabel.horizontalAlignmentMode = .center
                ui.timeLabel.verticalAlignmentMode = .center
                ui.timeLabel.fontSize = max(14, frame.height * 0.025)
                ui.timeLabel.position = CGPoint(x: progressStartX + barWidth / 2, y: timerY + barHeight * 1.2)
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
        
        // Затем проверяем перетаскивание цветных кругов (только для активных животных)
        for (index, ui) in animalUIs.enumerated() {
            if !animalVisible.indices.contains(index) || !animalVisible[index] { continue }
            if !animalActive.indices.contains(index) || !animalActive[index] { continue } // Только активные
            
            for dot in ui.dots {
                if dot.contains(location) {
                    dot.userData = ["dragging": true, "animalIndex": index]
                    return
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        for ui in animalUIs {
            for dot in ui.dots {
                if dot.userData?["dragging"] as? Bool == true {
                    dot.position = location
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
            let location = touch.location(in: self)
        
        for (index, ui) in animalUIs.enumerated() {
            for (i, dot) in ui.dots.enumerated() {
                if dot.userData?["dragging"] as? Bool == true {
                    dot.userData?["dragging"] = false
                    
                    // Найдём ближайший слот (позицию) среди текущих 4 слотов панели
                    let panelPos = ui.panel.position
                    let panelWidth = ui.panel.size.width
                    let spacing = panelWidth * 0.20
                    let startX = panelPos.x - (1.5 * spacing)
                    var closestIndex = 0
                    var minDist = CGFloat.greatestFiniteMagnitude
                    for slot in 0..<4 {
                        let slotPos = CGPoint(x: startX + CGFloat(slot) * spacing, y: panelPos.y + ui.panel.size.height * 0.10)
                        let d = hypot(slotPos.x - location.x, slotPos.y - location.y)
                        if d < minDist { minDist = d; closestIndex = slot }
                    }
                    
                    // Поменяем местами элементы в массиве animalSequences[index]
                    if i != closestIndex, index < animalSequences.count {
                        var seq = animalSequences[index]
                        if closestIndex < seq.count, i < seq.count {
                            seq.swapAt(i, closestIndex)
                            animalSequences[index] = seq
                        }
                    }
                    
                    // Переложим UI заново по обновлённой последовательности
                    updateAnimalUI(for: index)
                    layoutAnimals()
                    
                    // Проверяем правильность комбинации
                    checkSequenceMatch(for: index)
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
        
        // Сбрасываем состояние прожекторов
        spotlightTargetIndex = -1
        spotlightAngle = 0
        
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

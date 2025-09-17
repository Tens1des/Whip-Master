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
    private struct AnimalUI {
        let panel: SKSpriteNode
        let dots: [SKSpriteNode]
        let clock: SKSpriteNode
        let timeLabel: SKLabelNode
        let progressSegments: [SKSpriteNode]
    }
    private var animalUIs: [AnimalUI] = []
    
    // MARK: - Animal timers
    private var animalTimers: [Int] = [30, 30, 30, 30, 30] // 30 секунд для каждого животного
    private var animalFirstAppearance: [Bool] = [] // флаг первого появления для каждого животного
    private var animalVanish: [Bool] = [] // флаг исчезновения животного навсегда
    
    // MARK: - Animal sequences
    private var animalSequences: [[String]] = [] // последовательности цветов для каждого животного
    private let availableColors = ["red_circle", "yellow_circle", "blue_circle", "green_circle"]
    private let availableProgressColors = ["progress_segment_purple", "progress_segment_red", "progress_segment_orange", "progress_segment_green"]
    private var animalProgressColors: [[String]] = [] // фиксированные цвета прогресс-бара на старт уровня
    private var animalVisible: [Bool] = [] // текущее состояние видимости
    
    // MARK: - Spotlights
    private var spotlights: [SKSpriteNode] = []
    
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
        // Размещаем прожекторы (заморожены)
        // setupSpotlights()
        
        // Инициализируем флаги видимости и скрываем всех по умолчанию
        animalVisible = Array(repeating: false, count: animals.count)
        animalFirstAppearance = Array(repeating: false, count: animals.count)
        animalVanish = Array(repeating: false, count: animals.count)
        hideAllAnimals()
        
        isSceneSetup = true
        
        // Запускаем цикл показа
        startVisibilityLoop()
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
            let assetExists = UIImage(named: rawName) != nil
            let imageName = assetExists ? rawName : "logo_image "
            if !assetExists {
                print("[GameScene] Warning: animal asset not found: \(rawName). Using placeholder \(imageName)")
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
            
            // Масштабируем животное
            if let texture = animal.texture {
                let targetHeight = frame.height * 0.15
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
            
            // Прогресс-бар из 4 сегментов
            let segmentNames = ["progress_segment_purple", "progress_segment_red", "progress_segment_orange", "progress_segment_green"]
            var progressSegments: [SKSpriteNode] = []
            for segmentName in segmentNames {
                let segment = SKSpriteNode(imageNamed: segmentName)
                segment.zPosition = 14
                addChild(segment)
                progressSegments.append(segment)
            }
            
            animalUIs.append(AnimalUI(panel: panel, dots: dots, clock: clock, timeLabel: timeLabel, progressSegments: progressSegments))
            
            print("[GameScene] Animal \(rawName) added at position: \(animal.position), zPosition: \(animal.zPosition)")
        }
        
        print("[GameScene] Total animals added: \(animals.count)")
        
        // Генерируем рандомные последовательности для всех животных
        generateRandomSequences()
        
        layoutAnimals() // выравниваем панели сразу
    }
    
    private func setupSpotlights() {
        print("[GameScene] setupSpotlights called. Frame size: \(frame.size)")
        
        let centerX = frame.midX
        let centerY = frame.midY
        let radius = min(frame.width, frame.height) * 0.35
        let spotlightRadius = min(frame.width, frame.height) * 0.55 // прожекторы дальше от центра
        
        // Позиции для 4 прожекторов (направлены на первые 4 животных)
        let angles: [CGFloat] = [0, 72, 144, 216] // 360/4 = 90 градусов между прожекторами
        
        for (index, angle) in angles.enumerated() {
            let spotlight = SKSpriteNode(imageNamed: "proector_image")
            
            if spotlight.texture == nil {
                print("[GameScene] ERROR: Failed to create spotlight sprite")
                continue
            }
            
            let radianAngle = angle * .pi / 180
            let x = centerX + spotlightRadius * cos(radianAngle)
            let y = centerY + spotlightRadius * sin(radianAngle)
            spotlight.position = CGPoint(x: x, y: y)
            
            // Поворачиваем прожектор к центру (к животному)
            let targetAngle = atan2(centerY - y, centerX - x)
            spotlight.zRotation = targetAngle
            
            // Масштабируем прожектор
            if let texture = spotlight.texture {
                let targetHeight = frame.height * 0.50
                let scale = max(0.01, targetHeight / texture.size().height)
                spotlight.xScale = scale
                spotlight.yScale = scale
                print("[GameScene] Spotlight \(index) texture size: \(texture.size()), scale: \(scale)")
            }
            
            spotlight.zPosition = 8 // между фоном и животными
            spotlight.name = "spotlight_\(index)"
            addChild(spotlight)
            spotlights.append(spotlight)
            
            print("[GameScene] Spotlight \(index) added at position: \(spotlight.position), rotation: \(targetAngle)")
        }
        
        print("[GameScene] Total spotlights added: \(spotlights.count)")
    }
    
    private func generateRandomSequences() {
        animalSequences.removeAll()
        animalProgressColors.removeAll()
        
        for _ in 0..<animals.count {
            // Генерируем РАЗНЫЕ 4 цвета в случайном порядке для кругов
            let sequence = Array(availableColors.shuffled().prefix(4))
            animalSequences.append(sequence)
            
            // Генерируем фиксированный порядок цветов прогресс-бара (тоже перемешанный один раз)
            let progress = availableProgressColors.shuffled()
            animalProgressColors.append(progress)
        }
        
        print("[GameScene] Generated sequences: \(animalSequences)")
        print("[GameScene] Generated progress colors: \(animalProgressColors)")
    }
    
    // MARK: - Visibility control
    private func startVisibilityLoop() {
        // Периодически (каждые 5 сек) выбираем 1–2 случайных животных для показа
        let wait = SKAction.wait(forDuration: 5.0)
        let cycle = SKAction.run { [weak self] in
            guard let self else { return }
            let countToShow = Int.random(in: 1...2)
            var indices = Array(0..<self.animals.count).shuffled()
            // Исключаем исчезнувших животных
            indices = indices.filter { !self.animalVanish[$0] }
            indices = Array(indices.prefix(countToShow))
            self.showAnimals(indices: indices)
        }
        let sequence = SKAction.sequence([wait, cycle])
        run(SKAction.repeatForever(sequence), withKey: "visibilityLoop")
    }
    
    private func showAnimals(indices: [Int]) {
        hideAllAnimals()
        
        for i in indices {
            guard i < animals.count, i < animalUIs.count, i < animalVisible.count else { continue }
            guard !animalVanish[i] else { continue } // Не показываем исчезнувших
            
            // Если это первое появление животного - сбрасываем таймер
            if i < animalFirstAppearance.count && !animalFirstAppearance[i] {
                animalTimers[i] = 30
                animalFirstAppearance[i] = true
                print("[GameScene] First appearance for animal \(i), timer reset to 30")
            }
            
            animalVisible[i] = true
            animals[i].isHidden = false
            let ui = animalUIs[i]
            ui.panel.isHidden = false
            ui.clock.isHidden = false
            ui.timeLabel.isHidden = false
            for dot in ui.dots { dot.isHidden = false }
            for seg in ui.progressSegments { seg.isHidden = false }
        }
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
                for dot in ui.dots { dot.isHidden = true }
                for seg in ui.progressSegments { seg.isHidden = true }
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
        
        // Устанавливаем цвета прогресс-бара, сгенерированные на старте уровня
        if index < animalProgressColors.count {
            let progressColors = animalProgressColors[index]
            for (i, segment) in ui.progressSegments.enumerated() {
                if i < progressColors.count {
                    segment.texture = SKTexture(imageNamed: progressColors[i])
                }
            }
        }
    }
    
    private func layoutAnimals() {
        guard !animals.isEmpty else { return }
        
        // Инициализируем animalVisible если не инициализирован
        if animalVisible.isEmpty {
            animalVisible = Array(repeating: false, count: animals.count)
        }
        if animalFirstAppearance.isEmpty {
            animalFirstAppearance = Array(repeating: false, count: animals.count)
        }
        if animalVanish.isEmpty {
            animalVanish = Array(repeating: false, count: animals.count)
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
                let targetHeight = frame.height * 0.15
                let scale = max(0.01, targetHeight / texture.size().height)
                animal.xScale = scale
                animal.yScale = scale
            }
            
            // Панель и кружки
            let ui = animalUIs[index]
            ui.panel.size = CGSize(width: panelWidth, height: panelHeight)
            ui.panel.position = CGPoint(x: x, y: y + panelOffsetY)
            
            let spacing = panelWidth * 0.20
            let startX = ui.panel.position.x - (1.5 * spacing)
            for (i, dot) in ui.dots.enumerated() {
                dot.size = CGSize(width: dotSize, height: dotSize)
                dot.position = CGPoint(x: startX + CGFloat(i) * spacing, y: ui.panel.position.y + panelHeight * 0.10)
            }
            
            // Таймер: часы + время + прогресс-бар
            let timerY = y + timerOffsetY
            let clockSize = frame.height * 0.08
            ui.clock.size = CGSize(width: clockSize, height: clockSize)
            ui.clock.position = CGPoint(x: x - panelWidth * 0.35, y: timerY)
            
            // Прогресс-бар из 4 сегментов — сразу справа от часов
            let segmentWidth = panelWidth * 0.15
            let segmentHeight = frame.height * 0.03
            let segmentSpacing = segmentWidth * 0.1
            let progressStartX = ui.clock.position.x + (ui.clock.size.width * 0.6) + segmentSpacing
            let totalBarWidth = (segmentWidth * 4) + (segmentSpacing * 3)
            
            for (i, segment) in ui.progressSegments.enumerated() {
                segment.size = CGSize(width: segmentWidth, height: segmentHeight)
                let segmentX = progressStartX + CGFloat(i) * (segmentWidth + segmentSpacing)
                segment.position = CGPoint(x: segmentX, y: timerY)
                
            // Скрываем сегменты по мере истечения времени, но только если животное видимо
            let remainingTime = animalTimers[index]
            let totalTime = 30
            let visibleSegments = max(1, Int(4 * remainingTime / totalTime))
            let isAnimalVisible = index < animalVisible.count ? animalVisible[index] : false
            segment.isHidden = !isAnimalVisible || i >= visibleSegments
            }
            
            // Время — над началом прогресс-бара (над первым сегментом)
            ui.timeLabel.text = String(format: "%02d:%02d", animalTimers[index] / 60, animalTimers[index] % 60)
            ui.timeLabel.horizontalAlignmentMode = .center
            ui.timeLabel.verticalAlignmentMode = .center
            ui.timeLabel.fontSize = max(14, frame.height * 0.025) // уменьшил размер шрифта
            ui.timeLabel.position = CGPoint(x: progressStartX + segmentWidth / 2, y: timerY + segmentHeight * 1.2)
            
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
    
    private func layoutSpotlights() {
        guard !spotlights.isEmpty else { return }
        let centerX = frame.midX
        let centerY = frame.midY
        let spotlightRadius = min(frame.width, frame.height) * 0.55
        let angles: [CGFloat] = [0, 72, 144, 216]
        
        for (index, spotlight) in spotlights.enumerated() {
            let angle = angles[index] * .pi / 180
            let x = centerX + spotlightRadius * cos(angle)
            let y = centerY + spotlightRadius * sin(angle)
            spotlight.position = CGPoint(x: x, y: y)
            
            // Поворачиваем прожектор к центру
            let targetAngle = atan2(centerY - y, centerX - x)
            spotlight.zRotation = targetAngle
            
            if let texture = spotlight.texture {
                let targetHeight = frame.height * 0.20
                let scale = max(0.01, targetHeight / texture.size().height)
                spotlight.xScale = scale
                spotlight.yScale = scale
            }
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
            // layoutSpotlights() // заморожены
        }
        print("[GameScene] didChangeSize: old=\(oldSize) new=\(size)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Перетаскивание цветных кругов
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Ищем, на какой точке нажали
        for (index, ui) in animalUIs.enumerated() {
            if !animalVisible.indices.contains(index) || !animalVisible[index] { continue }
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
                    
                    // Проверяем совпадение цветов прогресс-бара и панели
                    checkColorMatch(for: index)
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
        animalFirstAppearance = Array(repeating: false, count: animals.count)
        
        // Останавливаем текущий цикл и запускаем новый
        removeAction(forKey: "visibilityLoop")
        hideAllAnimals()
        startVisibilityLoop()
        
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
    
    
    // MARK: - Color matching
    private func checkColorMatch(for animalIndex: Int) {
        guard animalIndex < animalSequences.count && animalIndex < animalProgressColors.count else { return }
        
        let panelColors = animalSequences[animalIndex]
        let progressColors = animalProgressColors[animalIndex]
        
        // Маппинг цветов: progress_segment -> panel_circle
        let colorMapping: [String: String] = [
            "progress_segment_purple": "blue_circle",
            "progress_segment_red": "red_circle", 
            "progress_segment_orange": "yellow_circle",
            "progress_segment_green": "green_circle"
        ]
        
        // Проверяем точное совпадение последовательностей
        let isMatch = panelColors.elementsEqual(progressColors) { panelColor, progressColor in
            let mappedProgressColor = colorMapping[progressColor] ?? progressColor
            return panelColor == mappedProgressColor
        }
        
        if isMatch {
            print("[GameScene] Color match! Animal \(animalIndex) vanishes forever")
            print("[GameScene] Panel: \(panelColors), Progress: \(progressColors)")
            animalVanish[animalIndex] = true
            animalVisible[animalIndex] = false
            
            // Скрываем животное и его UI
            animals[animalIndex].isHidden = true
            let ui = animalUIs[animalIndex]
            ui.panel.isHidden = true
            ui.clock.isHidden = true
            ui.timeLabel.isHidden = true
            for dot in ui.dots { dot.isHidden = true }
            for seg in ui.progressSegments { seg.isHidden = true }
        }
    }
}

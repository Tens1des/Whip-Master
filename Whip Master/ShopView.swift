//
//  ShopView.swift
//  Whip Master
//
//  Created by Рома Котов on 16.09.2025.
//

import SwiftUI

// MARK: - Skin Model
struct Skin {
    let id: Int
    let name: String
    let iconName: String
    let gameSpriteName: String
    let price: Int
    var isPurchased: Bool
    var isSelected: Bool
}

// MARK: - Skin Manager
class SkinManager: ObservableObject {
    @Published var skins: [Skin] = []
    @Published var selectedSkinId: Int = 4 // По умолчанию clown_default (4-й скин)
    @Published var coins: Int = 500 // Начальные монеты
    
    static let shared = SkinManager() // Singleton для доступа из любой части приложения
    
    init() {
        setupSkins()
    }
    
    private func setupSkins() {
        skins = [
            Skin(id: 1, name: "Skin 1", iconName: "skin1_icon", gameSpriteName: "skin1", price: 100, isPurchased: false, isSelected: false),
            Skin(id: 2, name: "Skin 2", iconName: "skin2_icon", gameSpriteName: "skin2", price: 150, isPurchased: false, isSelected: false),
            Skin(id: 3, name: "Skin 3", iconName: "skin3_icon", gameSpriteName: "skin3", price: 200, isPurchased: false, isSelected: false),
            Skin(id: 4, name: "Default", iconName: "clown_default", gameSpriteName: "clown_default", price: 0, isPurchased: true, isSelected: true)
        ]
    }
    
    func buySkin(_ skinId: Int) {
        guard let index = skins.firstIndex(where: { $0.id == skinId }) else { return }
        guard !skins[index].isPurchased else { return }
        guard coins >= skins[index].price else { return }
        
        coins -= skins[index].price
        skins[index].isPurchased = true
    }
    
    func selectSkin(_ skinId: Int) {
        guard let index = skins.firstIndex(where: { $0.id == skinId }) else { return }
        guard skins[index].isPurchased else { return }
        
        // Снимаем выделение с всех скинов
        for i in 0..<skins.count {
            skins[i].isSelected = false
        }
        
        // Выделяем выбранный скин
        skins[index].isSelected = true
        selectedSkinId = skinId
    }
    
    func getCurrentSkinSprite() -> String {
        return skins.first { $0.id == selectedSkinId }?.gameSpriteName ?? "clown_default"
    }
}

struct ShopView: View {
    @Binding var isPresented: Bool
    @State private var showSettings = false
    @StateObject var skinManager = SkinManager.shared
    @State private var infoOpenSkinIds: Set<Int> = []
    
    private func getSkinInfoText(_ skinId: Int) -> String {
        switch skinId {
        case 1:
            return "Player mistakes slow down animal timer by 4 sec instead of penalty"
        case 2:
            return "Adds +3 sec to animal timer when correctly repeating sequence"
        case 3:
            return "Increases sequence display time by +4 sec"
        case 4:
            return "Increases sequence display time by +2 sec"
        default:
            return "Skin information"
        }
    }
    
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
                            .overlay(
                                Text("\(skinManager.coins)")
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
                
                // Контент магазина - панели скинов
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(skinManager.skins, id: \.id) { skin in
                            VStack(spacing: 10) {
                                // Панель скина
                                Image("skinPanel_image")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 250)
                                    .overlay(
                                        ZStack {
                                            // Контент панели
                                            VStack {
                                                // Скин сверху
                                                Image(skin.iconName)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 150, height: 150)
                                                    .opacity(infoOpenSkinIds.contains(skin.id) ? 0 : 1)
                                                    .offset(y: infoOpenSkinIds.contains(skin.id) ? 180 : 0)
                                                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: infoOpenSkinIds)

                                                Spacer()
                                                
                                                // Кнопка внизу панели
                                                if !infoOpenSkinIds.contains(skin.id) && skin.isSelected {
                                                    // Кнопка "В использовании"
                                                    Image("inUse_button")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 120, height: 40)
                                                } else if !infoOpenSkinIds.contains(skin.id) && skin.isPurchased {
                                                    // Кнопка "Использовать"
                                                    Button(action: {
                                                        skinManager.selectSkin(skin.id)
                                                    }) {
                                                        Image("use_button")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 120, height: 40)
                                                    }
                                                } else if !infoOpenSkinIds.contains(skin.id) {
                                                    // Кнопка покупки
                                                    Button(action: {
                                                        skinManager.buySkin(skin.id)
                                                    }) {
                                                        Image("buy_button")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 120, height: 40)
                                                    }
                                                    .disabled(skinManager.coins < skin.price)
                                                    .opacity(skinManager.coins < skin.price ? 0.5 : 1.0)
                                                }
                                            }
                                            .padding(.vertical, 20)

                                            // Текст информации поверх, по центру панели без фона
                                            if infoOpenSkinIds.contains(skin.id) {
                                                VStack {
                                                    Spacer(minLength: 0)
                                                    Text(getSkinInfoText(skin.id))
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.center)
                                                        .padding(.horizontal, 17)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                    Spacer(minLength: 0)
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 8)
                                                .transition(.opacity)
                                                .animation(.easeInOut(duration: 0.2), value: infoOpenSkinIds)
                                            }

                                        }
                                    )
                                    .overlay(alignment: .topLeading) {
                                        // Левая кнопка info/close (фиксированная позиция)
                                        Button(action: {
                                            if infoOpenSkinIds.contains(skin.id) {
                                                infoOpenSkinIds.remove(skin.id)
                                            } else {
                                                infoOpenSkinIds.insert(skin.id)
                                            }
                                        }) {
                                            Image(infoOpenSkinIds.contains(skin.id) ? "closeInfo_button" : "info_button")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 30, height: 30)
                                                .clipped()
                                        }
                                        .padding(.top, 8)
                                        .padding(.leading, 30)
                                    }
                            }
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
 

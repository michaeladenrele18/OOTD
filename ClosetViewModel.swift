//
//  ClosetViewModel.swift
//  OOTD.AI
//

import SwiftUI
import UIKit
import Combine

// -------------------------------------------------------------
// MARK: - Shared Closet Item Model
// -------------------------------------------------------------

struct ClosetItem: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let uiImage: UIImage?
}

// -------------------------------------------------------------
// MARK: - ViewModel
// -------------------------------------------------------------

@MainActor
class ClosetViewModel: ObservableObject {
    
    @Published var jackets: [ClosetItem] = []
    @Published var shirts: [ClosetItem] = []
    @Published var pants: [ClosetItem] = []
    @Published var shoes: [ClosetItem] = []
    
    // MARK: - Helpers
    
    func items(for section: String) -> [ClosetItem] {
        switch section {
        case "Jackets": return jackets
        case "Shirts":  return shirts
        case "Pants":   return pants
        case "Shoes":   return shoes
        default: return []
        }
    }
    
    func add(_ item: ClosetItem, to section: String) {
        switch section {
        case "Jackets": jackets.append(item)
        case "Shirts":  shirts.append(item)
        case "Pants":   pants.append(item)
        case "Shoes":   shoes.append(item)
        default: break
        }
    }
    
    func delete(_ item: ClosetItem, from section: String) {
        switch section {
        case "Jackets": jackets.removeAll { $0.id == item.id }
        case "Shirts":  shirts.removeAll { $0.id == item.id }
        case "Pants":   pants.removeAll { $0.id == item.id }
        case "Shoes":   shoes.removeAll { $0.id == item.id }
        default: break
        }
    }
    
    // Outfit model: includes both the AI hint strings and any matched ClosetItem
    struct Outfit: Sendable {
        var jacket: ClosetItem?
        var jacketHint: String?
        var shirt: ClosetItem?
        var shirtHint: String?
        var pants: ClosetItem?
        var pantsHint: String?
        var shoes: ClosetItem?
        var shoesHint: String?
        
        func asArray() -> [ClosetItem] {
            [jacket, shirt, pants, shoes].compactMap { $0 }
        }
    }
    
    // ---------------------------------------------------------
    // MARK: - Local Fallback Outfit Generator
    // ---------------------------------------------------------
    
    func generateSmartOutfit(temperature: Double,
                             profile: UserProfile?) -> Outfit {
        
        var jacket: ClosetItem? = nil
        let shirt = shirts.randomElement()
        let pants = pants.randomElement()
        let shoes = shoes.randomElement()
        
        if temperature < 55 { jacket = jackets.randomElement() }
        
        return Outfit(jacket: jacket,
                      shirt: shirt,
                      pants: pants,
                      shoes: shoes)
    }
    
    // ---------------------------------------------------------
    // MARK: - AI Outfit Generator (main function for HomeView)
    // ---------------------------------------------------------
    
    func generateAIOutfit(
        temperature: Double,
        profile: UserProfile?,
        freeTextPrompt: String? = nil,
        completion: @escaping (Outfit) -> Void
    ) {
        let summary = closetSummaryForAI()
        
        AIStylistService.shared.suggestOutfit(
            temperature: temperature,
            profile: profile,
            closetSummary: summary,
            freeTextPrompt: freeTextPrompt,
        ) { [weak self] result in
            guard let self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let hints):
                    completion(self.mapHintsToOutfit(hints: hints))
                case .failure:
                    completion(self.generateSmartOutfit(temperature: temperature, profile: profile))
                }
            }
        }
    }
    
    private func closetSummaryForAI() -> String {
        func list(_ items: [ClosetItem]) -> String {
            items.isEmpty ? "none" : items.map(\.name).joined(separator: ", ")
        }
        
        return """
        Jackets: \(list(jackets))
        Shirts: \(list(shirts))
        Pants: \(list(pants))
        Shoes: \(list(shoes))
        """
    }
    
    private func mapHintsToOutfit(hints: AIOutfitHints) -> Outfit {
        func match(_ items: [ClosetItem], hint: String?) -> ClosetItem? {
            guard let hint = hint?.lowercased(), !items.isEmpty else { return items.randomElement() }
            
            let scored = items.map { item in
                (item, item.name.lowercased().wordsMatched(in: hint))
            }
            return scored.max(by: { $0.1 < $1.1 })?.0 ?? items.randomElement()
        }
        
        let jacketItem = hints.jacket?.lowercased() == "none" ? nil : match(jackets, hint: hints.jacket)
        let shirtItem  = match(shirts, hint: hints.shirt)
        let pantsItem  = match(pants, hint: hints.pants)
        let shoesItem  = match(shoes, hint: hints.shoes)
        
        return Outfit(
            jacket: jacketItem,
            jacketHint: hints.jacket,
            shirt: shirtItem,
            shirtHint: hints.shirt,
            pants: pantsItem,
            pantsHint: hints.pants,
            shoes: shoesItem,
            shoesHint: hints.shoes
        )
    }
}

private extension String {
    func wordsMatched(in text: String) -> Int {
        split(separator: " ").reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
    }
}

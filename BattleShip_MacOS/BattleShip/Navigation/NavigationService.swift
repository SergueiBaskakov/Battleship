//
//  NavigationService.swift
//  BattleShip
//
//  Created by Serguei Diaz on 14.01.2025.
//

import SwiftUI

class NavigationService: ObservableObject, Identifiable {
    let id = UUID()
    
    @Published var items: [navigationPath] = []
        
    public static var shared = NavigationService()
    
    public func goTo(_ view: navigationPath) {
        self.items.append(view)
    }
    
    public func backOne() {
        if !self.items.isEmpty {
            self.items.removeLast()
        }
    }
    
    public func backTo(_ view: navigationPath) {
        guard let last = self.items.last else { return }
        if last != view {
            backOne()
            backTo(view)
        }
    }
    
    public func backToRoot() {
        self.items = []
    }
    
    private init() {}
}

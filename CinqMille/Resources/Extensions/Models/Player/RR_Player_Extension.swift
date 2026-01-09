//
//  CM_Player_Extension.swift
//  CinqMille
//
//  Created by BLIN Michael on 01/01/2026.
//

import Foundation

extension CM_Player {
	
	public var score:Int {
		
		return self.scores.reduce(0, +)
	}
	public static var current:CM_Player {
		
		if let data = UserDefaults.get(.currentPlayer) as? Data, let player = try? JSONDecoder().decode(CM_Player.self, from: data) {
			
			return player
		}
		
		let player:CM_Player = .init()
		player.save()
		
		return player
	}
	
	public func save() {
		
		if let data = try? JSONEncoder().encode(self) {
			
			UserDefaults.set(data, .currentPlayer)
		}
	}
}

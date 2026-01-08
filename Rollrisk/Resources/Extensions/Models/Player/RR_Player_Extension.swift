//
//  RR_Player_Extension.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import Foundation

extension RR_Player {
	
	public var score:Int {
		
		return self.scores.reduce(0, +)
	}
	public static var current:RR_Player {
		
		if let data = UserDefaults.get(.currentPlayer) as? Data, let player = try? JSONDecoder().decode(RR_Player.self, from: data) {
			
			return player
		}
		
		let player:RR_Player = .init()
		player.save()
		
		return player
	}
	
	public func save() {
		
		if let data = try? JSONEncoder().encode(self) {
			
			UserDefaults.set(data, .currentPlayer)
		}
	}
}

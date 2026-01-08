//
//  RR_Player.swift
//  Rollrisk
//
//  Created by BLIN Michael on 01/01/2026.
//

import Foundation

public class RR_Player : Codable, Equatable {
	
	public class Stats : Codable {
		
		public var wins:Int = 0
		public var losses:Int = 0
		public var abandonments:Int = 0
	}
	
	public var id:UUID = UUID()
	public var name:String?
	public var scores:[Int] = .init()
	public var stats:Stats = .init()
	public var hasOpened:Bool = false
	
	public static func == (lhs: RR_Player, rhs: RR_Player) -> Bool {
		
		return lhs.id == rhs.id
	}
	
	public func resetGameState() {
		
		scores.removeAll()
		hasOpened = false
		save()
	}
}

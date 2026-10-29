//
//  InsightsModel.swift
//  Moko
//
//  Created by user@42 on 28/10/26.
//

import Foundation
import SwiftData

@Model
final class InsightsModel {
    var courage : Int
    var clarity : Int
    var presence : Int
    var warmth : Int
    var date : Date
    init(courage : Int, clarity : Int , presence : Int , warmth : Int, date : Date){
        self.clarity = clarity
        self.courage = courage
        self.presence = presence
        self.warmth = warmth
        self.date = date
    }
    
}

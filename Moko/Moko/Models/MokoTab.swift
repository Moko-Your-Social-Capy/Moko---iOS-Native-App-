//
//  MokoTab.swift
//  Moko
//
//  The single shared tab enum for the app.
//

import SwiftUI

enum MokoTab: String, CaseIterable, Identifiable, Hashable {
    case overview
    case quests
    case relax
    case search

    var id: String { rawValue }
}

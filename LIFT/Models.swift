//
//  Models.swift
//  LIFT
//

import Foundation
import FirebaseFirestore

struct WorkoutCategory: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var createdAt: Date
    
    var idString: String {
        id ?? ""
    }
    
    static func == (lhs: WorkoutCategory, rhs: WorkoutCategory) -> Bool {
        lhs.idString == rhs.idString && lhs.name == rhs.name
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case lats = "Lats"
    case upperBack = "Upper Back"
    case lowerBack = "Lower Back"
    case frontDelts = "Front Delts"
    case sideDelts = "Side Delts"
    case rearDelts = "Rear Delts"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case abs = "Abs"
    case obliques = "Obliques"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    
    var id: String { self.rawValue }
}

struct Exercise: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var categoryId: String
    var name: String
    var createdAt: Date
    var targetedMuscles: [String]?
    
    var idString: String {
        id ?? ""
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(idString)
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.idString == rhs.idString && lhs.name == rhs.name && lhs.categoryId == rhs.categoryId && lhs.targetedMuscles == rhs.targetedMuscles
    }
}

struct WorkoutSet: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var weight: Double
    var reps: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, weight, reps
    }
}

struct ExerciseLog: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var exerciseId: String
    var exerciseName: String
    var sets: [WorkoutSet]
    var rating: Int // 1-5 stars
    
    private enum CodingKeys: String, CodingKey {
        case id, exerciseId, exerciseName, sets, rating
    }
}

struct WorkoutLog: Identifiable, Codable {
    @DocumentID var id: String?
    var categoryId: String
    var categoryName: String
    var date: Date
    var exerciseLogs: [ExerciseLog]
    
    var idString: String {
        id ?? ""
    }
}

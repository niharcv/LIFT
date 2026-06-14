//
//  NutritionModels.swift
//  LIFT
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Equatable {
    @DocumentID var id: String?
    var age: Int
    var sex: String // "Male", "Female"
    var weight: Double // in lbs
    var height: Double // in inches
    var activityLevel: String // "Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extra Active"
    var targetWeight: Double // in lbs
    var goalType: String // "Lose Weight", "Gain Weight", "Maintain Weight"
    var weeklyPace: Double // in lbs/week: 0.5, 1.0, 1.5, 2.0
    var bmr: Double
    var calorieBudget: Int
    var updatedAt: Date
    
    var idString: String {
        id ?? ""
    }
}

struct FoodLogEntry: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String
    var calories: Int
    var protein: Double // in grams
    var carbs: Double // in grams
    var fat: Double // in grams
    var mealType: String // "Breakfast", "Lunch", "Dinner", "Snack"
    var date: Date
    
    var idString: String {
        id ?? ""
    }
    
    static func == (lhs: FoodLogEntry, rhs: FoodLogEntry) -> Bool {
        lhs.idString == rhs.idString &&
        lhs.name == rhs.name &&
        lhs.calories == rhs.calories &&
        lhs.protein == rhs.protein &&
        lhs.carbs == rhs.carbs &&
        lhs.fat == rhs.fat &&
        lhs.mealType == rhs.mealType &&
        lhs.date == rhs.date
    }
}

struct CustomMeal: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String
    var calories: Int
    var protein: Double // in grams
    var carbs: Double // in grams
    var fat: Double // in grams
    
    var idString: String {
        id ?? ""
    }
}

struct WeightLog: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var weight: Double // in lbs
    var date: Date
    
    var idString: String {
        id ?? ""
    }
}

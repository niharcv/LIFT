//
//  DatabaseService.swift
//  LIFT
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class DatabaseService: ObservableObject {
    @Published var categories: [WorkoutCategory] = []
    @Published var exercises: [Exercise] = []
    @Published var workoutLogs: [WorkoutLog] = []
    
    // Nutrition Properties
    @Published var userProfile: UserProfile? = nil
    @Published var todayFoodLogs: [FoodLogEntry] = []
    @Published var customMeals: [CustomMeal] = []
    @Published var weightLogs: [WeightLog] = []
    @Published var waterIntake: Int = 0
    
    // Goals progress caching
    @Published var last30DaysFoodLogs: [FoodLogEntry] = []
    @Published var last30DaysWaterLogs: [String: Int] = [:]
    
    // Apple Health Sync Properties
    @Published var healthKitWorkouts: [AppleHealthActivity] = []
    @Published var isHealthKitAuthorized = false
    
    let db = Firestore.firestore()
    var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private var categoriesListener: ListenerRegistration?
    private var exercisesListener: ListenerRegistration?
    private var logsListener: ListenerRegistration?
    
    var profileListener: ListenerRegistration?
    var foodLogsListener: ListenerRegistration?
    var customMealsListener: ListenerRegistration?
    var weightLogsListener: ListenerRegistration?
    var waterListener: ListenerRegistration?
    var last30DaysFoodLogsListener: ListenerRegistration?
    var last30DaysWaterLogsListener: ListenerRegistration?
    
    func startListening() {
        guard let uid = userId else { return }
        
        // Auto-sync HealthKit on every launch — requestAuthorization is a no-op
        // if the user has already granted permission, so this is always safe to call.
        requestHealthKitAuthorization()
        
        // Listen to Categories
        categoriesListener = db.collection("users").document(uid).collection("categories")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching categories: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.categories = documents.compactMap { doc in
                    try? doc.data(as: WorkoutCategory.self)
                }
            }
        
        // Listen to Exercises
        exercisesListener = db.collection("users").document(uid).collection("exercises")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching exercises: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.exercises = documents.compactMap { doc in
                    try? doc.data(as: Exercise.self)
                }
            }
            
        // Listen to Workout Logs
        logsListener = db.collection("users").document(uid).collection("workout_logs")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching workout logs: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.workoutLogs = documents.compactMap { doc in
                    try? doc.data(as: WorkoutLog.self)
                }
            }
            
        // Start listening to persistent nutrition data (profile, custom meals, weight logs)
        startListeningToPersistentNutrition()
        
        // Start listening to the last 30 days of data for Goals & Streaks
        startListeningTo30DaysProgress()
    }
    
    func stopListening() {
        categoriesListener?.remove()
        exercisesListener?.remove()
        logsListener?.remove()
        
        profileListener?.remove()
        foodLogsListener?.remove()
        customMealsListener?.remove()
        weightLogsListener?.remove()
        waterListener?.remove()
        
        last30DaysFoodLogsListener?.remove()
        last30DaysWaterLogsListener?.remove()
        
        categories = []
        exercises = []
        workoutLogs = []
        
        userProfile = nil
        todayFoodLogs = []
        customMeals = []
        weightLogs = []
        waterIntake = 0
        
        last30DaysFoodLogs = []
        last30DaysWaterLogs = [:]
    }
    
    // Add Category
    func addCategory(name: String, completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }
        
        let newCategory = WorkoutCategory(name: name, createdAt: Date())
        
        do {
            _ = try db.collection("users").document(uid).collection("categories").addDocument(from: newCategory)
            completion(true)
        } catch {
            print("Error adding category: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Add Exercise
    func addExercise(name: String, categoryId: String, targetedMuscles: [String], completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }
        
        let newExercise = Exercise(categoryId: categoryId, name: name, createdAt: Date(), targetedMuscles: targetedMuscles)
        
        do {
            _ = try db.collection("users").document(uid).collection("exercises").addDocument(from: newExercise)
            completion(true)
        } catch {
            print("Error adding exercise: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Calculate muscle battery levels from 0.0 (fully depleted) to 1.0 (fully charged)
    func getMuscleRecoveryLevels() -> [String: Double] {
        var batteryLevels: [String: Double] = [:]
        for muscle in MuscleGroup.allCases {
            batteryLevels[muscle.rawValue] = 1.0
        }
        
        let logs = workoutLogs
        let exerciseList = exercises
        
        var accumulatedFatigue: [String: Double] = [:]
        
        for log in logs {
            let timeInterval = Date().timeIntervalSince(log.date)
            let hoursElapsed = timeInterval / 3600.0
            
            // Fatigue from logs older than 48 hours has decayed to 0
            if hoursElapsed >= 48.0 {
                break
            }
            
            // Linear recharge factor: fatigue decays to 0 at 48 hours
            let decayFactor = 1.0 - (hoursElapsed / 48.0)
            
            // Count sets completed per muscle group in this session
            var setsPerMuscle: [String: Int] = [:]
            for exerciseLog in log.exerciseLogs {
                if let exercise = exerciseList.first(where: { $0.idString == exerciseLog.exerciseId }),
                   let muscles = exercise.targetedMuscles {
                    let setsCount = exerciseLog.sets.count
                    for muscle in muscles {
                        setsPerMuscle[muscle, default: 0] += setsCount
                    }
                }
            }
            
            // Add remaining fatigue to muscles
            for (muscle, setsCount) in setsPerMuscle {
                // Deplete 15% per set
                let depletion = Double(setsCount) * 0.15
                let remainingFatigue = depletion * decayFactor
                accumulatedFatigue[muscle, default: 0.0] += remainingFatigue
            }
        }
        
        // Apply fatigue to calculate remaining battery levels
        for muscle in MuscleGroup.allCases {
            let fatigue = accumulatedFatigue[muscle.rawValue, default: 0.0]
            batteryLevels[muscle.rawValue] = max(0.0, 1.0 - fatigue)
        }
        
        return batteryLevels
    }
    
    // Save Workout Log
    func saveWorkoutLog(categoryId: String, categoryName: String, exerciseLogs: [ExerciseLog], completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }
        
        let newLog = WorkoutLog(
            categoryId: categoryId,
            categoryName: categoryName,
            date: Date(),
            exerciseLogs: exerciseLogs
        )
        
        do {
            _ = try db.collection("users").document(uid).collection("workout_logs").addDocument(from: newLog)
            completion(true)
        } catch {
            print("Error saving workout log: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Get last performance for a specific exercise
    func getLastPerformance(for exerciseId: String) -> ExerciseLog? {
        for log in workoutLogs {
            if let exerciseLog = log.exerciseLogs.first(where: { $0.exerciseId == exerciseId }) {
                return exerciseLog
            }
        }
        return nil
    }
    
    // Delete Category and associated exercises
    func deleteCategory(id: String, completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }
        
        let batch = db.batch()
        
        let categoryRef = db.collection("users").document(uid).collection("categories").document(id)
        batch.deleteDocument(categoryRef)
        
        let associatedExercises = exercises.filter { $0.categoryId == id }
        for exercise in associatedExercises {
            if let exerciseId = exercise.id {
                let exerciseRef = db.collection("users").document(uid).collection("exercises").document(exerciseId)
                batch.deleteDocument(exerciseRef)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error deleting category: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Delete Exercise
    func deleteExercise(id: String, completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("exercises").document(id).delete { error in
            if let error = error {
                print("Error deleting exercise: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Delete Workout Log (Session)
    func deleteWorkoutLog(id: String, completion: @escaping (Bool) -> Void) {
        guard let uid = userId else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("workout_logs").document(id).delete { error in
            if let error = error {
                print("Error deleting workout log: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Apple Health (HealthKit) Integration
    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        HealthKitManager.shared.requestAuthorization { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isHealthKitAuthorized = success
                if success {
                    self?.syncHealthKitWorkouts(for: Date())
                }
                completion(success)
            }
        }
    }
    
    func syncHealthKitWorkouts(for date: Date) {
        HealthKitManager.shared.fetchWorkouts(for: date) { [weak self] workouts, error in
            DispatchQueue.main.async {
                self?.healthKitWorkouts = workouts
            }
        }
    }
    
    func startListeningTo30DaysProgress() {
        guard let uid = userId else { return }
        
        last30DaysFoodLogsListener?.remove()
        last30DaysWaterLogsListener?.remove()
        
        let calendar = Calendar.current
        let threeSixtyFiveDaysAgo = calendar.date(byAdding: .day, value: -365, to: calendar.startOfDay(for: Date()))!
        
        // 1. Listen to food logs for the last 365 days
        last30DaysFoodLogsListener = db.collection("users").document(uid).collection("food_logs")
            .whereField("date", isGreaterThanOrEqualTo: threeSixtyFiveDaysAgo)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching 30 days food logs: \(error?.localizedDescription ?? "")")
                    return
                }
                let logs = documents.compactMap { try? $0.data(as: FoodLogEntry.self) }
                DispatchQueue.main.async {
                    self?.last30DaysFoodLogs = logs
                }
            }
            
        // 2. Listen to water logs (entire collection is fine because it has one document per day)
        last30DaysWaterLogsListener = db.collection("users").document(uid).collection("water_intake")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching 30 days water logs: \(error?.localizedDescription ?? "")")
                    return
                }
                var waterMap: [String: Int] = [:]
                for doc in documents {
                    if let amount = doc.data()["amount"] as? Int {
                        waterMap[doc.documentID] = amount
                    }
                }
                DispatchQueue.main.async {
                    self?.last30DaysWaterLogs = waterMap
                }
            }
    }
}

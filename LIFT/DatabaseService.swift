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
    
    private let db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private var categoriesListener: ListenerRegistration?
    private var exercisesListener: ListenerRegistration?
    private var logsListener: ListenerRegistration?
    
    func startListening() {
        guard let uid = userId else { return }
        
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
    }
    
    func stopListening() {
        categoriesListener?.remove()
        exercisesListener?.remove()
        logsListener?.remove()
        
        categories = []
        exercises = []
        workoutLogs = []
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
}

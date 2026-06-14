//
//  NutritionDatabaseService.swift
//  LIFT
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

extension DatabaseService {
    
    // Helper to format date into YYYY-MM-DD
    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // Listen to persistent nutrition data (profile, custom meals, weight logs)
    func startListeningToPersistentNutrition() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // 1. Listen to Profile
        profileListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let document = snapshot else {
                    print("Error fetching profile: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                if document.exists {
                    self?.userProfile = try? document.data(as: UserProfile.self)
                } else {
                    self?.userProfile = nil
                }
            }
            
        // 2. Listen to Custom Meals
        customMealsListener = db.collection("users").document(uid).collection("custom_meals")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching custom meals: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.customMeals = documents.compactMap { doc in
                    try? doc.data(as: CustomMeal.self)
                }
            }
            
        // 3. Listen to Weight Logs (ordered by date ascending for line charting)
        weightLogsListener = db.collection("users").document(uid).collection("weight_logs")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching weight logs: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self?.weightLogs = documents.compactMap { doc in
                    try? doc.data(as: WeightLog.self)
                }
            }
    }
    
    // Listen to date-specific data (food logs, water intake)
    func startListeningToNutrition(for date: Date) {
        syncHealthKitWorkouts(for: date)
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing date-specific listeners
        foodLogsListener?.remove()
        waterListener?.remove()
        
        // Calculate date bounds
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 1. Listen to Food Logs for specified date
        foodLogsListener = db.collection("users").document(uid).collection("food_logs")
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching food logs: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                // Sort by date descending in memory
                let logs = documents.compactMap { doc in
                    try? doc.data(as: FoodLogEntry.self)
                }
                self?.todayFoodLogs = logs.sorted(by: { $0.date > $1.date })
            }
            
        // 2. Listen to Water Intake for specified date
        let dateString = formatDateString(date)
        waterListener = db.collection("users").document(uid).collection("water_intake").document(dateString)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let document = snapshot else {
                    print("Error fetching water: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                if document.exists, let amount = document.data()?["amount"] as? Int {
                    self?.waterIntake = amount
                } else {
                    self?.waterIntake = 0
                }
            }
    }
    
    // Save/Update User Profile
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        var profileData = profile
        profileData.updatedAt = Date()
        
        do {
            try db.collection("users").document(uid).setData(from: profileData, merge: true)
            completion(true)
        } catch {
            print("Error saving user profile: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Log Food Entry
    func logFood(_ entry: FoodLogEntry, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        do {
            _ = try db.collection("users").document(uid).collection("food_logs").addDocument(from: entry)
            completion(true)
        } catch {
            print("Error logging food: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Delete Food Log Entry
    func deleteFoodLog(id: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("food_logs").document(id).delete { error in
            if let error = error {
                print("Error deleting food log: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Update Food Log Entry
    func updateFoodLog(_ entry: FoodLogEntry, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid, let id = entry.id else {
            completion(false)
            return
        }
        
        do {
            try db.collection("users").document(uid).collection("food_logs").document(id).setData(from: entry)
            completion(true)
        } catch {
            print("Error updating food log: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Save Custom Meal Template
    func saveCustomMeal(_ meal: CustomMeal, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        do {
            _ = try db.collection("users").document(uid).collection("custom_meals").addDocument(from: meal)
            completion(true)
        } catch {
            print("Error saving custom meal: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // Delete Custom Meal Template
    func deleteCustomMeal(id: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("custom_meals").document(id).delete { error in
            if let error = error {
                print("Error deleting custom meal: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Save Weight Log Entry
    func saveWeightLog(weight: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let calendar = Calendar.current
        let existingLog = weightLogs.first { calendar.isDate($0.date, inSameDayAs: date) }
        
        if let existing = existingLog, let docId = existing.id {
            // Update existing log (runs asynchronously in Firestore)
            db.collection("users").document(uid).collection("weight_logs").document(docId).updateData([
                "weight": weight,
                "date": date
            ]) { error in
                if let error = error {
                    print("Error updating weight log in background: \(error.localizedDescription)")
                }
            }
            
            // Also update current weight in profile if it exists
            if var profile = userProfile {
                profile.weight = weight
                saveUserProfile(profile) { _ in }
            }
            
            completion(true)
        } else {
            // Create new log
            let newLog = WeightLog(weight: weight, date: date)
            
            do {
                _ = try db.collection("users").document(uid).collection("weight_logs").addDocument(from: newLog)
                
                // Also update current weight in profile if it exists
                if var profile = userProfile {
                    profile.weight = weight
                    saveUserProfile(profile) { _ in }
                }
                
                completion(true)
            } catch {
                print("Error saving weight log: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // Delete Weight Log Entry
    func deleteWeightLog(id: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(uid).collection("weight_logs").document(id).delete { error in
            if let error = error {
                print("Error deleting weight log: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Update Daily Water Intake (+ / - ounces)
    func updateWaterIntake(amount: Int, date: Date, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let dateString = formatDateString(date)
        let docRef = db.collection("users").document(uid).collection("water_intake").document(dateString)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let docSnapshot: DocumentSnapshot
            do {
                try docSnapshot = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            var currentAmount = 0
            if docSnapshot.exists, let amountValue = docSnapshot.data()?["amount"] as? Int {
                currentAmount = amountValue
            }
            
            let newAmount = max(0, currentAmount + amount)
            transaction.setData(["amount": newAmount], forDocument: docRef, merge: true)
            return newAmount
        }) { (object, error) in
            if let error = error {
                print("Error updating water intake: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

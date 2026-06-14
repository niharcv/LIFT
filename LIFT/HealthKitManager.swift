//
//  HealthKitManager.swift
//  LIFT
//

import Foundation
import HealthKit

struct AppleHealthActivity: Identifiable, Hashable {
    let id: UUID
    let name: String
    let date: Date
    let duration: TimeInterval // seconds
    let caloriesBurned: Double // kcal
}

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Health data is not available on this device."]))
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func fetchWorkouts(for date: Date, completion: @escaping ([AppleHealthActivity], Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion([], nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion([], error)
                }
                return
            }
            
            let activities = workouts.map { workout -> AppleHealthActivity in
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0
                let name = self.workoutName(from: workout.workoutActivityType)
                return AppleHealthActivity(
                    id: workout.uuid,
                    name: name,
                    date: workout.startDate,
                    duration: workout.duration,
                    caloriesBurned: calories
                )
            }
            
            DispatchQueue.main.async {
                completion(activities, nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func workoutName(from type: HKWorkoutActivityType) -> String {
        switch type {
        // Cardio
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .stairs: return "Stairs"
        case .jumpRope: return "Jump Rope"
        case .highIntensityIntervalTraining: return "HIIT"
        case .mixedCardio: return "Mixed Cardio"
        case .skatingSports: return "Skating"
        case .crossCountrySkiing: return "Cross-Country Skiing"
        case .downhillSkiing: return "Downhill Skiing"
        case .snowboarding: return "Snowboarding"
        // Strength & Core
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .coreTraining: return "Core Training"
        case .crossTraining: return "Cross Training"
        // Mind & Body
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .barre: return "Barre"
        case .mindAndBody: return "Mind & Body"
        case .flexibility: return "Flexibility"
        case .cooldown: return "Cooldown"
        case .preparationAndRecovery: return "Recovery"
        // Dance
        case .cardioDance: return "Cardio Dance"
        case .socialDance: return "Social Dance"
        case .dance: return "Dance"
        // Ball Sports
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .americanFootball: return "American Football"
        case .baseball: return "Baseball"
        case .softball: return "Softball"
        case .volleyball: return "Volleyball"
        case .tennis: return "Tennis"
        case .tableTennis: return "Table Tennis"
        case .badminton: return "Badminton"
        case .pickleball: return "Pickleball"
        case .lacrosse: return "Lacrosse"
        case .cricket: return "Cricket"
        case .rugby: return "Rugby"
        case .golf: return "Golf"
        case .bowling: return "Bowling"
        case .discSports: return "Disc Sports"
        case .handball: return "Handball"
        case .racquetball: return "Racquetball"
        case .squash: return "Squash"
        // Combat
        case .kickboxing: return "Kickboxing"
        case .boxing: return "Boxing"
        case .wrestling: return "Wrestling"
        case .martialArts: return "Martial Arts"
        case .fencing: return "Fencing"
        // Water & Outdoor
        case .waterSports: return "Water Sports"
        case .surfingSports: return "Surfing"
        case .paddleSports: return "Paddling"
        case .snowSports: return "Snow Sports"
        case .climbing: return "Climbing"
        // Accessibility
        case .wheelchairWalkPace: return "Wheelchair Walk"
        case .wheelchairRunPace: return "Wheelchair Run"
        // Other
        case .fitnessGaming: return "Fitness Gaming"
        case .other: return "Workout"
        default: return "Workout"
        }
    }
}

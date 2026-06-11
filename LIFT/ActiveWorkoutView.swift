//
//  ActiveWorkoutView.swift
//  LIFT
//

import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var dbService: DatabaseService
    @Environment(\.dismiss) var dismiss
    
    @State private var step: WorkoutStep = .selectCategory
    @State private var selectedCategory: WorkoutCategory?
    @State private var selectedExercises: [Exercise] = []
    
    // Active session tracking state
    @State private var completedExerciseLogs: [ExerciseLog] = []
    @State private var exerciseLogs: [ExerciseLog] = []
    @State private var isSaving = false
    
    enum WorkoutStep {
        case selectCategory
        case selectExercises
        case activeTracking
        case summary
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                // Header
                headerView
                    .padding(.horizontal)
                    .padding(.top)
                
                // Step Content
                switch step {
                case .selectCategory:
                    categorySelectionView
                case .selectExercises:
                    exerciseSelectionView
                case .activeTracking:
                    activeTrackingView
                case .summary:
                    summaryView
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            if step == .activeTracking {
                Text(selectedCategory?.name.uppercased() ?? "WORKOUT")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Theme.neonCyan)
                    .tracking(2)
            } else {
                Text("NEW SESSION")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Theme.neonCyan)
                    .tracking(2)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Category Selection View
    private var categorySelectionView: some View {
        VStack(spacing: 20) {
            Text("Select Workout Type")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            if dbService.categories.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet.clipboard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.neonPurple)
                    Text("No workout categories created yet.\nCreate a category in the Dashboard tab first.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(dbService.categories) { category in
                            Button(action: {
                                withAnimation(.spring()) {
                                    selectedCategory = category
                                    step = .selectExercises
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(category.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        let count = dbService.exercises.filter { $0.categoryId == category.idString }.count
                                        Text("\(count) exercise\(count == 1 ? "" : "s") available")
                                            .font(.caption)
                                            .foregroundColor(Theme.neonCyan)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.neonPurple)
                                }
                                .padding()
                                .glassCard()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Exercise Selection View
    private var exerciseSelectionView: some View {
        VStack(spacing: 20) {
            if let category = selectedCategory {
                Text(category.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Select the exercises to do today")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                let categoryExercises = dbService.exercises.filter { $0.categoryId == category.idString }
                
                if categoryExercises.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.neonPurple)
                        Text("No exercises added to this category yet.\nGo back and add exercises in the Dashboard.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(categoryExercises) { exercise in
                            HStack {
                                Text(exercise.name)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedExercises.contains(exercise) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.neonCyan)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Color.white.opacity(0.1))
                            .onTapGesture {
                                if selectedExercises.contains(exercise) {
                                    selectedExercises.removeAll(where: { $0.idString == exercise.idString })
                                } else {
                                    selectedExercises.append(exercise)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: .infinity)
                    .background(Color.clear)
                    
                    // Start workout button
                    Button(action: {
                        if !selectedExercises.isEmpty {
                            startWorkoutSession()
                        }
                    }) {
                        Text("START WORKOUT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black.opacity(selectedExercises.isEmpty ? 0.4 : 1.0))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryGradient.opacity(selectedExercises.isEmpty ? 0.3 : 1.0))
                            .cornerRadius(12)
                            .shadow(color: selectedExercises.isEmpty ? .clear : Theme.neonCyan.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(selectedExercises.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Active Tracking View
    private var activeTrackingView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                let completedCount = exerciseLogs.filter { log in
                    log.sets.contains { $0.weight > 0 || $0.reps > 0 }
                }.count
                
                HStack {
                    Text("ACTIVE WORKOUT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.neonPurple)
                    Spacer()
                    Text("\(completedCount) / \(exerciseLogs.count) COMPLETED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.neonCyan)
                }
                .padding(.horizontal)
                
                ForEach(0..<exerciseLogs.count, id: \.self) { logIdx in
                    let log = exerciseLogs[logIdx]
                    let previousPerformance = dbService.getLastPerformance(for: log.exerciseId)
                    
                    VStack(spacing: 12) {
                        // Card Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.exerciseName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                // Last Time summary
                                if let prev = previousPerformance {
                                    Text("LAST: \(prev.sets.count) sets • Max: \(prev.sets.map { $0.weight }.max() ?? 0, specifier: "%.1f") lbs")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                } else {
                                    Text("First time logging this exercise")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            Spacer()
                            
                            // Difficulty Rating (Stars & Label)
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= log.rating ? "star.fill" : "star")
                                            .font(.system(size: 14))
                                            .foregroundColor(star <= log.rating ? Theme.neonGold : .white.opacity(0.2))
                                            .onTapGesture {
                                                withAnimation {
                                                    exerciseLogs[logIdx].rating = star
                                                }
                                            }
                                    }
                                }
                                
                                Text(difficultyLabel(for: log.rating))
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 14)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Set list headers
                        HStack {
                            Text("SET")
                                .frame(width: 40, alignment: .leading)
                            Spacer()
                            Text("PREVIOUS")
                                .frame(width: 80, alignment: .center)
                            Spacer()
                            Text("LBS")
                                .frame(width: 80, alignment: .center)
                            Spacer()
                            Text("REPS")
                                .frame(width: 60, alignment: .trailing)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        
                        // Sets
                        VStack(spacing: 8) {
                            ForEach(0..<log.sets.count, id: \.self) { idx in
                                let prevSet: WorkoutSet? = (previousPerformance != nil && idx < previousPerformance!.sets.count) ? previousPerformance!.sets[idx] : nil
                                
                                HStack {
                                    Text("\(idx + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .frame(width: 40, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(prevSet != nil ? "\(prevSet!.weight, specifier: "%.1f") x \(prevSet!.reps)" : "—")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 80, alignment: .center)
                                    
                                    Spacer()
                                    
                                    // Lbs TextField
                                    TextField("", value: Binding(
                                        get: { exerciseLogs[logIdx].sets[idx].weight },
                                        set: { exerciseLogs[logIdx].sets[idx].weight = $0 }
                                    ), format: .number, prompt: Text("0.0").foregroundColor(.white.opacity(0.3)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(6)
                                    .foregroundColor(.white)
                                    .frame(width: 80)
                                    
                                    Spacer()
                                    
                                    // Reps TextField
                                    TextField("", value: Binding(
                                        get: { exerciseLogs[logIdx].sets[idx].reps },
                                        set: { exerciseLogs[logIdx].sets[idx].reps = $0 }
                                    ), format: .number, prompt: Text("0").foregroundColor(.white.opacity(0.3)))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(6)
                                    .foregroundColor(.white)
                                    .frame(width: 60)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.horizontal, 6)
                        
                        // Add/Remove set buttons inside card
                        HStack(spacing: 16) {
                            Button(action: {
                                if exerciseLogs[logIdx].sets.count > 1 {
                                    exerciseLogs[logIdx].sets.removeLast()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "minus")
                                    Text("REMOVE SET")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(6)
                            }
                            .disabled(log.sets.count <= 1)
                            
                            Spacer()
                            
                            Button(action: {
                                let lastWeight = log.sets.last?.weight ?? 0.0
                                let lastReps = log.sets.last?.reps ?? 0
                                exerciseLogs[logIdx].sets.append(WorkoutSet(weight: lastWeight, reps: lastReps))
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("ADD SET")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.neonCyan)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Theme.neonCyan.opacity(0.08))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 14)
                    }
                    .glassCard()
                    .padding(.horizontal)
                }
                
                // Finish Workout Button
                Button(action: {
                    completedExerciseLogs = exerciseLogs.filter { log in
                        log.sets.contains { $0.weight > 0 || $0.reps > 0 }
                    }
                    withAnimation(.spring()) {
                        step = .summary
                    }
                }) {
                    Text("FINISH WORKOUT")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryGradient)
                        .cornerRadius(12)
                        .shadow(color: Theme.neonCyan.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Summary View
    private var summaryView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Celebration Icon
            ZStack {
                Circle()
                    .fill(Theme.neonCyan.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.goldGradient)
                    .shadow(color: Theme.neonGold.opacity(0.5), radius: 15)
            }
            
            VStack(spacing: 8) {
                Text("WORKOUT COMPLETE!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
                
                Text("Your progress is logged successfully.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Recap Stats Card
            VStack(spacing: 16) {
                Text("Workout Stats Recap")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 30) {
                    VStack {
                        Text("\(completedExerciseLogs.count)")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(Theme.neonCyan)
                        Text("Exercises")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    let totalSets = completedExerciseLogs.reduce(0) { $0 + $1.sets.count }
                    VStack {
                        Text("\(totalSets)")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(Theme.neonPurple)
                        Text("Total Sets")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    let totalVolume = completedExerciseLogs.reduce(0.0) { result, log in
                        result + log.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                    }
                    VStack {
                        Text("\(Int(totalVolume))")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(Theme.neonGreen)
                        Text("Volume (lbs)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
            
            Spacer()
            
            // Save & Close button
            Button(action: saveWorkoutToFirebase) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("SAVE & FINISH")
                            .fontWeight(.black)
                        Image(systemName: "checkmark")
                    }
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.primaryGradient)
                .cornerRadius(12)
                .shadow(color: Theme.neonCyan.opacity(0.3), radius: 10, y: 5)
            }
            .disabled(isSaving)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Logic Helper Functions
    private func startWorkoutSession() {
        completedExerciseLogs = []
        exerciseLogs = selectedExercises.map { exercise in
            if let previous = dbService.getLastPerformance(for: exercise.idString) {
                return ExerciseLog(
                    exerciseId: exercise.idString,
                    exerciseName: exercise.name,
                    sets: previous.sets.map { WorkoutSet(weight: $0.weight, reps: $0.reps) },
                    rating: previous.rating
                )
            } else {
                return ExerciseLog(
                    exerciseId: exercise.idString,
                    exerciseName: exercise.name,
                    sets: [
                        WorkoutSet(weight: 0, reps: 0),
                        WorkoutSet(weight: 0, reps: 0),
                        WorkoutSet(weight: 0, reps: 0)
                    ],
                    rating: 3
                )
            }
        }
        withAnimation(.spring()) {
            step = .activeTracking
        }
    }
    
    private func saveWorkoutToFirebase() {
        guard let category = selectedCategory else { return }
        isSaving = true
        
        dbService.saveWorkoutLog(
            categoryId: category.idString,
            categoryName: category.name,
            exerciseLogs: completedExerciseLogs
        ) { success in
            isSaving = false
            if success {
                dismiss()
            }
        }
    }
    
    private func difficultyLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "RPE 5-6: Easy"
        case 2: return "RPE 7: Moderate"
        case 3: return "RPE 8: Challenging"
        case 4: return "RPE 9: Very Hard"
        case 5: return "RPE 10: Failure"
        default: return ""
        }
    }
}

#Preview {
    ActiveWorkoutView()
        .environmentObject(DatabaseService())
}

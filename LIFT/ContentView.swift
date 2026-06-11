//
//  ContentView.swift
//  LIFT
//
//

import SwiftUI
import Charts

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dbService: DatabaseService
    
    @State private var selectedTab = 0
    @State private var showActiveWorkout = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainAppView
                    .onAppear {
                        dbService.startListening()
                    }
                    .onDisappear {
                        dbService.stopListening()
                    }
            } else {
                LoginView()
            }
        }
    }
    
    private var mainAppView: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView(showActiveWorkout: $showActiveWorkout)
                    .tabItem {
                        Image(systemName: "dumbbell.fill")
                        Text("Train")
                    }
                    .tag(0)
                
                // History Tab
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                    .tag(1)
                
                // Progress Tab
                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(2)
            }
            .tint(Theme.neonCyan)
            .onAppear {
                // Configure SwiftUI TabBar appearance for a sleek dark look
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Theme.cardBackground.opacity(0.95))
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .sheet(isPresented: $showActiveWorkout) {
            ActiveWorkoutView()
                .environmentObject(dbService)
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dbService: DatabaseService
    @Binding var showActiveWorkout: Bool
    
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var expandedCategoryId: String? = nil
    @State private var showingProfile = false
    @State private var editedDisplayName = ""
    
    // Exercise input state per category
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    
    var daysSinceLastWorkout: Int {
        guard let lastDate = dbService.workoutLogs.first?.date else {
            return 99
        }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfWorkoutDay = calendar.startOfDay(for: lastDate)
        let components = calendar.dateComponents([.day], from: startOfWorkoutDay, to: startOfToday)
        return max(0, components.day ?? 0)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Profile Header
                        HStack {
                            let nameToShow = authManager.currentUser?.displayName ?? authManager.currentUser?.email?.components(separatedBy: "@").first ?? "ATHLETE"
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WELCOME BACK,")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.neonPurple)
                                    .tracking(1)
                                Text(nameToShow.uppercased())
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: {
                                editedDisplayName = authManager.currentUser?.displayName ?? ""
                                showingProfile = true
                            }) {
                                let initial = String(nameToShow.first ?? "A").uppercased()
                                Text(initial)
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Theme.primaryGradient)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                    .shadow(color: Theme.neonCyan.opacity(0.3), radius: 6)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Large Start Workout button
                        Button(action: {
                            showActiveWorkout = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                Text("START NEW WORKOUT")
                                    .font(.headline)
                                    .fontWeight(.black)
                                    .tracking(1)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Theme.primaryGradient)
                            .cornerRadius(16)
                            .shadow(color: Theme.neonCyan.opacity(0.35), radius: 15, y: 5)
                        }
                        .padding(.horizontal)
                        
                        // Gym Partner Roast Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("GYM PARTNER ROAST")
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .foregroundColor(.orange)
                                    .tracking(2)
                                Spacer()
                                Text("\(daysSinceLastWorkout) days since last session")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                            
                            Text(WorkoutEncouragement.getMessage(daysSinceLastWorkout: daysSinceLastWorkout))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Muscle Power Grid
                        MusclePowerGridView(batteryLevels: dbService.getMuscleRecoveryLevels())
                            .padding(.horizontal)
                        
                        // Categories List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("MY CATEGORIES")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.neonCyan)
                                    .tracking(2)
                                Spacer()
                                Button(action: {
                                    showingAddCategory = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("Add")
                                    }
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.neonPurple)
                                }
                            }
                            .padding(.horizontal)
                            
                            if dbService.categories.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.largeTitle)
                                        .foregroundColor(Theme.neonPurple.opacity(0.5))
                                    Text("No categories yet. Create categories like Push, Pull, Legs to organize your workouts!")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                                .glassCard()
                                .padding(.horizontal)
                            } else {
                                ForEach(dbService.categories) { category in
                                    CategoryCard(
                                        category: category,
                                        isExpanded: expandedCategoryId == category.idString,
                                        onToggle: {
                                            withAnimation(.spring()) {
                                                if expandedCategoryId == category.idString {
                                                    expandedCategoryId = nil
                                                } else {
                                                    expandedCategoryId = category.idString
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddCategory) {
                addCategorySheet
            }
            .sheet(isPresented: $showingProfile) {
                profileSheet
            }
        }
    }
    
    // Add Category Modal
    private var addCategorySheet: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("New Workout Category")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                
                TextField("", text: $newCategoryName, prompt: Text("Category Name (e.g. Push, Pull, Legs)").foregroundColor(.white.opacity(0.4)))
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                Button(action: {
                    if !newCategoryName.isEmpty {
                        dbService.addCategory(name: newCategoryName) { success in
                            if success {
                                newCategoryName = ""
                                showingAddCategory = false
                            }
                        }
                    }
                }) {
                    Text("CREATE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryGradient)
                        .cornerRadius(10)
                }
                .disabled(newCategoryName.isEmpty)
                
                Button("Cancel") {
                    showingAddCategory = false
                }
                .foregroundColor(.gray)
                .font(.footnote)
            }
            .padding(30)
            .glassCard()
            .padding(20)
        }
    }
    
    // Profile settings sheet
    private var profileSheet: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Drag Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text("ATHLETE PROFILE")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Theme.neonCyan)
                    .tracking(2)
                
                // Avatar Large & Name
                HStack(spacing: 16) {
                    let nameToShow = authManager.currentUser?.displayName ?? authManager.currentUser?.email?.components(separatedBy: "@").first ?? "ATHLETE"
                    let initial = String(nameToShow.first ?? "A").uppercased()
                    Text(initial)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 54)
                        .background(Theme.primaryGradient)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                        .shadow(color: Theme.neonCyan.opacity(0.4), radius: 10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nameToShow)
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text(authManager.currentUser?.email ?? "athlete@lift.com")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Name Editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SET YOUR NAME")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .tracking(1)
                            
                            HStack(spacing: 12) {
                                TextField("", text: $editedDisplayName, prompt: Text("Display Name").foregroundColor(.white.opacity(0.4)))
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                
                                if editedDisplayName != (authManager.currentUser?.displayName ?? "") && !editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button(action: {
                                        authManager.updateProfileName(name: editedDisplayName) { success in
                                            if success {
                                                // Updated
                                            }
                                        }
                                    }) {
                                        Text("SAVE")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 16)
                                            .background(Theme.neonCyan)
                                            .cornerRadius(10)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // User Stats Grid
                        VStack(spacing: 16) {
                            Text("YOUR ACHIEVEMENTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .tracking(1)
                            
                            HStack(spacing: 16) {
                                VStack(spacing: 6) {
                                    Text("\(dbService.workoutLogs.count)")
                                        .font(.title3)
                                        .fontWeight(.black)
                                        .foregroundColor(Theme.neonPurple)
                                    Text("Workouts")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(12)
                                
                                VStack(spacing: 6) {
                                    Text("\(dbService.categories.count)")
                                        .font(.title3)
                                        .fontWeight(.black)
                                        .foregroundColor(Theme.neonCyan)
                                    Text("Categories")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(12)
                                
                                VStack(spacing: 6) {
                                    Text("\(dbService.exercises.count)")
                                        .font(.title3)
                                        .fontWeight(.black)
                                        .foregroundColor(Theme.neonGreen)
                                    Text("Exercises")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .glassCard()
                        .padding(.horizontal)
                        
                        // Sign Out Button
                        Button(action: {
                            showingProfile = false
                            authManager.signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("SIGN OUT")
                                    .fontWeight(.black)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                        
                        Button("Close") {
                            showingProfile = false
                        }
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            editedDisplayName = authManager.currentUser?.displayName ?? ""
        }
    }
}

// MARK: - Category Card View
struct CategoryCard: View {
    @EnvironmentObject var dbService: DatabaseService
    let category: WorkoutCategory
    let isExpanded: Bool
    let onToggle: () -> Void
    
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    @State private var showingDeleteCategoryAlert = false
    @State private var showingDeleteExerciseAlert = false
    @State private var exerciseToDelete: Exercise? = nil
    @State private var selectedMuscles: Set<MuscleGroup> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        let count = dbService.exercises.filter { $0.categoryId == category.idString }.count
                        Text("\(count) exercise\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(Theme.neonCyan)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.neonPurple)
                }
                .padding()
            }
            
            // Expanded exercises list
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                let categoryExercises = dbService.exercises.filter { $0.categoryId == category.idString }
                
                VStack(alignment: .leading, spacing: 12) {
                    if categoryExercises.isEmpty {
                        Text("No exercises added yet.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(categoryExercises) { exercise in
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .font(.caption)
                                    .foregroundColor(Theme.neonPurple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    if let muscles = exercise.targetedMuscles, !muscles.isEmpty {
                                        Text(muscles.joined(separator: ", "))
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(8)
                            .contextMenu {
                                Button {
                                    exerciseToDelete = exercise
                                    showingDeleteExerciseAlert = true
                                } label: {
                                    Label("Delete Exercise", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    // Add exercise input inline
                    if showingAddExercise {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TextField("", text: $newExerciseName, prompt: Text("Exercise Name (e.g. Bench Press)").foregroundColor(.white.opacity(0.4)))
                                    .font(.subheadline)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    if !newExerciseName.isEmpty {
                                        dbService.addExercise(
                                            name: newExerciseName,
                                            categoryId: category.idString,
                                            targetedMuscles: selectedMuscles.map { $0.rawValue }
                                        ) { success in
                                            if success {
                                                newExerciseName = ""
                                                selectedMuscles = []
                                                showingAddExercise = false
                                            }
                                        }
                                    }
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(Theme.neonCyan)
                                }
                                
                                Button(action: {
                                    selectedMuscles = []
                                    showingAddExercise = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Muscle Group Selector
                            Text("TARGET MUSCLE GROUPS:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                                .tracking(1)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MuscleGroup.allCases) { muscle in
                                        let isSelected = selectedMuscles.contains(muscle)
                                        Button(action: {
                                            if isSelected {
                                                selectedMuscles.remove(muscle)
                                            } else {
                                                selectedMuscles.insert(muscle)
                                            }
                                        }) {
                                            Text(muscle.rawValue)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(isSelected ? .black : .white)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(isSelected ? Theme.neonCyan : Color.white.opacity(0.08))
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        Button(action: {
                            showingAddExercise = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Exercise")
                            }
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonPurple)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.neonPurple.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .glassCard()
        .contextMenu {
            Button {
                showingDeleteCategoryAlert = true
            } label: {
                Label("Delete Category", systemImage: "trash")
            }
        }
        .alert("Delete Category?", isPresented: $showingDeleteCategoryAlert) {
            Button("Delete", role: .destructive) {
                dbService.deleteCategory(id: category.idString) { _ in }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(category.name)'? This will also delete all of its exercises. Historical workout logs are not affected.")
        }
        .alert("Delete Exercise?", isPresented: $showingDeleteExerciseAlert) {
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete {
                    dbService.deleteExercise(id: exercise.idString) { _ in }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let exercise = exerciseToDelete {
                Text("Are you sure you want to delete '\(exercise.name)'? Historical workout logs are not affected.")
            } else {
                Text("Are you sure you want to delete this exercise?")
            }
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var dbService: DatabaseService
    
    struct CategoryCount: Identifiable {
        let id: String
        let name: String
        let count: Int
        let deficit: Int
    }
    
    var categoryBalances: [CategoryCount] {
        let categories = dbService.categories
        let logs = dbService.workoutLogs
        
        var counts: [String: Int] = [:]
        for log in logs {
            counts[log.categoryId, default: 0] += 1
        }
        
        let maxCount = counts.values.max() ?? 0
        
        return categories.map { cat in
            let count = counts[cat.idString, default: 0]
            let deficit = maxCount - count
            return CategoryCount(id: cat.idString, name: cat.name, count: count, deficit: deficit)
        }
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("WORKOUT HISTORY")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Category Balance Scorecard (Replacing weekly overview card)
                    categoryBalanceCard
                        .padding(.horizontal)
                    
                    // History List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("COMPLETED SESSIONS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonCyan)
                            .tracking(2)
                            .padding(.horizontal)
                        
                        if dbService.workoutLogs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No workouts logged yet.\nComplete your first session on the Train tab!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            .padding(.horizontal)
                        } else {
                            ForEach(dbService.workoutLogs) { log in
                                WorkoutLogCard(log: log)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    // Category Balance Scorecard
    private var categoryBalanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CATEGORY BALANCE SCORECARD")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.neonCyan)
                        .tracking(1)
                    Text("Deficit relative to your most active split.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "scale.3d")
                    .foregroundColor(Theme.neonCyan)
            }
            
            let balances = categoryBalances
            if balances.isEmpty {
                Text("No categories created yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else if dbService.workoutLogs.isEmpty {
                Text("Log your first workout to see your training balance scorecard!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 12) {
                    ForEach(balances) { balance in
                        HStack {
                            Text(balance.name.uppercased())
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(balance.count) workout\(balance.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.trailing, 8)
                            
                            if balance.deficit == 0 {
                                Text("0 BEHIND")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Theme.neonGreen)
                                    .cornerRadius(6)
                            } else {
                                Text("\(balance.deficit) BEHIND")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(balance.deficit == 0 ? Theme.neonGreen.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Workout Log Card
struct WorkoutLogCard: View {
    @EnvironmentObject var dbService: DatabaseService
    let log: WorkoutLog
    @State private var isExpanded = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.categoryName.uppercased())
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(Theme.neonCyan)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Text(formatDate(log.date))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(log.exerciseLogs.count) exercise\(log.exerciseLogs.count == 1 ? "" : "s") completed")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .padding(.leading)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(log.exerciseLogs) { exerciseLog in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(exerciseLog.exerciseName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Stars Rating
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(star <= exerciseLog.rating ? Theme.neonGold : .gray.opacity(0.3))
                                    }
                                }
                            }
                            
                            Text(formatSets(exerciseLog.sets))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .glassCard()
        .contextMenu {
            Button {
                showingDeleteAlert = true
            } label: {
                Label("Delete Workout Session", systemImage: "trash")
            }
        }
        .alert("Delete Workout Session?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                dbService.deleteWorkoutLog(id: log.idString) { _ in }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this workout session? This action cannot be undone.")
        }
    }
    
    private func formatSets(_ sets: [WorkoutSet]) -> String {
        sets.enumerated().map { (index, set) in
            "S\(index+1): \(String(format: "%.1f", set.weight)) lbs x \(set.reps)"
        }.joined(separator: "  |  ")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Progress View (Analytics)
struct AnalyticsView: View {
    @EnvironmentObject var dbService: DatabaseService
    @State private var selectedExerciseId: String? = nil
    @State private var expandedCategoryId: String? = nil
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("PROGRESS TRACKING")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                if dbService.categories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Create categories and exercises first to view progression analytics.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 1. Selected Exercise Chart at the top
                            if let selectedId = selectedExerciseId, let exercise = dbService.exercises.first(where: { $0.idString == selectedId }) {
                                let chartData = getChartData(for: selectedId)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(exercise.name.uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    if chartData.isEmpty {
                                        Text("Complete workouts containing this exercise to see your weight progression chart.")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 40)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Chart {
                                            ForEach(chartData, id: \.date) { data in
                                                LineMark(
                                                    x: .value("Date", data.date, unit: .day),
                                                    y: .value("Weight (lbs)", data.maxWeight)
                                                )
                                                .foregroundStyle(Theme.primaryGradient)
                                                .lineStyle(StrokeStyle(lineWidth: 3))
                                                .interpolationMethod(.catmullRom)
                                                
                                                PointMark(
                                                    x: .value("Date", data.date, unit: .day),
                                                    y: .value("Weight (lbs)", data.maxWeight)
                                                )
                                                .foregroundStyle(Theme.neonCyan)
                                                .annotation(position: .top) {
                                                    Text("\(Int(data.maxWeight)) lbs")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.white)
                                                        .padding(4)
                                                        .background(Color.black.opacity(0.6))
                                                        .cornerRadius(4)
                                                }
                                            }
                                        }
                                        .frame(height: 220)
                                        .chartYScale(domain: getYScaleDomain(for: chartData))
                                        .chartXAxis {
                                            AxisMarks(values: .stride(by: .day)) { _ in
                                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                                    .foregroundStyle(Color.gray)
                                            }
                                        }
                                        .chartYAxis {
                                            AxisMarks { value in
                                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.1))
                                                AxisValueLabel().foregroundStyle(Color.gray)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .glassCard()
                                .padding(.horizontal)
                                
                                // History list for selected exercise
                                if !chartData.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Logged History")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                        
                                        ForEach(chartData, id: \.date) { data in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(formatShortDate(data.date))
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                    Text("Max Weight: \(data.maxWeight, specifier: "%.1f") lbs")
                                                        .font(.caption)
                                                        .foregroundColor(Theme.neonCyan)
                                                }
                                                Spacer()
                                                
                                                HStack(spacing: 2) {
                                                    ForEach(1...5, id: \.self) { star in
                                                        Image(systemName: "star.fill")
                                                            .font(.system(size: 12))
                                                            .foregroundColor(star <= data.rating ? Theme.neonGold : .gray.opacity(0.3))
                                                    }
                                                }
                                            }
                                            .padding()
                                            .background(Color.white.opacity(0.03))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            } else {
                                // Chart placeholder
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.neonCyan.opacity(0.5))
                                    Text("Select an exercise below to view its progression history.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                                .glassCard()
                                .padding(.horizontal)
                            }
                            
                            // 2. Exercises List by Category
                            VStack(alignment: .leading, spacing: 16) {
                                Text("EXERCISES BY CATEGORY")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.neonCyan)
                                    .tracking(2)
                                    .padding(.horizontal)
                                
                                ForEach(dbService.categories) { category in
                                    let isExpanded = expandedCategoryId == category.idString
                                    
                                    VStack(alignment: .leading, spacing: 0) {
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                expandedCategoryId = isExpanded ? nil : category.idString
                                            }
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(category.name.uppercased())
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                    
                                                    let count = dbService.exercises.filter { $0.categoryId == category.idString }.count
                                                    Text("\(count) exercise\(count == 1 ? "" : "s")")
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                Spacer()
                                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                                    .foregroundColor(Theme.neonPurple)
                                                    .font(.caption)
                                            }
                                            .padding()
                                            .background(Color.white.opacity(0.01))
                                        }
                                        
                                        if isExpanded {
                                            let categoryExercises = dbService.exercises.filter { $0.categoryId == category.idString }
                                            
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                            
                                            if categoryExercises.isEmpty {
                                                Text("No exercises added yet.")
                                                    .font(.footnote)
                                                    .foregroundColor(.gray)
                                                    .padding()
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color.black.opacity(0.15))
                                            } else {
                                                VStack(alignment: .leading, spacing: 0) {
                                                    ForEach(categoryExercises) { exercise in
                                                        let isSelected = selectedExerciseId == exercise.idString
                                                        
                                                        Button(action: {
                                                            withAnimation {
                                                                selectedExerciseId = exercise.idString
                                                            }
                                                        }) {
                                                            HStack {
                                                                Image(systemName: "dumbbell.fill")
                                                                    .font(.caption)
                                                                    .foregroundColor(isSelected ? Theme.neonCyan : Theme.neonPurple)
                                                                VStack(alignment: .leading, spacing: 2) {
                                                                    Text(exercise.name)
                                                                        .font(.subheadline)
                                                                        .foregroundColor(isSelected ? Theme.neonCyan : .white)
                                                                    if let muscles = exercise.targetedMuscles, !muscles.isEmpty {
                                                                        Text(muscles.joined(separator: ", "))
                                                                            .font(.system(size: 9))
                                                                            .foregroundColor(.gray)
                                                                    }
                                                                }
                                                                Spacer()
                                                                if isSelected {
                                                                    Image(systemName: "checkmark.circle.fill")
                                                                        .foregroundColor(Theme.neonCyan)
                                                                        .font(.caption)
                                                                }
                                                            }
                                                            .padding(.vertical, 12)
                                                            .padding(.horizontal, 20)
                                                            .background(isSelected ? Color.white.opacity(0.05) : Color.clear)
                                                        }
                                                        
                                                        if exercise != categoryExercises.last {
                                                            Divider()
                                                                .background(Color.white.opacity(0.05))
                                                        }
                                                    }
                                                }
                                                .background(Color.black.opacity(0.15))
                                            }
                                        }
                                    }
                                    .glassCard()
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .onAppear {
                        if selectedExerciseId == nil, let first = dbService.exercises.first {
                            selectedExerciseId = first.idString
                            expandedCategoryId = first.categoryId
                        }
                    }
                }
            }
        }
    }
    
    struct ExerciseProgressPoint {
        let date: Date
        let maxWeight: Double
        let rating: Int
    }
    
    private func getChartData(for exerciseId: String) -> [ExerciseProgressPoint] {
        var points: [ExerciseProgressPoint] = []
        
        // Reverse logs to chronological order for chart progression
        for log in dbService.workoutLogs.reversed() {
            if let exerciseLog = log.exerciseLogs.first(where: { $0.exerciseId == exerciseId }) {
                let maxWeight = exerciseLog.sets.map { $0.weight }.max() ?? 0.0
                points.append(ExerciseProgressPoint(date: log.date, maxWeight: maxWeight, rating: exerciseLog.rating))
            }
        }
        return points
    }
    
    private func getYScaleDomain(for data: [ExerciseProgressPoint]) -> ClosedRange<Double> {
        let weights = data.map { $0.maxWeight }
        let minWeight = weights.min() ?? 0.0
        let maxWeight = weights.max() ?? 100.0
        
        let lowerBound = max(0.0, minWeight - 15)
        let upperBound = maxWeight + 15
        
        return lowerBound...upperBound
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Muscle Power Grid
struct MusclePowerGridView: View {
    let batteryLevels: [String: Double]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MUSCLE POWER GRID")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.neonCyan)
                        .tracking(1.5)
                    Text("Real-time capacity depleted by workout volume.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "bolt.battery.tab.fill")
                    .foregroundColor(Theme.neonCyan)
            }
            
            // Get sorted batteries
            let sortedMuscles = MuscleGroup.allCases.map { muscle in
                (name: muscle.rawValue, level: batteryLevels[muscle.rawValue] ?? 1.0)
            }.sorted { $0.level < $1.level }
            
            // Critical batteries (depleted)
            let criticalMuscles = sortedMuscles.filter { $0.level < 0.99 }
            
            if isExpanded {
                // Show all 16 muscles in a 2-column grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(sortedMuscles, id: \.name) { item in
                        BatteryCell(name: item.name, level: item.level)
                    }
                }
            } else {
                // Show up to 4 most depleted muscles
                if criticalMuscles.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "battery.100.bolt")
                            .font(.title2)
                            .foregroundColor(Theme.neonGreen)
                        Text("All muscle batteries at 100% capacity.\nReady to crush your next session!")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(criticalMuscles.prefix(4), id: \.name) { item in
                            BatteryCell(name: item.name, level: item.level)
                        }
                    }
                }
            }
            
            // Toggle Button
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Spacer()
                    Text(isExpanded ? "COLLAPSE POWER GRID" : "SHOW ALL 16 MUSCLES")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Theme.neonCyan)
                        .tracking(1)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.neonCyan)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.03))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding()
        .glassCard()
    }
}

struct BatteryCell: View {
    let name: String
    let level: Double
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(Int(level * 100))% Charge")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(levelColor.opacity(0.9))
            }
            Spacer()
            
            BatteryIcon(level: level)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.02))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(levelColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var levelColor: Color {
        if level > 0.7 {
            return Theme.neonGreen
        } else if level > 0.3 {
            return Theme.neonGold
        } else {
            return Color.red
        }
    }
}

struct BatteryIcon: View {
    let level: Double
    
    var body: some View {
        HStack(spacing: 1.5) {
            // Battery Body
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(levelColor.opacity(0.4), lineWidth: 1)
                    .frame(width: 28, height: 14)
                
                let fillWidth = max(1.0, CGFloat(level * 24.0))
                RoundedRectangle(cornerRadius: 2)
                    .fill(levelColor)
                    .frame(width: fillWidth, height: 10)
                    .padding(.leading, 2)
            }
            
            // Terminal
            RoundedRectangle(cornerRadius: 1)
                .fill(levelColor.opacity(0.4))
                .frame(width: 2, height: 6)
        }
    }
    
    private var levelColor: Color {
        if level > 0.7 {
            return Theme.neonGreen
        } else if level > 0.3 {
            return Theme.neonGold
        } else {
            return Color.red
        }
    }
}

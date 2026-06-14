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
                
                // Nutrition Tab
                NutritionView()
                    .tabItem {
                        Image(systemName: "apple.logo")
                        Text("Nutrition")
                    }
                    .tag(1)
                
                // History Tab
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                    .tag(2)
                
                // Progress Tab
                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(3)
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
    
    // Nutrition profile state variables
    @State private var ageString = ""
    @State private var sex = "Male"
    @State private var weightString = ""
    @State private var heightString = ""
    @State private var activityLevel = "Sedentary"
    @State private var targetWeightString = ""
    @State private var goalType = "Lose Weight"
    @State private var weeklyPace = 1.0
    @State private var calculatedBMR = 0.0
    @State private var calculatedBudget = 0
    @State private var showBiometricsSaveSuccess = false
    
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
                    .submitLabel(.done)
                    .onSubmit { hideKeyboard() }
                
                Button(action: {
                    hideKeyboard()
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
                                    .submitLabel(.done)
                                    .onSubmit { hideKeyboard() }
                                
                                if editedDisplayName != (authManager.currentUser?.displayName ?? "") && !editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button(action: {
                                        hideKeyboard()
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
                        
                        // Biometrics Form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BIOMETRICS")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .tracking(1)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Age (years)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    TextField("", text: $ageString, prompt: Text("e.g. 25").foregroundColor(.white.opacity(0.4)))
                                        .keyboardType(.numberPad)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .keyboardDoneButton()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sex")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Menu {
                                        Button("Male") { sex = "Male" }
                                        Button("Female") { sex = "Female" }
                                    } label: {
                                        HStack {
                                            Text(sex)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.neonCyan)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Weight (lbs)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    TextField("", text: $weightString, prompt: Text("e.g. 160.0").foregroundColor(.white.opacity(0.4)))
                                        .keyboardType(.decimalPad)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .keyboardDoneButton()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Height (inches)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    TextField("", text: $heightString, prompt: Text("e.g. 68.0").foregroundColor(.white.opacity(0.4)))
                                        .keyboardType(.decimalPad)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .keyboardDoneButton()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Goals & Activity Form
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GOALS & ACTIVITY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .tracking(1)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Target Weight (lbs)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    TextField("", text: $targetWeightString, prompt: Text("e.g. 150.0").foregroundColor(.white.opacity(0.4)))
                                        .keyboardType(.decimalPad)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .keyboardDoneButton()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Goal Type")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Menu {
                                        Button("Lose Weight") { goalType = "Lose Weight" }
                                        Button("Maintain Weight") { goalType = "Maintain Weight" }
                                        Button("Gain Weight") { goalType = "Gain Weight" }
                                    } label: {
                                        HStack {
                                            Text(goalType)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.neonCyan)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            if goalType != "Maintain Weight" {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Weekly Pace")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                    Menu {
                                        ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { pace in
                                            Button("\(pace, specifier: "%.1f") lbs/week") { weeklyPace = pace }
                                        }
                                    } label: {
                                        HStack {
                                            Text("\(weeklyPace, specifier: "%.1f") lbs/week")
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.neonCyan)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Activity Level")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Menu {
                                    ForEach(["Sedentary", "Lightly Active", "Moderately Active", "Very Active", "Extra Active"], id: \.self) { level in
                                        Button(level) { activityLevel = level }
                                    }
                                } label: {
                                    HStack {
                                        Text(activityLevel)
                                            .fontWeight(.bold)
                                            .foregroundColor(Theme.neonCyan)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Button(action: saveProfileMetrics) {
                                Text(showBiometricsSaveSuccess ? "SAVED ✓" : "SAVE BIOMETRICS & GOALS")
                                    .font(.footnote)
                                    .fontWeight(.black)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(14)
                                    .background(showBiometricsSaveSuccess ? AnyShapeStyle(Theme.neonGreen) : AnyShapeStyle(Theme.primaryGradient))
                                    .cornerRadius(10)
                                    .shadow(color: (showBiometricsSaveSuccess ? Theme.neonGreen : Theme.neonCyan).opacity(0.2), radius: 6)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        
                        // Budget readout card
                        if calculatedBMR > 0 {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("ESTIMATED BMR")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(Int(calculatedBMR)) kcal")
                                        .font(.subheadline)
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                }
                                HStack {
                                    Text("DAILY CALORIE BUDGET")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(calculatedBudget) kcal")
                                        .font(.subheadline)
                                        .fontWeight(.black)
                                        .foregroundColor(Theme.neonGreen)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.25))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.neonGreen.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal)
                        }
                        
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
            if let profile = dbService.userProfile {
                ageString = String(profile.age)
                sex = profile.sex
                weightString = String(format: "%.1f", profile.weight)
                heightString = String(format: "%.1f", profile.height)
                activityLevel = profile.activityLevel
                targetWeightString = String(format: "%.1f", profile.targetWeight)
                goalType = profile.goalType
                weeklyPace = profile.weeklyPace
                calculatedBMR = profile.bmr
                calculatedBudget = profile.calorieBudget
            }
        }
    }
    
    // Save BMR/TDEE and profile metrics helper
    private func saveProfileMetrics() {
        hideKeyboard()
        guard let age = Int(ageString),
              let weight = Double(weightString),
              let height = Double(heightString),
              let targetWeight = Double(targetWeightString) else {
            return
        }
        
        let weightKg = weight * 0.45359237
        let heightCm = height * 2.54
        
        var computedBmr = 0.0
        if sex == "Male" {
            computedBmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + 5
        } else {
            computedBmr = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) - 161
        }
        
        var activityFactor = 1.2
        switch activityLevel {
        case "Sedentary": activityFactor = 1.2
        case "Lightly Active": activityFactor = 1.375
        case "Moderately Active": activityFactor = 1.55
        case "Very Active": activityFactor = 1.725
        case "Extra Active": activityFactor = 1.9
        default: activityFactor = 1.2
        }
        
        let tdee = computedBmr * activityFactor
        
        var computedBudget = tdee
        if goalType == "Lose Weight" {
            computedBudget = tdee - (weeklyPace * 500)
        } else if goalType == "Gain Weight" {
            computedBudget = tdee + (weeklyPace * 500)
        }
        
        // Safety check (minimum 1200 kcal)
        let finalBudget = max(1200, Int(computedBudget))
        
        let newProfile = UserProfile(
            id: authManager.currentUser?.uid,
            age: age,
            sex: sex,
            weight: weight,
            height: height,
            activityLevel: activityLevel,
            targetWeight: targetWeight,
            goalType: goalType,
            weeklyPace: weeklyPace,
            bmr: computedBmr,
            calorieBudget: finalBudget,
            updatedAt: Date()
        )
        
        dbService.saveUserProfile(newProfile) { success in
            if success {
                self.calculatedBMR = computedBmr
                self.calculatedBudget = finalBudget
                withAnimation {
                    self.showBiometricsSaveSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.showBiometricsSaveSuccess = false
                    }
                }
            }
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
                                    .submitLabel(.done)
                                    .onSubmit { hideKeyboard() }
                                
                                Button(action: {
                                    hideKeyboard()
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
    @State private var showingFullHistory = false
    
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
                        
                        if dbService.isHealthKitAuthorized {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Synced")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Category Balance Scorecard (Replacing weekly overview card)
                    categoryBalanceCard
                        .padding(.horizontal)
                    
                    // Unified Sessions List (LIFT workouts + Apple Health activities merged by date)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("COMPLETED SESSIONS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonCyan)
                            .tracking(2)
                            .padding(.horizontal)
                        
                        let hasAnything = !dbService.workoutLogs.isEmpty || !dbService.healthKitWorkouts.isEmpty
                        
                        if !hasAnything {
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
                            // Merge LIFT logs + HealthKit activities into one chronological list.
                            // Use a tagged enum so ForEach can handle both types with stable IDs.
                            let liftItems: [(date: Date, id: String, isHealthKit: Bool, log: WorkoutLog?, activity: AppleHealthActivity?)] =
                                dbService.workoutLogs.map { (date: $0.date, id: "lift-\($0.idString)", isHealthKit: false, log: $0, activity: nil) }
                            let hkItems: [(date: Date, id: String, isHealthKit: Bool, log: WorkoutLog?, activity: AppleHealthActivity?)] =
                                dbService.healthKitWorkouts.map { (date: $0.date, id: "hk-\($0.id)", isHealthKit: true, log: nil, activity: $0) }
                            let merged = (liftItems + hkItems).sorted { $0.date > $1.date }
                            
                            let calendar = Calendar.current
                            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                            let thisWeeksSessions = merged.filter { $0.date >= startOfWeek }
                            
                            ForEach(thisWeeksSessions, id: \.id) { item in
                                if item.isHealthKit, let activity = item.activity {
                                    AppleHealthActivityCard(activity: activity)
                                        .padding(.horizontal)
                                } else if let log = item.log {
                                    WorkoutLogCard(log: log)
                                        .padding(.horizontal)
                                }
                            }
                            
                            if merged.count > thisWeeksSessions.count {
                                Button(action: { showingFullHistory = true }) {
                                    HStack {
                                        Text("VIEW ALL PAST SESSIONS (\(merged.count))")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundColor(.black)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.primaryGradient)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showingFullHistory) {
            FullHistoryView()
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

// MARK: - Apple Health Activity Card
struct AppleHealthActivityCard: View {
    let activity: AppleHealthActivity
    @State private var isExpanded = false
    
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
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                Text(activity.name.uppercased())
                                    .font(.headline)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Text(formatDate(activity.date))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("Apple Health Workout")
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
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Time Spent", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatDuration(activity.duration))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Label("Calories Burned", systemImage: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(activity.caloriesBurned)) kcal")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonGold)
                    }
                    
                    HStack {
                        Label("Calorie Bonus (50%)", systemImage: "bolt.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("+\(Int(activity.caloriesBurned * 0.5)) kcal")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonGreen)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .glassCard()
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) mins"
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
    
    // Segment selector
    @State private var progressMode = 0 // 0: Workouts, 1: Body Weight
    
    // Weight log input
    @State private var showingWeightLog = false
    @State private var newWeightString = ""
    @State private var selectedWeekOffset = 0
    @State private var weightLogToDelete: WeightLog? = nil
    @State private var showingWeightDeleteConfirmation = false
    @State private var showingFullExerciseHistory = false
    @State private var showingFullWeightHistory = false
    
    // Zoom/scroll properties
    @State private var exerciseZoomScale: Double = 1.0
    @State private var weightZoomScale: Double = 1.0
    @GestureState private var exerciseGestureZoom: Double = 1.0
    @GestureState private var weightGestureZoom: Double = 1.0
    
    private var visibleExerciseDuration: Double {
        let chartData = selectedExerciseId.map { getChartData(for: $0) } ?? []
        guard let first = chartData.first, let last = chartData.last else {
            let days = max(3.0, min(180.0, 30.0 / (exerciseZoomScale * exerciseGestureZoom)))
            return days * 24 * 3600
        }
        let dataSpan = max(24 * 3600 * 3, last.date.timeIntervalSince(first.date)) // at least 3 days
        let days = dataSpan / (24 * 3600)
        let visibleDays = max(3.0, min(180.0, days / (exerciseZoomScale * exerciseGestureZoom)))
        return visibleDays * 24 * 3600
    }
    
    private var visibleWeightDuration: Double {
        guard let first = dbService.weightLogs.first, let last = dbService.weightLogs.last else {
            let days = max(3.0, min(180.0, 30.0 / (weightZoomScale * weightGestureZoom)))
            return days * 24 * 3600
        }
        let dataSpan = max(24 * 3600 * 3, last.date.timeIntervalSince(first.date)) // at least 3 days
        let days = dataSpan / (24 * 3600)
        let visibleDays = max(3.0, min(180.0, days / (weightZoomScale * weightGestureZoom)))
        return visibleDays * 24 * 3600
    }
    
    private var exerciseZoomGesture: some Gesture {
        MagnificationGesture()
            .updating($exerciseGestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                exerciseZoomScale = max(0.2, min(10.0, exerciseZoomScale * value))
            }
    }
    
    private var weightZoomGesture: some Gesture {
        MagnificationGesture()
            .updating($weightGestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                weightZoomScale = max(0.2, min(10.0, weightZoomScale * value))
            }
    }
    
    private var todayWeightLog: WeightLog? {
        let calendar = Calendar.current
        return dbService.weightLogs.first { calendar.isDateInToday($0.date) }
    }
    
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
                
                // Segment Picker
                HStack(spacing: 0) {
                    Button(action: { progressMode = 0 }) {
                        Text("WORKOUTS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(progressMode == 0 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(progressMode == 0 ? Theme.neonCyan : Color.clear)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { progressMode = 1 }) {
                        Text("BODY WEIGHT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(progressMode == 1 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(progressMode == 1 ? Theme.neonGold : Color.clear)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { progressMode = 2 }) {
                        Text("GOALS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(progressMode == 2 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(progressMode == 2 ? Theme.neonPurple : Color.clear)
                            .cornerRadius(8)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if progressMode == 0 {
                    // WORKOUTS CONTENT
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
                                                AxisMarks { _ in
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
                                            .chartScrollableAxes(.horizontal)
                                            .chartXVisibleDomain(length: visibleExerciseDuration)
                                            .gesture(exerciseZoomGesture)
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
                                            
                                            ForEach(chartData.prefix(5), id: \.date) { data in
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
                                            
                                            if chartData.count > 5 {
                                                Button(action: { showingFullExerciseHistory = true }) {
                                                    HStack {
                                                        Text("VIEW ALL LOGGED HISTORY (\(chartData.count))")
                                                            .font(.caption)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.black)
                                                        Image(systemName: "arrow.right")
                                                            .font(.caption)
                                                            .foregroundColor(.black)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Theme.primaryGradient)
                                                    .cornerRadius(12)
                                                    .padding(.horizontal)
                                                    .padding(.top, 4)
                                                }
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
                } else if progressMode == 1 {
                    // BODY WEIGHT CONTENT
                    ScrollView {
                        bodyWeightSection
                            .padding(.vertical)
                    }
                } else {
                    // GOALS CONTENT
                    ScrollView {
                        weeklyGoalsSection
                            .padding(.vertical)
                    }
                }
            }
        }
        .sheet(isPresented: $showingWeightLog) {
            weightLogSheet
        }
        .sheet(isPresented: $showingFullExerciseHistory) {
            if let selectedId = selectedExerciseId, let exercise = dbService.exercises.first(where: { $0.idString == selectedId }) {
                FullExerciseHistoryView(exerciseName: exercise.name, chartData: getChartData(for: selectedId))
            }
        }
        .sheet(isPresented: $showingFullWeightHistory) {
            FullWeightHistoryView()
        }
        .confirmationDialog(
            "Delete Weight Log?",
            isPresented: $showingWeightDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                if let log = weightLogToDelete, let id = log.id {
                    dbService.deleteWeightLog(id: id) { _ in }
                }
            }
            Button("Cancel", role: .cancel) {
                weightLogToDelete = nil
            }
        } message: {
            if let log = weightLogToDelete {
                Text("Are you sure you want to delete the weight log of \(log.weight, specifier: "%.1f") lbs on \(formatShortDate(log.date))?")
            }
        }
    }
    
    // MARK: - Body Weight Section View
    
    private var bodyWeightSection: some View {
        let currentWeight = dbService.weightLogs.last?.weight ?? dbService.userProfile?.weight ?? 0.0
        let targetWeight = dbService.userProfile?.targetWeight ?? 0.0
        let distance = currentWeight - targetWeight
        
        return VStack(spacing: 20) {
            // Weight logging panel (Hides/Shows button based on today's logs)
            HStack {
                if let todayLog = todayWeightLog {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S WEIGHT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonGold)
                            .tracking(1)
                        Text("\(todayLog.weight, specifier: "%.1f") lbs")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEIGHT LOG")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .tracking(1)
                        Text("No weight logged today")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: {
                        if let lastWeight = dbService.weightLogs.last?.weight {
                            newWeightString = String(format: "%.1f", lastWeight)
                        } else if let profileWeight = dbService.userProfile?.weight {
                            newWeightString = String(format: "%.1f", profileWeight)
                        } else {
                            newWeightString = ""
                        }
                        showingWeightLog = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "scalemass.fill")
                            Text("Log Weight")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Theme.goldGradient)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
            
            // Distance card & Chart
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEIGHT PROGRESSION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonGold)
                            .tracking(2)
                        
                        if currentWeight > 0 && targetWeight > 0 {
                            let distanceString = String(format: "%.1f", abs(distance))
                            let goalText = distance > 0 ? "\(distanceString) lbs to lose" : (distance < 0 ? "\(distanceString) lbs to gain" : "Goal reached!")
                            Text(goalText)
                                .font(.subheadline)
                                .fontWeight(.black)
                                .foregroundColor(Theme.neonGreen)
                        } else {
                            Text("Configure targets in Profile settings")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(Theme.neonGold)
                }
                
                if dbService.weightLogs.count >= 2 {
                    Chart {
                        ForEach(dbService.weightLogs) { log in
                            LineMark(
                                x: .value("Date", log.date, unit: .day),
                                y: .value("Weight", log.weight)
                            )
                            .foregroundStyle(Theme.goldGradient)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", log.date, unit: .day),
                                y: .value("Weight", log.weight)
                            )
                            .foregroundStyle(Theme.neonGold)
                        }
                        
                        if targetWeight > 0 {
                            RuleMark(
                                y: .value("Target Weight", targetWeight)
                            )
                            .foregroundStyle(Color.red.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal: \(Int(targetWeight)) lbs")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(4)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: getWeightChartYScaleDomain())
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.05))
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.05))
                            AxisValueLabel().foregroundStyle(Color.gray)
                        }
                    }
                    .chartScrollableAxes(.horizontal)
                    .chartXVisibleDomain(length: visibleWeightDuration)
                    .gesture(weightZoomGesture)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.flattrend.xyaxis")
                            .font(.title)
                            .foregroundColor(Theme.neonGold.opacity(0.5))
                        Text("Log your weight on 2 different days to generate progression chart.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .background(Color.white.opacity(0.01))
                    .cornerRadius(12)
                }
            }
            .padding()
            .glassCard()
            .padding(.horizontal)
            
            // Weight log history list (limited to 5 logs)
            if !dbService.weightLogs.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WEIGHT LOG HISTORY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    VStack(spacing: 8) {
                        ForEach(dbService.weightLogs.reversed().prefix(5)) { log in
                            HStack {
                                Text(formatShortDate(log.date))
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(log.weight, specifier: "%.1f") lbs")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.neonGold)
                            }
                            .padding()
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                weightLogToDelete = log
                                showingWeightDeleteConfirmation = true
                            }
                        }
                    }
                    
                    if dbService.weightLogs.count > 5 {
                        Button(action: { showingFullWeightHistory = true }) {
                            HStack {
                                Text("VIEW ALL WEIGHT HISTORY (\(dbService.weightLogs.count))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.goldGradient)
                            .cornerRadius(12)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .glassCard()
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Weight Log Sheet
    
    private var weightLogSheet: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Log Current Weight")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("", text: $newWeightString, prompt: Text("e.g. 155.0").foregroundColor(.white.opacity(0.4)))
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .keyboardDoneButton()
                
                Button(action: {
                    hideKeyboard()
                    let cleanString = newWeightString.replacingOccurrences(of: ",", with: ".")
                    if let weight = Double(cleanString) {
                        dbService.saveWeightLog(weight: weight, date: Date()) { success in
                            DispatchQueue.main.async {
                                newWeightString = ""
                                showingWeightLog = false
                            }
                        }
                    }
                }) {
                    Text("SAVE WEIGHT")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.goldGradient)
                        .cornerRadius(10)
                }
                .disabled(Double(newWeightString.replacingOccurrences(of: ",", with: ".")) == nil)
                
                Button("Cancel") {
                    showingWeightLog = false
                }
                .foregroundColor(.gray)
                .font(.footnote)
            }
            .padding(30)
            .glassCard()
            .padding(20)
        }
    }
    
    // MARK: - Workout Analytics Helpers
    
    struct ExerciseProgressPoint {
        let date: Date
        let maxWeight: Double
        let rating: Int
    }
    
    private func getChartData(for exerciseId: String) -> [ExerciseProgressPoint] {
        var points: [ExerciseProgressPoint] = []
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
    
    private func getWeightChartYScaleDomain() -> ClosedRange<Double> {
        let weights = dbService.weightLogs.map { $0.weight }
        let minW = weights.min() ?? 100.0
        let maxW = weights.max() ?? 200.0
        
        let target = dbService.userProfile?.targetWeight ?? minW
        
        let absoluteMin = min(minW, target)
        let absoluteMax = max(maxW, target)
        
        let lower = (absoluteMin - 5).isNaN || (absoluteMin - 5).isInfinite ? 100.0 : (absoluteMin - 5)
        let upper = (absoluteMax + 5).isNaN || (absoluteMax + 5).isInfinite ? 200.0 : (absoluteMax + 5)
        
        return lower...upper
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private var weeklyGoalsSection: some View {
        VStack(spacing: 24) {
            // Week navigation header
            HStack {
                Button(action: {
                    withAnimation {
                        selectedWeekOffset -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(weekHeaderString().uppercased())
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .tracking(1.5)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectedWeekOffset += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(selectedWeekOffset < 0 ? .white : .gray.opacity(0.3))
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .disabled(selectedWeekOffset >= 0)
            }
            .padding(.horizontal)
            
            // Vertical Stack of full-width tiles
            VStack(spacing: 16) {
                GoalProgressRing(
                    progress: Double(weeklyProteinMetCount()) / 7.0,
                    title: "Protein Target",
                    valueText: "\(weeklyProteinMetCount())/7 days",
                    streak: calculateStreak(forGoal: proteinGoalMet),
                    color: Theme.neonPurple
                )
                
                GoalProgressRing(
                    progress: Double(weeklyWorkoutCount()) / 3.0,
                    title: "Workout Target",
                    valueText: "\(weeklyWorkoutCount())/3 sessions",
                    streak: calculateStreak(forGoal: workoutGoalMet),
                    color: Theme.neonCyan
                )
                
                GoalProgressRing(
                    progress: Double(weeklyWaterMetCount()) / 7.0,
                    title: "Water Target",
                    valueText: "\(weeklyWaterMetCount())/7 days",
                    streak: calculateStreak(forGoal: waterGoalMet),
                    color: Theme.neonOrange
                )
                
                GoalProgressRing(
                    progress: Double(weeklyDeficitMetCount()) / 7.0,
                    title: "Deficit Target",
                    valueText: "\(weeklyDeficitMetCount())/7 days",
                    streak: calculateStreak(forGoal: deficitGoalMet),
                    color: Theme.neonGreen
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func datesForSelectedWeek() -> [Date] {
        let calendar = Calendar.current
        guard let targetDate = calendar.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: Date()) else { return [] }
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private func weekHeaderString() -> String {
        let dates = datesForSelectedWeek()
        guard let first = dates.first, let last = dates.last else { return "WEEK" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startStr = formatter.string(from: first)
        let endStr = formatter.string(from: last)
        
        if selectedWeekOffset == 0 {
            return "THIS WEEK (\(startStr) - \(endStr))"
        } else if selectedWeekOffset == -1 {
            return "LAST WEEK (\(startStr) - \(endStr))"
        } else {
            return "\(startStr) - \(endStr)"
        }
    }
    
    private func proteinGoalMet(for date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let logs = dbService.last30DaysFoodLogs.filter { $0.date >= startOfDay && $0.date < endOfDay }
        guard !logs.isEmpty else { return false }
        let consumed = logs.reduce(0.0) { $0 + $1.protein }
        let target = (dbService.userProfile?.weight ?? 150.0) / 2.20462
        return consumed >= target
    }
    
    private func waterGoalMet(for date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let dateString = formatter.string(from: date)
        let intake = dbService.last30DaysWaterLogs[dateString] ?? 0
        return intake >= 64
    }
    
    private func deficitGoalMet(for date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let logs = dbService.last30DaysFoodLogs.filter { $0.date >= startOfDay && $0.date < endOfDay }
        guard !logs.isEmpty else { return false }
        let consumed = logs.reduce(0) { $0 + $1.calories }
        let budget = dbService.userProfile?.calorieBudget ?? 2000
        return consumed <= budget
    }
    
    private func workoutGoalMet(for date: Date) -> Bool {
        let calendar = Calendar.current
        let startRange = calendar.date(byAdding: .day, value: -2, to: date)!
        let startOfDay = calendar.startOfDay(for: startRange)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        return dbService.workoutLogs.contains { log in
            log.date >= startOfDay && log.date < endOfDay
        }
    }
    
    private func weeklyProteinMetCount() -> Int {
        datesForSelectedWeek().filter { proteinGoalMet(for: $0) }.count
    }
    
    private func weeklyWaterMetCount() -> Int {
        datesForSelectedWeek().filter { waterGoalMet(for: $0) }.count
    }
    
    private func weeklyDeficitMetCount() -> Int {
        datesForSelectedWeek().filter { deficitGoalMet(for: $0) }.count
    }
    
    private func weeklyWorkoutCount() -> Int {
        let calendar = Calendar.current
        let weekDates = datesForSelectedWeek()
        guard let startOfWeek = weekDates.first, let endOfWeek = weekDates.last else { return 0 }
        let startOfDay = calendar.startOfDay(for: startOfWeek)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endOfWeek))!
        let filteredLogs = dbService.workoutLogs.filter { log in
            log.date >= startOfDay && log.date < endOfDay
        }
        let uniqueDays = Set(filteredLogs.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    private func calculateStreak(forGoal check: (Date) -> Bool) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let metYesterday = check(yesterday)
        let metToday = check(today)
        
        if !metYesterday && !metToday {
            return 0
        }
        
        var streakCount = 0
        let currentDate = metToday ? today : yesterday
        
        for i in 0..<365 {
            guard let checkDate = calendar.date(byAdding: .day, value: -i, to: currentDate) else { break }
            if check(checkDate) {
                streakCount += 1
            } else {
                break
            }
        }
        
        return streakCount
    }
}

// MARK: - Goal Progress Ring View
struct GoalProgressRing: View {
    let progress: Double
    let title: String
    let valueText: String
    let streak: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 6)
                    .frame(width: 54, height: 54)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 54, height: 54)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.spring(), value: progress)
                
                Text(valueText.components(separatedBy: " ").first ?? "")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                    .tracking(1)
                
                let desc = valueText.components(separatedBy: " ").last ?? ""
                Text("\(valueText.components(separatedBy: " ").first ?? "") \(desc) completed")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 12))
                Text("\(streak)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.neonOrange)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassCard()
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

// MARK: - Full History View Sheets

struct FullHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dbService: DatabaseService
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("ALL WORKOUT HISTORY")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.neonCyan)
                    .fontWeight(.bold)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        let liftItems: [(date: Date, id: String, isHealthKit: Bool, log: WorkoutLog?, activity: AppleHealthActivity?)] =
                            dbService.workoutLogs.map { (date: $0.date, id: "lift-\($0.idString)", isHealthKit: false, log: $0, activity: nil) }
                        let hkItems: [(date: Date, id: String, isHealthKit: Bool, log: WorkoutLog?, activity: AppleHealthActivity?)] =
                            dbService.healthKitWorkouts.map { (date: $0.date, id: "hk-\($0.id)", isHealthKit: true, log: nil, activity: $0) }
                        let merged = (liftItems + hkItems).sorted { $0.date > $1.date }
                        
                        if merged.isEmpty {
                            Text("No history found.")
                                .foregroundColor(.gray)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(merged, id: \.id) { item in
                                if item.isHealthKit, let activity = item.activity {
                                    AppleHealthActivityCard(activity: activity)
                                } else if let log = item.log {
                                    WorkoutLogCard(log: log)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

struct FullExerciseHistoryView: View {
    @Environment(\.dismiss) var dismiss
    let exerciseName: String
    let chartData: [AnalyticsView.ExerciseProgressPoint]
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("\(exerciseName.uppercased()) HISTORY")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.neonCyan)
                        .fontWeight(.bold)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 8) {
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
            }
        }
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct FullWeightHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dbService: DatabaseService
    @State private var weightLogToDelete: WeightLog? = nil
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("WEIGHT LOG HISTORY")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.neonGold)
                        .fontWeight(.bold)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dbService.weightLogs.reversed()) { log in
                            HStack {
                                Text(formatShortDate(log.date))
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(log.weight, specifier: "%.1f") lbs")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.neonGold)
                            }
                            .padding()
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                weightLogToDelete = log
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .confirmationDialog(
            "Delete Weight Log?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                if let log = weightLogToDelete, let id = log.id {
                    dbService.deleteWeightLog(id: id) { _ in }
                }
            }
            Button("Cancel", role: .cancel) {
                weightLogToDelete = nil
            }
        } message: {
            if let log = weightLogToDelete {
                Text("Are you sure you want to delete the weight log of \(log.weight, specifier: "%.1f") lbs on \(formatShortDate(log.date))?")
            }
        }
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

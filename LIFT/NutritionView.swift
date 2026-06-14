//
//  NutritionView.swift
//  LIFT
//

import SwiftUI
import Charts
import PhotosUI
import AVFoundation

struct NutritionView: View {
    @EnvironmentObject var dbService: DatabaseService
    @StateObject private var speechManager = SpeechManager()
    
    @State private var currentDate = Date()
    @State private var showingAddFood = false
    @State private var presetMealType = "Breakfast"
    @State private var foodBeingEdited: FoodLogEntry? = nil
    
    // Weight logging state
    @State private var showingWeightLogSheet = false
    @State private var newWeightString = ""
    @State private var selectedWeightDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date selector header
                        dateHeader
                            .padding(.horizontal)
                        
                        // Calorie budget ring / progress & Macros card
                        calorieProgressCard
                            .padding(.horizontal)
                        
                        // Body Weight card
                        weightCard
                            .padding(.horizontal)
                        
                        // Water Intake card
                        waterCard
                            .padding(.horizontal)
                        
                        // Meal categories list
                        mealSectionsList
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddFood) {
                AddFoodView(mealType: presetMealType, currentDate: currentDate)
                    .environmentObject(dbService)
            }
            .sheet(item: $foodBeingEdited) { entry in
                EditFoodSheetView(initialEntry: entry) { editedEntry in
                    if let _ = editedEntry.id {
                        dbService.updateFoodLog(editedEntry) { _ in }
                    }
                }
            }
            .sheet(isPresented: $showingWeightLogSheet) {
                weightLogSheet
            }
            .onAppear {
                dbService.startListeningToNutrition(for: currentDate)
            }
            .onChange(of: currentDate) { oldValue, newValue in
                dbService.startListeningToNutrition(for: newValue)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NUTRITION TRACKER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.neonPurple)
                    .tracking(2)
                
                HStack(spacing: 12) {
                    Button(action: { changeDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline)
                            .foregroundColor(Theme.neonCyan)
                    }
                    
                    Text(formatHeaderDate(currentDate))
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .frame(minWidth: 140)
                    
                    Button(action: { changeDate(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(Theme.neonCyan)
                    }
                }
            }
            Spacer()
        }
    }
    
    private var calorieProgressCard: some View {
        let budgetRaw = dbService.userProfile?.calorieBudget ?? 2000
        let healthKitCalories = dbService.healthKitWorkouts.reduce(0.0) { $0 + $1.caloriesBurned }
        let budgetBonus = Int(healthKitCalories * 0.5)
        let budget = max(1200, budgetRaw + budgetBonus) // Ensure budget is never 0 to prevent division by zero/NaN CoreGraphics warnings
        let consumed = dbService.todayFoodLogs.reduce(0) { $0 + $1.calories }
        let remaining = budget - consumed
        let ratio = min(1.0, Double(consumed) / Double(budget))
        
        // Macros consumed
        let proteinConsumed = dbService.todayFoodLogs.reduce(0.0) { $0 + $1.protein }
        let carbsConsumed = dbService.todayFoodLogs.reduce(0.0) { $0 + $1.carbs }
        let fatConsumed = dbService.todayFoodLogs.reduce(0.0) { $0 + $1.fat }
        
        // Macro targets (Protein based on 1g per kg of body weight, others on budget)
        let proteinTarget = (dbService.userProfile?.weight ?? 150.0) / 2.20462
        let carbsTarget = (Double(budget) * 0.45) / 4.0
        let fatTarget = (Double(budget) * 0.25) / 9.0
        
        return VStack(spacing: 20) {
            HStack(spacing: 24) {
                // Calorie progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 12)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(ratio.isNaN || ratio.isInfinite ? 0.0 : ratio))
                        .stroke(
                            Theme.primaryGradient,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.spring(), value: consumed)
                    
                    VStack(spacing: 2) {
                        Text("\(remaining)")
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        Text(remaining >= 0 ? "Left" : "Over")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                
                // Calorie breakdown
                VStack(alignment: .leading, spacing: 8) {
                    // Total
                    VStack(alignment: .leading, spacing: 1) {
                        Text("TOTAL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.gray)
                        Text("\(budget) kcal")
                            .font(.headline)
                            .fontWeight(.black)
                            .foregroundColor(Theme.neonCyan)
                    }
                    
                    Divider().background(Color.white.opacity(0.08))
                    
                    // Budget row
                    HStack {
                        Text("Budget")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(budgetRaw) kcal")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Active Calorie Bonus row
                    if budgetBonus > 0 {
                        HStack {
                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Theme.neonGreen)
                                Text("Active Calorie Bonus")
                                    .font(.caption2)
                                    .foregroundColor(Theme.neonGreen)
                            }
                            Spacer()
                            Text("+\(budgetBonus) kcal")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.neonGreen)
                        }
                    }
                    
                    // Consumed row
                    HStack {
                        Text("Consumed Today")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(consumed) kcal")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonPurple)
                    }
                }
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Macros progress bars
            VStack(spacing: 12) {
                macroProgressBar(name: "Protein", consumed: proteinConsumed, target: proteinTarget, color: Theme.neonPurple)
                macroProgressBar(name: "Carbohydrates", consumed: carbsConsumed, target: carbsTarget, color: Theme.neonCyan)
                macroProgressBar(name: "Fats", consumed: fatConsumed, target: fatTarget, color: Theme.neonGold)
            }
        }
        .padding()
        .glassCard()
    }
    
    private var weightCard: some View {
        let calendar = Calendar.current
        let weightLogForDate = dbService.weightLogs.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BODY WEIGHT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.neonGold)
                    .tracking(2)
                
                if let log = weightLogForDate {
                    Text("\(String(format: "%.1f", log.weight)) lbs")
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                } else {
                    Text("No weight logged for this date")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                if let log = weightLogForDate {
                    newWeightString = String(format: "%.1f", log.weight)
                } else if let lastWeight = dbService.weightLogs.last?.weight {
                    newWeightString = String(format: "%.1f", lastWeight)
                } else if let profileWeight = dbService.userProfile?.weight {
                    newWeightString = String(format: "%.1f", profileWeight)
                } else {
                    newWeightString = ""
                }
                selectedWeightDate = currentDate
                showingWeightLogSheet = true
            }) {
                Text(weightLogForDate != nil ? "EDIT WEIGHT" : "LOG WEIGHT")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Theme.goldGradient)
                    .cornerRadius(8)
            }
        }
        .padding()
        .glassCard()
    }
    
    private var waterCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("WATER INTAKE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.neonCyan)
                    .tracking(2)
                
                Text("\(dbService.waterIntake) oz")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                
                Text("Daily Target: 64 oz")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    dbService.updateWaterIntake(amount: -8, date: currentDate) { _ in }
                }) {
                    Image(systemName: "minus")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(dbService.waterIntake <= 0)
                
                Button(action: {
                    dbService.updateWaterIntake(amount: 8, date: currentDate) { _ in }
                }) {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Theme.neonCyan)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    private var weightLogSheet: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Log Weight")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("WEIGHT (LBS)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    TextField("", text: $newWeightString, prompt: Text("e.g. 155.0").foregroundColor(.white.opacity(0.4)))
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .keyboardDoneButton()
                }
                
                Button(action: {
                    hideKeyboard()
                    let cleanString = newWeightString.replacingOccurrences(of: ",", with: ".")
                    if let weight = Double(cleanString) {
                        dbService.saveWeightLog(weight: weight, date: currentDate) { success in
                            DispatchQueue.main.async {
                                newWeightString = ""
                                showingWeightLogSheet = false
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
                    showingWeightLogSheet = false
                }
                .foregroundColor(.gray)
                .font(.footnote)
            }
            .padding(30)
            .glassCard()
            .padding(20)
        }
    }
    
    private var mealSectionsList: some View {
        let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("TODAY'S LOGGED FOOD")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Theme.neonPurple)
                .tracking(2)
            
            ForEach(mealTypes, id: \.self) { mealType in
                let meals = dbService.todayFoodLogs.filter { $0.mealType == mealType }
                
                VStack(alignment: .leading, spacing: 0) {
                    // Meal Type Header
                    HStack {
                        Text(mealType.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        let totalCalories = meals.reduce(0) { $0 + $1.calories }
                        if totalCalories > 0 {
                            Text("·  \(totalCalories) kcal")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            presetMealType = mealType
                            showingAddFood = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.neonCyan)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.01))
                    
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    // Foods List
                    if meals.isEmpty {
                        Text("No food logged yet.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(meals) { meal in
                                FoodRow(
                                    meal: meal,
                                    onEdit: {
                                        foodBeingEdited = meal
                                    },
                                    onDelete: {
                                        if let id = meal.id {
                                            dbService.deleteFoodLog(id: id) { _ in }
                                        }
                                    }
                                )
                                
                                if meal != meals.last {
                                    Divider()
                                        .background(Color.white.opacity(0.05))
                                }
                            }
                        }
                    }
                }
                .glassCard()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func formatHeaderDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOMORROW"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date).uppercased()
        }
    }
    
    private func macroProgressBar(name: String, consumed: Double, target: Double, color: Color) -> some View {
        let rawProgress = target > 0 ? consumed / target : 0.0
        let progress = (rawProgress.isNaN || rawProgress.isInfinite) ? 0.0 : min(1.0, max(0.0, rawProgress))
        
        return VStack(spacing: 4) {
            HStack {
                Text(name.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(consumed))g / \(Int(target))g")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        .animation(.spring(), value: consumed)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Add Food View (Sheet)

struct AddFoodView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var dbService: DatabaseService
    
    let mealType: String
    let currentDate: Date
    
    @State private var activeTab = 0 // 0: LIFT AI, 1: Search, 2: Manual, 3: Custom
    
    // Search properties with debouncer
    @State private var searchQuery = ""
    @State private var searchResults: [OpenFoodFactsClient.Product] = []
    @State private var isSearching = false
    @State private var debounceTimer: Timer? = nil
    @State private var activeSearchTask: URLSessionDataTask? = nil
    @State private var searchErrorMessage: String? = nil
    @State private var isBarcodeSearchInProgress = false
    
    // Manual log properties
    @State private var foodName = ""
    @State private var caloriesString = ""
    @State private var proteinString = ""
    @State private var carbsString = ""
    @State private var fatString = ""
    @State private var saveAsCustomTemplate = false
    
    // Custom portion weight
    @State private var selectedProduct: OpenFoodFactsClient.Product? = nil
    @State private var portionWeightString = "100" // grams
    @State private var servingsString = "1.0" // servings multiplier
    
    // Speech and LIFT AI Chat Properties
    @StateObject private var speechManager = SpeechManager()
    @State private var chatInput = ""
    @State private var isAILoading = false
    @State private var recognizedFoodResult: GeminiClient.GeminiMealResult? = nil
    @State private var foodBeingEdited: FoodLogEntry? = nil
    @State private var activeAITask: URLSessionDataTask? = nil
    
    // Image analyzer
    @State private var showingImagePicker = false       // photo library
    @State private var showingCameraCapture = false     // AVFoundation camera
    @State private var selectedImage: UIImage? = nil
    
    // Barcode scanner
    @State private var showingBarcodeScanner = false
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text("ADD TO \(mealType.uppercased())")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Theme.neonCyan)
                    .tracking(2)
                    .padding(.vertical, 16)
                
                // Segmented Tabs Control
                HStack(spacing: 0) {
                    tabButton(title: "LIFT AI", index: 0)
                    tabButton(title: "Search", index: 1)
                    tabButton(title: "Manual", index: 2)
                    tabButton(title: "Custom", index: 3)
                }
                .padding(4)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Tab Contents
                Group {
                    switch activeTab {
                    case 0:
                        liftAITabView
                    case 1:
                        searchTabView
                    case 2:
                        manualTabView
                    case 3:
                        customMealsTabView
                    default:
                        EmptyView()
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .sheet(item: $selectedProduct) { product in
            portionConfigSheet(for: product)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCameraCapture) {
            CameraPhotoCaptureView { image in
                selectedImage = image
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { barcode in
                // Switch to Search tab and do a dedicated barcode lookup
                self.isBarcodeSearchInProgress = true
                self.activeTab = 1
                self.searchQuery = barcode
                self.performBarcodeSearch(barcode)
            }
        }
        .sheet(item: $foodBeingEdited) { entry in
            EditFoodSheetView(initialEntry: entry) { editedEntry in
                dbService.logFood(editedEntry) { success in
                    if success {
                        self.recognizedFoodResult = nil
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedImage) { oldValue, newImage in
            if let image = newImage {
                analyzeSelectedImage(image)
            }
        }
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { activeTab = index }) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(activeTab == index ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(activeTab == index ? Theme.neonCyan : Color.clear)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Search Tab
    
    private var searchTabView: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("", text: $searchQuery, prompt: Text("Search foods (e.g. Oats, Chicken)").foregroundColor(.white.opacity(0.4)))
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchQuery) { oldValue, newValue in
                        if isBarcodeSearchInProgress {
                            isBarcodeSearchInProgress = false
                        } else {
                            triggerDebouncedSearch()
                        }
                    }
                
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Theme.neonCyan)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            if isSearching {
                ProgressView()
                    .tint(Theme.neonCyan)
                    .frame(maxHeight: .infinity)
            } else if let errMsg = searchErrorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(Theme.neonGold)
                    Text(errMsg)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .frame(maxHeight: .infinity)
            } else if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("Search for packaged items to import calories and macros directly.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(searchResults) { product in
                            Button(action: {
                                selectedProduct = product
                                if let size = product.servingSize, size > 0 {
                                    portionWeightString = String(format: "%.0f", size)
                                } else {
                                    portionWeightString = "100"
                                }
                                servingsString = "1.0"
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack(spacing: 4) {
                                            if let brand = product.brand, !brand.isEmpty {
                                                Text(brand.capitalized)
                                                    .foregroundColor(Theme.neonCyan)
                                                Text("·")
                                            }
                                            
                                            if let nutriments = product.nutriments {
                                                let kcal = Int(nutriments.energyKcal ?? 0)
                                                Text("\(kcal) kcal/100g")
                                            }
                                            
                                            if let servingDesc = getServingDescription(for: product) {
                                                Text("·")
                                                Text(servingDesc)
                                            }
                                        }
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Theme.neonCyan)
                                        .font(.title3)
                                }
                                .padding()
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func triggerDebouncedSearch() {
        debounceTimer?.invalidate()
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If query is empty, cancel any in-flight task and clear results
        if trimmedQuery.isEmpty {
            activeSearchTask?.cancel()
            activeSearchTask = nil
            searchResults = []
            searchErrorMessage = nil
            isSearching = false
            return
        }
        
        // Don't send request until user has typed at least 3 characters
        guard trimmedQuery.count >= 3 else {
            activeSearchTask?.cancel()
            activeSearchTask = nil
            searchResults = []
            searchErrorMessage = nil
            isSearching = false
            return
        }
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            performSearch()
        }
    }
    
    private func performSearch() {
        hideKeyboard()
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 3 else { return }
        
        // Cancel previous request to avoid race conditions
        activeSearchTask?.cancel()
        
        isSearching = true
        searchErrorMessage = nil
        
        activeSearchTask = OpenFoodFactsClient.search(query: trimmedQuery) { results, errMsg in
            DispatchQueue.main.async {
                self.searchResults = results
                self.searchErrorMessage = errMsg
                self.isSearching = false
                self.activeSearchTask = nil
            }
        }
    }
    
    // Dedicated barcode/UPC lookup using the USDA gtinUpc filter.
    // The general text search endpoint doesn't match raw barcodes well;
    // the /foods/search endpoint with dataType=Branded finds packaged products by UPC.
    private func performBarcodeSearch(_ barcode: String) {
        hideKeyboard()
        activeSearchTask?.cancel()
        debounceTimer?.invalidate() // Invalidate any scheduled search timer to avoid overwriting barcode search
        isSearching = true
        searchErrorMessage = nil
        searchResults = []
        
        activeSearchTask = OpenFoodFactsClient.searchByBarcode(barcode) { results, errMsg in
            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
                self.activeSearchTask = nil
                self.isBarcodeSearchInProgress = false
                if results.isEmpty {
                    self.searchErrorMessage = errMsg ?? "No product found for barcode \(barcode). Try searching by name instead."
                } else {
                    self.searchErrorMessage = nil
                }
            }
        }
    }
    
    // Search product portion size configurator
    private func portionConfigSheet(for product: OpenFoodFactsClient.Product) -> some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Configure Portion")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.neonCyan)
                    .multilineTextAlignment(.center)
                
                if let servingDesc = getServingDescription(for: product) {
                    Text("Standard Serving: \(servingDesc)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, -12)
                }
                
                if let servingSize = product.servingSize, servingSize > 0 {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Servings")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("", text: $servingsString, prompt: Text("1.0").foregroundColor(.white.opacity(0.4)))
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .keyboardDoneButton()
                                .onChange(of: servingsString) { oldValue, newValue in
                                    let cleanValue = newValue.replacingOccurrences(of: ",", with: ".")
                                    if let servings = Double(cleanValue) {
                                        let computedGrams = servings * servingSize
                                        let newGramsStr = String(format: "%.0f", computedGrams)
                                        if portionWeightString != newGramsStr {
                                            portionWeightString = newGramsStr
                                        }
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight (grams)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            TextField("", text: $portionWeightString, prompt: Text("e.g. 100").foregroundColor(.white.opacity(0.4)))
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .keyboardDoneButton()
                                .onChange(of: portionWeightString) { oldValue, newValue in
                                    if let grams = Double(newValue) {
                                        let computedServings = grams / servingSize
                                        let newServingsStr = String(format: "%.1f", computedServings)
                                        if servingsString != newServingsStr {
                                            servingsString = newServingsStr
                                        }
                                    }
                                }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight consumed (grams)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextField("", text: $portionWeightString, prompt: Text("e.g. 100").foregroundColor(.white.opacity(0.4)))
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .keyboardDoneButton()
                    }
                }
                
                if let grams = Double(portionWeightString), let nut = product.nutriments {
                    let scale = grams / 100.0
                    let kcal = Int(Double(nut.energyKcal ?? 0) * scale)
                    let p = (nut.proteins ?? 0) * scale
                    let c = (nut.carbohydrates ?? 0) * scale
                    let f = (nut.fat ?? 0) * scale
                    
                    VStack(spacing: 8) {
                        Text("ESTIMATED MACROS (\(Int(grams))g):")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            macroBadge(name: "Cals", value: "\(kcal)")
                            Spacer()
                            macroBadge(name: "Prot", value: String(format: "%.1fg", p))
                            Spacer()
                            macroBadge(name: "Carb", value: String(format: "%.1fg", c))
                            Spacer()
                            macroBadge(name: "Fat", value: String(format: "%.1fg", f))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        hideKeyboard()
                        if let grams = Double(portionWeightString), let nut = product.nutriments {
                            let scale = grams / 100.0
                            let entry = FoodLogEntry(
                                name: product.name,
                                calories: Int(Double(nut.energyKcal ?? 0) * scale),
                                protein: (nut.proteins ?? 0) * scale,
                                carbs: (nut.carbohydrates ?? 0) * scale,
                                fat: (nut.fat ?? 0) * scale,
                                mealType: mealType,
                                date: currentDate
                            )
                            dbService.logFood(entry) { success in
                                if success {
                                    selectedProduct = nil
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }) {
                        Text("LOG FOOD")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryGradient)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        hideKeyboard()
                        if let grams = Double(portionWeightString), let nut = product.nutriments {
                            let scale = grams / 100.0
                            let tempEntry = FoodLogEntry(
                                id: nil,
                                name: product.name,
                                calories: Int(Double(nut.energyKcal ?? 0) * scale),
                                protein: (nut.proteins ?? 0) * scale,
                                carbs: (nut.carbohydrates ?? 0) * scale,
                                fat: (nut.fat ?? 0) * scale,
                                mealType: mealType,
                                date: currentDate
                            )
                            selectedProduct = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                self.foodBeingEdited = tempEntry
                            }
                        }
                    }) {
                        Text("EDIT DETAILS")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }
                
                Button("Cancel") {
                    selectedProduct = nil
                }
                .foregroundColor(.gray)
                .font(.footnote)
            }
            .padding(30)
            .glassCard()
            .padding(20)
        }
    }
    
    // MARK: - Manual Tab
    
    private var manualTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FOOD NAME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    TextField("", text: $foodName, prompt: Text("e.g. Scrambled Eggs").foregroundColor(.white.opacity(0.4)))
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .submitLabel(.done)
                        .onSubmit { hideKeyboard() }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CALORIES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        TextField("", text: $caloriesString, prompt: Text("kcal").foregroundColor(.white.opacity(0.4)))
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .keyboardDoneButton()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PROTEIN (G)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        TextField("", text: $proteinString, prompt: Text("grams").foregroundColor(.white.opacity(0.4)))
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .keyboardDoneButton()
                    }
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CARBS (G)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        TextField("", text: $carbsString, prompt: Text("grams").foregroundColor(.white.opacity(0.4)))
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .keyboardDoneButton()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FAT (G)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        TextField("", text: $fatString, prompt: Text("grams").foregroundColor(.white.opacity(0.4)))
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .keyboardDoneButton()
                    }
                }
                
                Toggle(isOn: $saveAsCustomTemplate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save as Custom Meal Template")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Save to template list for quick log next time.")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                Button(action: saveManualEntry) {
                    Text("LOG FOOD")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryGradient)
                        .cornerRadius(10)
                }
                .disabled(foodName.isEmpty || caloriesString.isEmpty)
            }
            .padding(.horizontal)
        }
    }
    
    private func saveManualEntry() {
        hideKeyboard()
        guard let calories = Int(caloriesString) else { return }
        let protein = Double(proteinString) ?? 0.0
        let carbs = Double(carbsString) ?? 0.0
        let fat = Double(fatString) ?? 0.0
        
        let entry = FoodLogEntry(
            name: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: mealType,
            date: currentDate
        )
        
        dbService.logFood(entry) { success in
            if success {
                if saveAsCustomTemplate {
                    let customMeal = CustomMeal(
                        name: foodName,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat
                    )
                    dbService.saveCustomMeal(customMeal) { _ in }
                }
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Custom Meals Tab
    
    private var customMealsTabView: some View {
        VStack {
            if dbService.customMeals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.minus")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("No saved custom meals. Turn on 'Save as Custom Meal Template' when logging a manual meal to add it here.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(dbService.customMeals) { meal in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.name)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 10) {
                                        Text("\(meal.calories) kcal")
                                            .foregroundColor(Theme.neonCyan)
                                        Text("P: \(Int(meal.protein))g")
                                        Text("C: \(Int(meal.carbs))g")
                                        Text("F: \(Int(meal.fat))g")
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    let entry = FoodLogEntry(
                                        name: meal.name,
                                        calories: meal.calories,
                                        protein: meal.protein,
                                        carbs: meal.carbs,
                                        fat: meal.fat,
                                        mealType: mealType,
                                        date: currentDate
                                    )
                                    dbService.logFood(entry) { success in
                                        if success {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }) {
                                    Text("LOG")
                                        .font(.caption)
                                        .fontWeight(.black)
                                        .foregroundColor(.black)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Theme.neonCyan)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    if let id = meal.id {
                                        dbService.deleteCustomMeal(id: id) { _ in }
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(.leading, 8)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - LIFT AI Tab
    
    private var aiInfoHeader: some View {
        VStack(spacing: 6) {
            Text("LIFT AI NUTRITION CO-PILOT")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Theme.neonPurple)
                .tracking(1)
            Text("Describe what you ate or snap a photo of your food. Tap the microphone to dictate your meal.")
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 8)
    }

    private var aiPhotoButtons: some View {
        HStack(spacing: 12) {
            Button(action: { triggerImagePicker(source: .camera) }) {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title3)
                    Text("Take Photo")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
            
            Button(action: { triggerImagePicker(source: .photoLibrary) }) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.title3)
                    Text("Upload Photo")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
        }
    }

    private var aiChatInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JUST ASK LIFT")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1)
            
            ZStack(alignment: .trailing) {
                TextField("", text: $chatInput, prompt: Text("Describe your meal, or tap mic to speak...").foregroundColor(.white.opacity(0.4)))
                    .padding()
                    .padding(.trailing, 80) // Leave room for Mic and Send buttons
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .submitLabel(.send)
                    .onSubmit {
                        analyzeChatText()
                    }
                
                HStack(spacing: 12) {
                    // Voice Dictation Button inside TextField
                    Button(action: toggleSpeechRecording) {
                        Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.title3)
                            .foregroundColor(speechManager.isRecording ? .red : .gray)
                    }
                    
                    // Send Button
                    Button(action: analyzeChatText) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundColor(chatInput.isEmpty ? .gray : Theme.neonCyan)
                    }
                    .disabled(chatInput.isEmpty)
                }
                .padding(.trailing, 12)
            }
            .onChange(of: speechManager.transcript) { oldValue, newValue in
                if !newValue.isEmpty {
                    chatInput = newValue
                }
            }
        }
    }

    private var aiResultPreview: some View {
        Group {
            if let result = recognizedFoodResult {
                VStack(spacing: 14) {
                    Text("LIFT AI Analysis:")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(Theme.neonCyan)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(result.name.uppercased())
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            Text(result.explanation)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineSpacing(2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            let tempEntry = FoodLogEntry(
                                id: nil,
                                name: result.name,
                                calories: result.calories,
                                protein: result.protein,
                                carbs: result.carbs,
                                fat: result.fat,
                                mealType: result.mealType,
                                date: currentDate
                            )
                            foodBeingEdited = tempEntry
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.neonCyan)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        macroBadge(name: "Calories", value: "\(result.calories) kcal")
                        Spacer()
                        macroBadge(name: "Protein", value: String(format: "%.1fg", result.protein))
                        Spacer()
                        macroBadge(name: "Carbs", value: String(format: "%.1fg", result.carbs))
                        Spacer()
                        macroBadge(name: "Fat", value: String(format: "%.1fg", result.fat))
                    }
                    
                    Button(action: {
                        let entry = FoodLogEntry(
                            name: result.name,
                            calories: result.calories,
                            protein: result.protein,
                            carbs: result.carbs,
                            fat: result.fat,
                            mealType: result.mealType, // AI's parsed type
                            date: currentDate
                        )
                        dbService.logFood(entry) { success in
                            if success {
                                recognizedFoodResult = nil
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("LOG THIS MEAL")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Theme.primaryGradient)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1))
            }
        }
    }

    private var liftAITabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                aiInfoHeader
                
                aiPhotoButtons
                
                aiChatInput
                
                // Loading / Response Readouts
                if isAILoading {
                    VStack(spacing: 16) {
                        BouncingAIView()
                        
                        Button(action: {
                            activeAITask?.cancel()
                            activeAITask = nil
                            isAILoading = false
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel Request")
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                
                if let errorMsg = speechManager.errorMessage {
                    Text(errorMsg)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                aiResultPreview
            }
            .padding(.horizontal)
        }
    }
    
    // Route to the correct sheet:
    // Camera → CameraPhotoCaptureView (AVFoundation, guaranteed to open camera)
    // Library → ImagePicker (UIImagePickerController for photo library)
    private func triggerImagePicker(source: UIImagePickerController.SourceType) {
        if source == .camera {
            showingCameraCapture = true
        } else {
            showingImagePicker = true
        }
    }
    
    // Analyze image using AI client
    private func analyzeSelectedImage(_ image: UIImage) {
        isAILoading = true
        recognizedFoodResult = nil
        
        activeAITask = GeminiClient.shared.analyzeImage(image, userPrompt: "Analyze the food in this photo, estimate calories and macros, and select a meal type from: Breakfast, Lunch, Dinner, Snack.") { result in
            DispatchQueue.main.async {
                self.isAILoading = false
                self.activeAITask = nil
                switch result {
                case .success(let geminiResult):
                    self.recognizedFoodResult = geminiResult
                case .failure(let error):
                    if (error as NSError).code != NSURLErrorCancelled {
                        self.speechManager.errorMessage = "AI Image Analysis failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // Analyze typed text / voice transcript using AI client
    private func analyzeChatText() {
        guard !chatInput.isEmpty else { return }
        hideKeyboard()
        isAILoading = true
        recognizedFoodResult = nil
        
        let prompt = "User food log statement: \"\(chatInput)\". Estimate calories and macros, and map to a meal type (Breakfast, Lunch, Dinner, Snack)."
        
        activeAITask = GeminiClient.shared.analyzeText(prompt) { result in
            DispatchQueue.main.async {
                self.isAILoading = false
                self.activeAITask = nil
                switch result {
                case .success(let geminiResult):
                    self.recognizedFoodResult = geminiResult
                    self.chatInput = ""
                case .failure(let error):
                    if (error as NSError).code != NSURLErrorCancelled {
                        self.speechManager.errorMessage = "AI Text analysis failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // Speech recording toggle
    private func toggleSpeechRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            speechManager.checkPermissions { granted in
                if granted {
                    self.speechManager.startRecording()
                } else {
                    self.speechManager.errorMessage = "Microphone and Speech permissions are required."
                }
            }
        }
    }
    
    // MARK: - General helpers
    
    private func macroBadge(name: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(name.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.black)
                .foregroundColor(.white)
        }
        .frame(minWidth: 50)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }
}

// MARK: - USDA FoodData Central API Client

fileprivate struct USDASearchResponse: Codable {
    let foods: [USDAFood]?
}

fileprivate struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]?
    let brandOwner: String?
    let brandName: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
}

fileprivate struct USDANutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String?
    let value: Double?
}

struct OpenFoodFactsClient {
    struct Product: Identifiable, Codable {
        var id: String { code }
        let code: String
        let product_name: String?
        let product_name_en: String?
        let nutriments: Nutriments?
        
        let brand: String?
        let servingSize: Double?
        let servingSizeUnit: String?
        let householdServing: String?
        
        var name: String {
            product_name_en ?? product_name ?? "Unknown Food"
        }
    }
    
    struct Nutriments: Codable {
        let energyKcal: Double?
        let proteins: Double?
        let carbohydrates: Double?
        let fat: Double?
        
        enum CodingKeys: String, CodingKey {
            case energyKcal = "energy-kcal_100g"
            case proteins = "proteins_100g"
            case carbohydrates = "carbohydrates_100g"
            case fat = "fat_100g"
        }
    }
    
    @discardableResult
    static func search(query: String, completion: @escaping ([Product], String?) -> Void) -> URLSessionDataTask? {
        let apiKey = Secrets.usdaApiKey
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(apiKey)&query=\(encodedQuery)&pageSize=20") else {
            completion([], "Invalid search term.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as NSError? {
                if error.code == NSURLErrorCancelled {
                    return // Silent return if task was cancelled
                }
                DispatchQueue.main.async {
                    completion([], "Network error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion([], "No response received from USDA FoodData Central.")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(USDASearchResponse.self, from: data)
                
                let products = result.foods?.map { food -> Product in
                    var energy: Double = 0.0
                    var protein: Double = 0.0
                    var carbs: Double = 0.0
                    var fat: Double = 0.0
                    
                    if let nutrients = food.foodNutrients {
                        for nutrient in nutrients {
                            let name = (nutrient.nutrientName ?? "").lowercased()
                            let id = nutrient.nutrientId
                            
                            if id == 208 || id == 1008 || name.contains("energy") || name.contains("calories") {
                                energy = nutrient.value ?? 0.0
                            } else if id == 203 || id == 1003 || name.contains("protein") {
                                protein = nutrient.value ?? 0.0
                            } else if id == 205 || id == 1005 || name.contains("carbohydrate") {
                                carbs = nutrient.value ?? 0.0
                            } else if id == 204 || id == 1004 || name.contains("fat") || name.contains("lipid") {
                                fat = nutrient.value ?? 0.0
                            }
                        }
                    }
                    
                    let nutriments = Nutriments(
                        energyKcal: energy,
                        proteins: protein,
                        carbohydrates: carbs,
                        fat: fat
                    )
                    
                    let brand = food.brandOwner ?? food.brandName
                    
                    return Product(
                        code: "\(food.fdcId)",
                        product_name: food.description,
                        product_name_en: food.description,
                        nutriments: nutriments,
                        brand: brand,
                        servingSize: food.servingSize,
                        servingSizeUnit: food.servingSizeUnit,
                        householdServing: food.householdServingFullText
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    completion(products, nil)
                }
            } catch {
                print("Error parsing USDA FoodData Central response: \(error)")
                DispatchQueue.main.async {
                    completion([], "Failed to parse search results.")
                }
            }
        }
        task.resume()
        return task
    }
    
    // Barcode/UPC lookup via Open Food Facts (v3 API).
    // Tries the raw scanned barcode first, then strips the leading zero and retries.
    @discardableResult
    static func searchByBarcode(_ barcode: String, completion: @escaping ([Product], String?) -> Void) -> URLSessionDataTask? {
        let cleaned = barcode.trimmingCharacters(in: .whitespaces)
        let alternate: String? = (cleaned.count == 13 && cleaned.hasPrefix("0")) ? String(cleaned.dropFirst()) : nil
        
        func parseProduct(from json: [String: Any], code: String) -> Product? {
            guard let productRaw = json["product"] as? [String: Any] else { return nil }
            let name = (productRaw["product_name"] as? String)
                ?? (productRaw["product_name_en"] as? String) ?? "Unknown Product"
            let brand = productRaw["brands"] as? String
            let n = productRaw["nutriments"] as? [String: Any] ?? [:]
            
            let servingSize: Double
            if let ssDouble = productRaw["serving_quantity"] as? Double {
                servingSize = ssDouble
            } else if let ssInt = productRaw["serving_quantity"] as? Int {
                servingSize = Double(ssInt)
            } else {
                servingSize = 0.0
            }
            
            func doubleValue(for key: String) -> Double? {
                if let val = n[key] as? Double { return val }
                if let val = n[key] as? Int { return Double(val) }
                return nil
            }
            
            // Prefer 100g values. If missing, fall back to serving values converted to 100g.
            let energy = doubleValue(for: "energy-kcal_100g")
                ?? doubleValue(for: "energy-kcal")
                ?? (servingSize > 0 ? ((doubleValue(for: "energy-kcal_serving") ?? 0.0) * 100.0 / servingSize) : 0.0)
                
            let protein = doubleValue(for: "proteins_100g")
                ?? doubleValue(for: "proteins")
                ?? (servingSize > 0 ? ((doubleValue(for: "proteins_serving") ?? 0.0) * 100.0 / servingSize) : 0.0)
                
            let carbs = doubleValue(for: "carbohydrates_100g")
                ?? doubleValue(for: "carbohydrates")
                ?? (servingSize > 0 ? ((doubleValue(for: "carbohydrates_serving") ?? 0.0) * 100.0 / servingSize) : 0.0)
                
            let fat = doubleValue(for: "fat_100g")
                ?? doubleValue(for: "fat")
                ?? (servingSize > 0 ? ((doubleValue(for: "fat_serving") ?? 0.0) * 100.0 / servingSize) : 0.0)
                
            return Product(
                code: code,
                product_name: name, product_name_en: name,
                nutriments: Nutriments(energyKcal: energy, proteins: protein, carbohydrates: carbs, fat: fat),
                brand: brand,
                servingSize: servingSize > 0 ? servingSize : nil,
                servingSizeUnit: (productRaw["serving_quantity_unit"] as? String) ?? "g",
                householdServing: productRaw["serving_size"] as? String
            )
        }
        
        func fetch(_ code: String, fallback: String?, done: @escaping ([Product], String?) -> Void) -> URLSessionDataTask? {
            guard let url = URL(string: "https://world.openfoodfacts.org/api/v3/product/\(code).json") else {
                done([], "Invalid barcode."); return nil
            }
            var req = URLRequest(url: url)
            req.setValue("LIFT-iOS-App/1.0 (support@liftapp.com)", forHTTPHeaderField: "User-Agent")
            let task = URLSession.shared.dataTask(with: req) { data, _, error in
                if let e = error as NSError?, e.code == NSURLErrorCancelled { return }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async { done([], "Network error.") }; return
                }
                
                let statusStr = json["status"] as? String
                let statusInt = json["status"] as? Int
                let hasProduct = json["product"] != nil
                
                if (statusInt == 1 || statusStr == "success" || statusStr == "known" || hasProduct),
                   let product = parseProduct(from: json, code: code) {
                    DispatchQueue.main.async { done([product], nil) }
                } else if let alt = fallback {
                    // Product not found with EAN-13 — retry with UPC-A (no leading zero)
                    _ = fetch(alt, fallback: nil, done: done)
                } else {
                    DispatchQueue.main.async { done([], nil) }
                }
            }
            task.resume()
            return task
        }
        
        return fetch(cleaned, fallback: alternate, done: completion)
    }
}

// MARK: - Photo Library Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.selectedImage = image }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - AVFoundation Camera Capture View
// Uses AVCaptureSession directly (same as BarcodeScannerView) to guarantee the real camera opens.

struct CameraPhotoCaptureView: View {
    @Environment(\.presentationMode) private var presentationMode
    var onImageCaptured: (UIImage) -> Void
    @State private var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                switch cameraPermission {
                case .authorized:
                    CameraPhotoRepresentable { image in
                        onImageCaptured(image)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .ignoresSafeArea()
                case .notDetermined:
                    Color.black.ignoresSafeArea().onAppear {
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            DispatchQueue.main.async {
                                cameraPermission = granted ? .authorized : .denied
                            }
                        }
                    }
                default:
                    VStack(spacing: 20) {
                        Image(systemName: "camera.badge.exclamationmark").font(.system(size: 60)).foregroundColor(.gray)
                        Text("Camera Access Required").font(.headline).foregroundColor(.white)
                        Text("Enable camera access in iOS Settings to take food photos.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 30)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }.foregroundColor(Theme.neonCyan)
                    }
                }
            }
            .navigationTitle("Take Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.gray)
                }
            }
        }
    }
}

struct CameraPhotoRepresentable: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void
    func makeUIViewController(context: Context) -> CameraPhotoViewController {
        let vc = CameraPhotoViewController()
        vc.onImageCaptured = onImageCaptured
        return vc
    }
    func updateUIViewController(_ uiViewController: CameraPhotoViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject {}
}

class CameraPhotoViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onImageCaptured: ((UIImage) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        addShutterButton()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async { self.captureSession?.startRunning() }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true { captureSession?.stopRunning() }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    private func setupSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        self.photoOutput = output
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preview, at: 0)
        self.previewLayer = preview
        self.captureSession = session
        DispatchQueue.global(qos: .background).async { session.startRunning() }
    }
    private func addShutterButton() {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 36
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor
        button.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            button.widthAnchor.constraint(equalToConstant: 72),
            button.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { self.onImageCaptured?(image) }
    }
}

// MARK: - Edit Food Sheet View

struct EditFoodSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    let initialEntry: FoodLogEntry
    let onSave: (FoodLogEntry) -> Void
    
    @State private var name: String
    @State private var caloriesString: String
    @State private var proteinString: String
    @State private var carbsString: String
    @State private var fatString: String
    @State private var mealType: String
    @State private var date: Date
    
    init(initialEntry: FoodLogEntry, onSave: @escaping (FoodLogEntry) -> Void) {
        self.initialEntry = initialEntry
        self.onSave = onSave
        
        _name = State(initialValue: initialEntry.name)
        _caloriesString = State(initialValue: "\(initialEntry.calories)")
        _proteinString = State(initialValue: String(format: "%.1f", initialEntry.protein))
        _carbsString = State(initialValue: String(format: "%.1f", initialEntry.carbs))
        _fatString = State(initialValue: String(format: "%.1f", initialEntry.fat))
        _mealType = State(initialValue: initialEntry.mealType)
        _date = State(initialValue: initialEntry.date)
    }
    
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(initialEntry.id == nil ? "Edit Food Details" : "Edit Logged Food")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FOOD NAME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            TextField("", text: $name, prompt: Text("Food Name").foregroundColor(.white.opacity(0.4)))
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .submitLabel(.done)
                                .onSubmit { hideKeyboard() }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CALORIES")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("", text: $caloriesString, prompt: Text("kcal").foregroundColor(.white.opacity(0.4)))
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    .keyboardDoneButton()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PROTEIN (G)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("", text: $proteinString, prompt: Text("grams").foregroundColor(.white.opacity(0.4)))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    .keyboardDoneButton()
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CARBS (G)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("", text: $carbsString, prompt: Text("grams").foregroundColor(.white.opacity(0.4)))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    .keyboardDoneButton()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FAT (G)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("", text: $fatString, prompt: Text("grams").foregroundColor(.white.opacity(0.4)))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                    .keyboardDoneButton()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MEAL TYPE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                            
                            HStack {
                                ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { type in
                                    Button(action: { mealType = type }) {
                                        Text(type)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(mealType == type ? .black : .white)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(mealType == type ? Theme.neonCyan : Color.white.opacity(0.05))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                            .foregroundColor(.white)
                            .colorScheme(.dark)
                            .padding(.vertical, 8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    hideKeyboard()
                    let cleanCalories = caloriesString.replacingOccurrences(of: ",", with: ".")
                    let cleanProtein = proteinString.replacingOccurrences(of: ",", with: ".")
                    let cleanCarbs = carbsString.replacingOccurrences(of: ",", with: ".")
                    let cleanFat = fatString.replacingOccurrences(of: ",", with: ".")
                    
                    let updatedEntry = FoodLogEntry(
                        id: initialEntry.id,
                        name: name,
                        calories: Int(Double(cleanCalories) ?? 0),
                        protein: Double(cleanProtein) ?? 0.0,
                        carbs: Double(cleanCarbs) ?? 0.0,
                        fat: Double(cleanFat) ?? 0.0,
                        mealType: mealType,
                        date: date
                    )
                    onSave(updatedEntry)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("SAVE CHANGES")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryGradient)
                        .cornerRadius(10)
                }
                .disabled(name.isEmpty || caloriesString.isEmpty)
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.gray)
                .font(.footnote)
            }
            .padding(24)
        }
    }
}

// MARK: - Food Row View

struct FoodRow: View {
    let meal: FoodLogEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("P: \(Int(meal.protein))g")
                    Text("C: \(Int(meal.carbs))g")
                    Text("F: \(Int(meal.fat))g")
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(meal.calories) kcal")
                .font(.subheadline)
                .fontWeight(.black)
                .foregroundColor(Theme.neonCyan)
        }
        .padding()
        .background(Color.black.opacity(0.15))
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Food", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Food", systemImage: "trash")
            }
        }
    }
}

// MARK: - Serving Helpers

private func getServingDescription(for product: OpenFoodFactsClient.Product) -> String? {
    if let household = product.householdServing, !household.isEmpty {
        if let size = product.servingSize {
            let unit = product.servingSizeUnit ?? "g"
            let cleanUnit = unit.lowercased() == "grm" ? "g" : unit
            return "Serving: \(household) (\(Int(size))\(cleanUnit))"
        } else {
            return "Serving: \(household)"
        }
    } else if let size = product.servingSize {
        let unit = product.servingSizeUnit ?? "g"
        let cleanUnit = unit.lowercased() == "grm" ? "g" : unit
        return "Serving: \(Int(size))\(cleanUnit)"
    }
    return nil
}

// MARK: - Bouncing sparkles micro-animation view

struct BouncingAIView: View {
    @State private var isBouncing = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.neonPurple)
                .offset(y: isBouncing ? -12 : 12)
                .scaleEffect(isBouncing ? 1.15 : 0.85)
                .animation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                    value: isBouncing
                )
                .onAppear {
                    isBouncing = true
                }
            
            Text("LIFT AI is analyzing your meal...")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .tracking(0.5)
            
            Text("This might take a few seconds.")
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
    }
}

# LIFT 🏋️‍♂️

**LIFT** is a premium, modern iOS workout tracking application styled with sleek dark-mode aesthetics, custom glassmorphic cards, and dynamic visual indicators. It features full authentication, database synchronization, and automated muscle recovery telemetry.

---

## 🚀 Key Features

### 🔋 Muscle Battery & Power Grid (Dashboard Telemetry)
* **Real-time Fatigue Engine**: Automatically tracks the state of **16 individual muscle groups** based on your workout history.
* **Volume-based Depletion**: Each set performed for a targeted muscle group drains its battery level by **15%**.
* **Linear Recharging**: Muscle batteries recharge linearly at a rate of **100% over 48 hours** (approximately 2.083% charge per hour) from the logged workout timestamp.
* **Smart UI Display**: Displays a grid of custom color-coded batteries. By default, it shows only the **top 4 most depleted batteries** to maintain dashboard cleanliness, with an inline spring-animated toggle to expand and view all 16 muscle batteries.

### 📝 Flexible Active Workout Logger
* **Non-Linear Logging**: Lists all selected exercises on a single scrollable page so you can log sets, reps, and weights in **any order** based on equipment availability.
* **Inline Ratings**: Rates exercise difficulty (1-5 stars) and RPE values inline on the card without modal dialog interruptions.
* **Adaptive Set Controls**: Independently add or remove sets on an exercise-by-exercise basis.

### 🔥 Gym Partner Roasts
* **AI-style Accountability**: Counts the days since your last logged workout. If you slack off, a red-tinted dashboard card displays a random roast selected from a bank of **80+ savage quotes** to get you back in the gym.

### 📊 Category Balance Scorecard
* **Audit Your Splits**: A balance dashboard in your history tab that measures training frequency across your workout categories, showing exactly how many sessions a split is **BEHIND** compared to your most-trained category.

### 🔒 Secure Backend Integration
* **Firebase Auth**: User sign-up, sign-in, and profile display-name editor.
* **Cloud Firestore**: Real-time syncing of workout categories, custom exercises, and session logs.

---

## 🛠️ Technology Stack
* **Frontend**: SwiftUI (iOS 15+)
* **Database & Auth**: Firebase (Auth & Cloud Firestore SDKs)
* **Design Pattern**: MVVM-based service architecture

---

## 📦 Getting Started

### Prerequisites
* macOS running Xcode 14+
* iOS 15.0+ Simulator or physical device
* A Firebase Project with Auth and Firestore enabled

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/niharcv/LIFT.git
   cd LIFT
   ```
2. Open `LIFT.xcodeproj` in Xcode.
3. Download your `GoogleService-Info.plist` from your Firebase Console and add it to the root of the Xcode project.
4. Let Xcode resolve the Swift Package Manager (SPM) dependencies for Firebase.
5. Select a Simulator target and press `Cmd + R` to build and run.

# Comprehensive Habit Tracker & Analytics

A feature-rich iOS application built with **SwiftUI** designed to help users build positive habits, break negative ones, track daily moods, and gain actionable personal insights.

## Features

*   **Habit Tracking & Management**
    *   Create custom habits or use quick templates (e.g., Read, Drink Water, Workout).
    *   Set frequencies, daily targets, importance weights, and time-of-day preferences.
    *   Checklist support with daily subtasks.
    *   Interactive UI to mark habits as complete, with haptic feedback and dynamic progress indicators.
*   **Analytics & Insights Dashboard**
    *   90-day activity heatmap calendar.
    *   AI-driven insights and actionable recommendations based on habit adherence.
    *   KPI grid highlighting at-risk habits, 7-day consistency, and active streaks.
*   **Pomodoro Focus Timer**
    *   Built-in 25-minute focus timer linked directly to your habits.
*   **Habit Destroyer (Bad Habit Tracking)**
    *   Track days clean from negative habits.
    *   Log relapses and monitor your highest clean streaks to break the cycle.
*   **Mindfulness & Mood Lab**
    *   Log daily moods with contextual notes and weather data.
    *   Built-in mindfulness lockout timer to prevent spamming and encourage genuine reflection.
*   **Secret Journal Archive**
    *   Keep track of daily notes and journal entries.
    *   Includes automated sentiment analysis scoring.
*   **Data Export**
    *   Export raw habit analytics to CSV for external tools like Tableau or PowerBI.

## Architecture & Tech Stack

*   **Framework**: SwiftUI
*   **Language**: Swift
*   **Design Pattern**: MVVM (Model-View-ViewModel) utilizing `@ObservedObject` and `@State` 
*   **Components**: Native iOS components, SF Symbols, custom interactive heatmaps, and dynamic charts.

## Requirements

*   iOS 16.0+
*   Xcode 14.0+
*   Swift 5.0+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/vedjr02/Your-Repo-Name.git
2. Open the .xcodeproj or .xcworkspace file in Xcode.
3. Select your target device or simulator.
4. Build and run the project (Cmd + R).

## Usage
- Adding a Habit: Tap the '+' button on the main dashboard to create a new habit. Choose from templates or customize the color, frequency, and target.
- Logging a Mood: Navigate to the Mood Lab tab to log your current feelings. (Note: A 1-hour cooldown is applied between entries to encourage mindfulness).
- Focus Mode: Tap into any habit's detail view to start a Pomodoro session.
- Breaking Bad Habits: Use the 'Destroyer' tab to set up targets you want to quit and track your clean streak.

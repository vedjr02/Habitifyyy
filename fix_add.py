import re

path = "/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/ContentView.swift"
with open(path, "r") as f:
    text = f.read()

pattern = re.compile(r'func addHabit\(.*?\)\s*\{.*?habits\.append\(newHabit\)\n\s*if reminderTime != nil \{\n\s*NotificationManager\.shared\.scheduleNotification\(for: newHabit\)\n\s*\}\n\s*\}', re.DOTALL)

replacement = """func addHabit(name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency, timeOfDay: TimeOfDay, reminderTime: Date?) {
        let newHabit = Habit(
            name: name,
            category: category,
            themeColorHex: themeColorHex,
            frequency: frequency,
            timeOfDay: timeOfDay,
            reminderTime: reminderTime
        )
        habits.append(newHabit)
        if reminderTime != nil {
            NotificationManager.shared.scheduleNotification(for: newHabit)
        }
    }"""

text = pattern.sub(replacement, text)
with open(path, "w") as f:
    f.write(text)

print("done")

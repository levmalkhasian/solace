# App Notes -- What Everything Means

# FocusMode.swift
- private -- only visible in this file/type
- static -- belongs to the type, not an instance
- let -- constant

static func save(_ modes: [FocusMode])
- takes in array of FocusMode, converts to JSON
Example:

[
  {
    "id": "UUID",
    "name": "Work",
    "selection": {...}
  }
]

- saves to userDefaults

static func load() -> [FocusMode]
- loads/reads stored data in userDefaults
    - if none, return []
    - if the guard is true, the code after will execute. 

# FocusSessionManager.swift

@MainActor -- class is supposed to run on main thread.
final -- can't be inherited from. Thats it.
@ObservableObject -- class can be observed by SwiftUI views.
    - swiftUI refereshed the view when published properties change.
@Published -- when this property changes, notify any observing views.
@AppStorage/@UserDefaults -- stores value in UserDefaults automatically
    - values persist even when app closes

func refreshToday(now: Date = Date())
- now: Date means the type is Date object.
- let startOfDay = Calendar.current.startOfDay(for: now).timeIntervalSince1970
    - this calculates the start of the day

- weak self -- research



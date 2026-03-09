###  Todo List for Solace

1. Add email + pass auth and Google auth.
    - handle all edge cases. forgot password, not valid account, etc...
    - think about account use case. do they have to create and use an account in order to use the app? Probably.
    
    Steps:
    Practical stack choices:

      1. Supabase Auth (simple for SwiftUI, great DX)
      2. Firebase Auth (very common, good docs)
      3. Clerk/Auth0 (more enterprise, more setup)

      What to build in your app:

      1. AuthService protocol (signIn, signUp, signOut, currentUser, restoreSession)
      2. AuthViewModel as @StateObject in app root
      3. SessionStore persisted securely (Keychain, not UserDefaults for tokens)
      4. SettingsView button becomes:

      - Signed out: Login / Create Account
      - Signed in: show email + Sign Out

      If you add Google later:

      1. Keep same AuthService and add signInWithGoogle()
      2. For App Store: if you offer Google/social login, verify current Apple guideline requirements
         around also offering Sign in with Apple.

2. AlarmKit/Alarm functionality (IMPORTANT -- need for MVP on app store)
    - think about ios bottlenecks. ios26 needed for alarmkit, oldest phone that supports it is iPhone SE. 

3. Fix Stats logic, show days/weeks/months filter like Brick app.    !!!
    - today's focus is incorrect it seems

4. Later ideas --> Live activites, UI upgrades, branding/logos
    - show how much you saved overall with Solce, also total time for all users. Get data from DB and sql SELECT hours from * or something like that.
    - Ability to start focus without NFC? But not end of course.
    - Implement sensitive content, strict mode, app installs. 
    - Leaderboards with friends
        - lifetime time saved, saved this week, leaders get xp and bragging rights
    - Schedules -- auto block apps from a selected time slot.

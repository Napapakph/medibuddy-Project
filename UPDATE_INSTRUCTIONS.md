# Resolution for Auto-Login Loop

I have fixed the issue where the app would automatically log you back in even after signing out.

## Cause

The "Sign Out" button was only clearing the Supabase session but leaving the Custom API token on your device.

## Fix Applied

Updated `lib/services/authen_login.dart` to use `AuthManager.service.logout()`, which clears the token from secure storage.

## Action Required

1. Open the app (it may auto-login one last time).
2. Go to the menu/drawer.
3. Press **Sign Out** again.
4. This time, the token will be cleared, and you will return to the Login Screen correctly.

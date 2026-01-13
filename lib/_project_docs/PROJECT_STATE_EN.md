# Project State

## A) Project Overview
- App purpose: Manage user profiles, add/search medicines (OCR supported), set medication reminders, and view intake history.
- Major modules under lib/:
  - Auth/Onboarding: `lib/main.dart`, `lib/API/*`, `lib/pages/*`
  - Profile & Home: `lib/Home/pages/home.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/buddy.dart`
  - Medicine management: `lib/Home/pages/add_medicine/*`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`
  - Reminders: `lib/Home/pages/set_remind/*`
  - OCR/Camera: `lib/OCR/*`
  - Shared models/widgets: `lib/Model/*`, `lib/widgets/*`
- External services/packages used: `supabase_flutter`, `flutter_dotenv`, `http`, `dio`, `camera`, `image_picker`, `image_cropper`, `google_mlkit_text_recognition`, `flutter_otp_text_field`, `intl`

## B) File & Module Dependency Map (Tree + Graph)
### B1) File tree (Dart files only)
```text
lib/
|-- API/
|   |-- auth_gate.dart
|   |-- auth_session.dart
|   \-- authen_login.dart
|-- Home/
|   \-- pages/
|       |-- add_medicine/
|       |   |-- add_medicine.dart
|       |   |-- createName_medicine.dart
|       |   |-- detail_medicine.dart
|       |   |-- find_medicine.dart
|       |   |-- list_medicine.dart
|       |   |-- request_medicine.dart
|       |   \-- summary_medicine.dart
|       |-- buddy.dart
|       |-- history.dart
|       |-- home.dart
|       |-- library_profile.dart
|       |-- note_medicine.dart
|       |-- profile_screen.dart
|       |-- select_profile.dart
|       \-- set_remind/
|           |-- remind_list_screen.dart
|           |-- setFuctionRemind.dart
|           \-- setRemind_screen.dart
|-- Model/
|   |-- medicine_model.dart
|   \-- profile_model.dart
|-- OCR/
|   |-- camera_ocr.dart
|   |-- ocr_camera_frame.dart
|   |-- ocr_image_cropper.dart
|   |-- ocr_result_page.dart
|   \-- ocr_text_service.dart
|-- main.dart
|-- pages/
|   |-- forget_password.dart
|   |-- login.dart
|   |-- otp.dart
|   \-- signup.dart
|-- services/
|   |-- medicine_api.dart
|   |-- mock_auth_service.dart
|   \-- profile_api.dart
\-- widgets/
    |-- app_drawer.dart
    |-- login_button.dart
    |-- medicine_step_timeline.dart
    \-- profile_widget.dart
```

### B2) Dependency graph (key files)
#### lib/main.dart
- Imports (internal): `lib/API/auth_gate.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/history.dart`, `lib/Home/pages/home.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`, `lib/OCR/camera_ocr.dart`, `lib/pages/forget_password.dart`, `lib/pages/login.dart`, `lib/pages/signup.dart`
- Main classes/functions: `main()`, `MyApp`, `defaultPage()`, `kDisableAuthGate`
- Used by: Flutter entrypoint
- Calls/uses next: `dotenv.load`, `Supabase.initialize`, `initializeDateFormatting`, `Intl.defaultLocale`, `MaterialApp.onGenerateRoute` for routes `/login`, `/signup`, `/profile`, `/select_profile`, `/home`, `/forget_password`, `/library_profile`, `/list_medicine`, `/history`, `/camera_ocr`

#### lib/API/auth_gate.dart
- Imports (internal): `lib/pages/login.dart`, `lib/Home/pages/profile_screen.dart`
- Main classes/functions: `AuthGate`
- Used by: `lib/main.dart`
- Calls/uses next: Reads `Supabase.instance.client.auth.currentSession` and returns `ProfileScreen` or `LoginScreen`

#### lib/API/auth_session.dart
- Imports (internal): none
- Main classes/functions: `AuthSession`
- Used by: not imported elsewhere
- Calls/uses next: Reads `Supabase.instance.client.auth.currentSession`

#### lib/API/authen_login.dart
- Imports (internal): none
- Main classes/functions: `AuthenSignUpEmail`, `LoginWithGoogle`, `AuthenLoginEmail`, `AuthenLogout`, top-level `supabase`
- Used by: `lib/pages/login.dart`, `lib/pages/signup.dart`, `lib/widgets/app_drawer.dart`
- Calls/uses next: `supabase.auth.signUp`, `supabase.auth.signInWithPassword`, `supabase.auth.signInWithOAuth`, `supabase.auth.signOut`

#### lib/pages/login.dart
- Imports (internal): `lib/pages/signup.dart`, `lib/widgets/login_button.dart`, `lib/API/authen_login.dart`, `lib/pages/forget_password.dart`, `lib/Home/pages/profile_screen.dart`
- Main classes/functions: `LoginScreen`, `_LoginScreenState`, `_handleLogin`, `_handleGoogleLogin`, `forgetPassword`
- Used by: `lib/main.dart`, `lib/API/auth_gate.dart`, `lib/pages/forget_password.dart`, `lib/pages/otp.dart`, `lib/widgets/app_drawer.dart`
- Calls/uses next: `AuthenLoginEmail.signInWithEmail`, `LoginWithGoogle.signInWithGoogle`, `Supabase.auth.onAuthStateChange`, `Supabase.auth.resetPasswordForEmail`, navigation to `SignupScreen`, `ProfileScreen`, `ForgetPassword`

#### lib/pages/signup.dart
- Imports (internal): `lib/pages/otp.dart`, `lib/API/authen_login.dart`
- Main classes/functions: `SignupScreen`, `_SignupScreenState`, `_handleSignup`, `validatePassword`
- Used by: `lib/main.dart`, `lib/pages/login.dart`
- Calls/uses next: `AuthenSignUpEmail.signUpWithEmail`, navigation to `OTPScreen`

#### lib/pages/otp.dart
- Imports (internal): `lib/pages/login.dart`
- Main classes/functions: `OTPScreen`, `_OTPScreenState`, `confirmOTP`, `_parseJwt`
- Used by: `lib/pages/signup.dart`
- Calls/uses next: `http.post` to Supabase verify endpoint (uses `supabaseAnonKey` variable), `http.post` to `/api/mobile/v1/auth/sync-user`, `Supabase.auth.resend`, navigation to `LoginScreen`

#### lib/pages/forget_password.dart
- Imports (internal): `lib/widgets/login_button.dart`, `lib/pages/login.dart`
- Main classes/functions: `ForgetPassword`, `_ForgetPassword`, `_handleResetPassword`, `validatePassword`
- Used by: `lib/main.dart`, `lib/pages/login.dart`
- Calls/uses next: `Supabase.auth.updateUser`, `Supabase.auth.signOut`, `pushAndRemoveUntil` to `LoginScreen`

#### lib/Home/pages/profile_screen.dart
- Imports (internal): `lib/Home/pages/library_profile.dart`, `lib/Model/profile_model.dart`, `lib/services/profile_api.dart`
- Main classes/functions: `ProfileScreen`, `_ProfileScreenState`, `_onCameraTap`, `_goNext`
- Used by: `lib/main.dart`, `lib/API/auth_gate.dart`, `lib/pages/login.dart`
- Calls/uses next: `ProfileApi.createProfile`, `Supabase.auth.currentSession`, `ImagePicker`, navigation to `LibraryProfile`

#### lib/Home/pages/library_profile.dart
- Imports (internal): `lib/Home/pages/buddy.dart`, `lib/Model/profile_model.dart`, `lib/services/profile_api.dart`, `lib/widgets/profile_widget.dart`
- Main classes/functions: `LibraryProfile`, `_LibraryProfileState`, `_loadProfiles`, `_editProfile`, `_confirmDeleteProfile`, `_deleteProfile`, `_addProfile`, `create_profile`, `update_profile`
- Used by: `lib/main.dart`, `lib/Home/pages/profile_screen.dart`
- Calls/uses next: `ProfileApi.fetchProfiles`, `ProfileApi.createProfile`, `ProfileApi.updateProfile`, `ProfileApi.deleteProfile`, `ImagePicker`, `showDialog`, navigation to `MyBuddy`

#### lib/Home/pages/select_profile.dart
- Imports (internal): `lib/Home/pages/home.dart`, `lib/Model/profile_model.dart`, `lib/services/profile_api.dart`, `lib/widgets/app_drawer.dart`
- Main classes/functions: `SelectProfile`, `_SelectProfileState`, `_loadProfiles`
- Used by: `lib/main.dart`, `lib/Home/pages/home.dart`, `lib/Home/pages/buddy.dart`
- Calls/uses next: `ProfileApi.fetchProfiles`, `Supabase.auth.currentSession`, navigation to `/home` via `Navigator.pushNamed`

#### lib/Home/pages/home.dart
- Imports (internal): `lib/widgets/app_drawer.dart`, `lib/Model/profile_model.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/select_profile.dart`
- Main classes/functions: `Home`, `_Home`, `_MedicineReminder`
- Used by: `lib/main.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`
- Calls/uses next: navigation to `/list_medicine` via `Navigator.pushNamed`, `pushReplacement` to `SelectProfile` and `Home`

#### lib/Home/pages/buddy.dart
- Imports (internal): `lib/Home/pages/select_profile.dart`
- Main classes/functions: `MyBuddy`, `_MyBuddyState`
- Used by: `lib/Home/pages/library_profile.dart`
- Calls/uses next: navigation to `SelectProfile`

#### lib/Home/pages/history.dart
- Imports (internal): none
- Main classes/functions: `HistoryPage`, `_HistoryPageState`, `MedicineHistoryItem`, `MedicineTakeStatus`, `_DateField`, `_HistoryRow`
- Used by: `lib/main.dart`
- Calls/uses next: `showDatePicker`, `Navigator.pop`, TODO for history API

#### lib/Home/pages/note_medicine.dart
- Imports (internal): none
- Main classes/functions: none (empty file)
- Used by: none

#### lib/Home/pages/add_medicine/createName_medicine.dart
- Imports (internal): `lib/Home/pages/add_medicine/find_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/widgets/medicine_step_timeline.dart`
- Main classes/functions: `CreateNameMedicinePage`, `_CreateNameMedicinePageState`, `_ImageCircleButton`
- Used by: `lib/Home/pages/add_medicine/list_medicine.dart`
- Calls/uses next: builds `MedicineDraft`, uses `ImagePicker`, navigates to `FindMedicinePage`, returns `MedicineItem`

#### lib/Home/pages/add_medicine/find_medicine.dart
- Imports (internal): `lib/Home/pages/add_medicine/add_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/OCR/camera_ocr.dart`, `lib/widgets/medicine_step_timeline.dart`
- Main classes/functions: `FindMedicinePage`, `_FindMedicinePageState`
- Used by: `lib/Home/pages/add_medicine/createName_medicine.dart`
- Calls/uses next: navigation to `AddMedicinePage`, navigation to `CameraOcrPage`, returns `MedicineItem`

#### lib/Home/pages/add_medicine/add_medicine.dart
- Imports (internal): `lib/Home/pages/add_medicine/request_medicine.dart`, `lib/Home/pages/add_medicine/summary_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`, `lib/widgets/medicine_step_timeline.dart`
- Main classes/functions: `AddMedicinePage`, `_AddMedicinePageState`
- Used by: `lib/Home/pages/add_medicine/find_medicine.dart`
- Calls/uses next: `MedicineApi.fetchMedicineCatalog`, result filtering, navigation to `SummaryMedicinePage`, `RequestMedicinePage` when no results

#### lib/Home/pages/add_medicine/summary_medicine.dart
- Imports (internal): `lib/Home/pages/add_medicine/detail_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`, `lib/widgets/medicine_step_timeline.dart`
- Main classes/functions: `SummaryMedicinePage`, `_SummaryMedicinePageState`
- Used by: `lib/Home/pages/add_medicine/add_medicine.dart`
- Calls/uses next: `MedicineApi.addMedicineToProfile`, `showMedicineDetailDialog`, returns `MedicineItem`

#### lib/Home/pages/add_medicine/detail_medicine.dart
- Imports (internal): `lib/Model/medicine_model.dart`
- Main classes/functions: `showMedicineDetailDialog`, `_MedicineDetailContent`
- Used by: `lib/Home/pages/add_medicine/summary_medicine.dart`
- Calls/uses next: `showDialog` (currently short-circuited by early return)

#### lib/Home/pages/add_medicine/request_medicine.dart
- Imports (internal): none
- Main classes/functions: `RequestMedicinePage`, `_RequestMedicinePageState`, `_ImageCircleButton`
- Used by: `lib/Home/pages/add_medicine/add_medicine.dart`
- Calls/uses next: `ImagePicker`, `Navigator.pop` after submit (mock)

#### lib/Home/pages/add_medicine/list_medicine.dart
- Imports (internal): `lib/Home/pages/add_medicine/createName_medicine.dart`, `lib/Home/pages/home.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`, `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`, `lib/widgets/app_drawer.dart`
- Main classes/functions: `ListMedicinePage`, `_ListMedicinePageState`
- Used by: `lib/main.dart`, `lib/Home/pages/home.dart`
- Calls/uses next: `MedicineApi.fetchProfileMedicineList`, navigation to `CreateNameMedicinePage`, `RemindListScreen`, `Home`, uses `showDialog`

#### lib/Home/pages/set_remind/setFuctionRemind.dart
- Imports (internal): `lib/Model/medicine_model.dart`
- Main classes/functions: `ReminderDose`, `ReminderPlan`, `MealTimingIcon`, UI builders `type_frequency`, `detail_time`, `summary_rejimen`, helpers `buildMedicineImage`, `formatTime`
- Used by: `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`
- Calls/uses next: consumes `MedicineItem` to build UI

#### lib/Home/pages/set_remind/setRemind_screen.dart
- Imports (internal): `lib/Home/pages/set_remind/setFuctionRemind.dart`, `lib/Model/medicine_model.dart`
- Main classes/functions: `SetRemindScreen`, `_SetRemindScreenState`, `_CircleNavButton`
- Used by: `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`
- Calls/uses next: builds/edits `ReminderPlan` and returns via `Navigator.pop`

#### lib/Home/pages/set_remind/remind_list_screen.dart
- Imports (internal): `lib/Home/pages/set_remind/setFuctionRemind.dart`, `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Model/medicine_model.dart`
- Main classes/functions: `RemindListScreen`, `_RemindListScreenState`, `_ReminderPlanStore`
- Used by: `lib/Home/pages/add_medicine/list_medicine.dart`
- Calls/uses next: navigation to `SetRemindScreen`, in-memory plan store

#### lib/Model/medicine_model.dart
- Imports (internal): none
- Main classes/functions: `MedicineCatalogItem`, `MedicineDraft`, `MedicineItem`, `MedicineCatalogItem.fromJson`, `MedicineItem.mediId`
- Used by: add_medicine flow, OCR, reminders, `lib/services/medicine_api.dart`
- Calls/uses next: shared data contract for medicine entities

#### lib/Model/profile_model.dart
- Imports (internal): none
- Main classes/functions: `ProfileModel`
- Used by: `lib/Home/pages/home.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`
- Calls/uses next: shared profile model

#### lib/services/medicine_api.dart
- Imports (internal): `lib/Model/medicine_model.dart`
- Main classes/functions: `MedicineApi`, `fetchMedicineCatalog`, `fetchProfileMedicineList`, `addMedicineToProfile`
- Used by: `lib/Home/pages/add_medicine/add_medicine.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/add_medicine/summary_medicine.dart`
- Calls/uses next: reads `API_BASE_URL` from `.env`, uses `Supabase.instance.client` for access token, calls backend HTTP endpoints

#### lib/services/profile_api.dart
- Imports (internal): none
- Main classes/functions: `ProfileApi`, `createProfile`, `updateProfile`, `fetchProfiles`, `deleteProfile`
- Used by: `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`
- Calls/uses next: reads `API_BASE_URL` from `.env`, uses `Dio` with multipart/form-data

#### lib/services/mock_auth_service.dart
- Imports (internal): none
- Main classes/functions: `MockAuthService`
- Used by: none (commented out in `lib/pages/login.dart`)

#### lib/OCR/camera_ocr.dart
- Imports (internal): `lib/OCR/ocr_camera_frame.dart`, `lib/OCR/ocr_image_cropper.dart`, `lib/OCR/ocr_result_page.dart`, `lib/OCR/ocr_text_service.dart`
- Main classes/functions: `CameraOcrPage`, `_CameraOcrPageState`
- Used by: `lib/Home/pages/add_medicine/find_medicine.dart`, `lib/main.dart`
- Calls/uses next: `CameraController`, `ImagePicker`, `OcrImageCropper.crop`, `OcrTextService.recognize`, navigation to `OcrResultPage`

#### lib/OCR/ocr_result_page.dart
- Imports (internal): `lib/widgets/medicine_step_timeline.dart`, `lib/Model/medicine_model.dart`
- Main classes/functions: `OcrSuccessPage`, `OcrResultPage`, `_CircleIconButton`
- Used by: `lib/OCR/camera_ocr.dart`
- Calls/uses next: `Navigator.pushReplacement` to `OcrResultPage`, `Navigator.pop` returning OCR text

#### lib/OCR/ocr_text_service.dart
- Imports (internal): none
- Main classes/functions: `OcrTextService`
- Used by: `lib/OCR/camera_ocr.dart`
- Calls/uses next: ML Kit `TextRecognizer.processImage`

#### lib/OCR/ocr_image_cropper.dart
- Imports (internal): none
- Main classes/functions: `OcrImageCropper`
- Used by: `lib/OCR/camera_ocr.dart`
- Calls/uses next: `ImageCropper.cropImage`

#### lib/OCR/ocr_camera_frame.dart
- Imports (internal): none
- Main classes/functions: `OcrCameraFrame`
- Used by: `lib/OCR/camera_ocr.dart`
- Calls/uses next: UI widget for camera frame

#### lib/widgets/app_drawer.dart
- Imports (internal): `lib/API/authen_login.dart`, `lib/pages/login.dart`
- Main classes/functions: `AppDrawer`
- Used by: `lib/Home/pages/home.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`
- Calls/uses next: `AuthenLogout.signOut`, `Navigator.pushReplacementNamed` to `/home`, `/list_medicine`, `/history`, `/library_profile`, `/select_profile`, and `Navigator.pushAndRemoveUntil` to `LoginScreen`

#### lib/widgets/login_button.dart
- Imports (internal): none
- Main classes/functions: `LoginButton`, `SignupButton`, `resetPassword`
- Used by: `lib/pages/login.dart`, `lib/pages/forget_password.dart`
- Calls/uses next: UI-only widgets

#### lib/widgets/medicine_step_timeline.dart
- Imports (internal): none
- Main classes/functions: `MedicineStepTimeline`
- Used by: add_medicine flow and `lib/OCR/ocr_result_page.dart`
- Calls/uses next: UI-only widget

#### lib/widgets/profile_widget.dart
- Imports (internal): none
- Main classes/functions: `ProfileWidget`
- Used by: `lib/Home/pages/library_profile.dart`
- Calls/uses next: UI-only widget

## C) Auth & Onboarding Flow (End-to-end)
1) `main()` in `lib/main.dart` loads `.env` via `dotenv.load`, initializes `Supabase.initialize`, sets locale, and runs `MyApp`
2) `defaultPage()` chooses the entry screen based on `kDisableAuthGate` (currently `true` -> `LoginScreen`; if `false` -> `AuthGate`)
3) `AuthGate` (`lib/API/auth_gate.dart`) checks `supabase.auth.currentSession` and returns `ProfileScreen` or `LoginScreen`
4) Login: `LoginScreen._handleLogin` calls `AuthenLoginEmail.signInWithEmail` then navigates to `ProfileScreen` (and `auth.onAuthStateChange` also pushes to `ProfileScreen` on `signedIn`)
5) Sign Up: `SignupScreen._handleSignup` calls `AuthenSignUpEmail.signUpWithEmail`; on success (or already registered) -> `Navigator.push` to `OTPScreen`
6) OTP: `OTPScreen.confirmOTP` posts to Supabase `/auth/v1/verify` using `supabaseAnonKey` -> receives `access_token` -> posts to `/api/mobile/v1/auth/sync-user` -> `Navigator.pushReplacement` to `LoginScreen`
7) Google OAuth: `LoginWithGoogle.signInWithOAuth` with a custom-scheme redirect URI
8) Password recovery: `LoginScreen.forgetPassword` calls `supabase.auth.resetPasswordForEmail`; `AuthChangeEvent.passwordRecovery` triggers `ForgetPassword`; `ForgetPassword` calls `supabase.auth.updateUser` -> `signOut` -> `LoginScreen`
9) Post-login: `ProfileScreen` calls `ProfileApi.createProfile` then navigates to `LibraryProfile`; `SelectProfile` passes the selected profile to `Home`

## D) Navigation Map
### lib/pages/login.dart
- `_handleLogin` -> `Navigator.push(ProfileScreen)`; condition: valid form + login success; side effects: setState `_isLoading`
- `auth.onAuthStateChange` -> `Navigator.pushReplacement(ForgetPassword)` on `passwordRecovery`; `Navigator.pushReplacement(ProfileScreen)` on `signedIn`
- Sign up button -> `Navigator.push(SignupScreen)`
- `forgetPassword()` dialog -> `Navigator.pop` to close dialog

### lib/pages/signup.dart
- `_handleSignup` -> `Navigator.push(OTPScreen)` on success or already-registered error
- Back button -> `Navigator.pop`
- `Navigator.pop` inside dialog/alert (close dialog)

### lib/pages/otp.dart
- `confirmOTP` success -> `Navigator.pushReplacement(LoginScreen)`
- AppBar back -> `Navigator.pop`

### lib/pages/forget_password.dart
- `_handleResetPassword` success -> `Navigator.pushAndRemoveUntil(LoginScreen, (_) => false)`

### lib/widgets/app_drawer.dart
- `_go` -> `Navigator.pop` (close drawer) then `Navigator.pushReplacementNamed` to `/home`, `/list_medicine`, `/history`, `/library_profile`, `/select_profile`
- `logout` -> `Navigator.pushAndRemoveUntil(LoginScreen, (_) => false)`

### lib/Home/pages/profile_screen.dart
- `_goNext` -> `Navigator.pushReplacement(LibraryProfile)` after profile creation

### lib/Home/pages/library_profile.dart
- Buddy button -> `Navigator.push(MyBuddy)`
- Multiple `Navigator.pop` calls to close dialogs (add/edit/delete)

### lib/Home/pages/select_profile.dart
- No token -> `Navigator.pop`
- Confirm button -> `Navigator.pushNamed('/home', arguments: {'profileId': ...})`

### lib/Home/pages/home.dart
- Home button -> `Navigator.pushReplacement(Home)`
- Profile row -> `Navigator.pushReplacement(SelectProfile)`
- Medicine button -> `Navigator.pushNamed('/list_medicine', arguments: {'profileId': ...})`

### lib/Home/pages/buddy.dart
- Next button -> `Navigator.push(SelectProfile)`

### lib/Home/pages/history.dart
- Back button -> `Navigator.pop`

### lib/Home/pages/add_medicine/createName_medicine.dart
- `_goNext` -> `Navigator.push(FindMedicinePage)` then `Navigator.pop` with `MedicineItem`

### lib/Home/pages/add_medicine/find_medicine.dart
- `_goNext` -> `Navigator.push(AddMedicinePage)` then `Navigator.pop` with `MedicineItem`
- `_scanByCamera` -> `Navigator.push(CameraOcrPage)` and receive OCR text

### lib/Home/pages/add_medicine/add_medicine.dart
- `_showNotFoundDialog` -> `Navigator.pop` (close dialog); `Navigator.push(RequestMedicinePage)` on request action
- `_goNext` -> `Navigator.push(SummaryMedicinePage)` then `Navigator.pop` with `MedicineItem`

### lib/Home/pages/add_medicine/summary_medicine.dart
- `_saveMedicine` -> `Navigator.pop` with `MedicineItem` (even on error)
- Info icon -> `showMedicineDetailDialog` (currently returns early)

### lib/Home/pages/add_medicine/detail_medicine.dart
- Close button -> `Navigator.pop`

### lib/Home/pages/add_medicine/request_medicine.dart
- `_submitRequest` -> `Navigator.pop`

### lib/Home/pages/add_medicine/list_medicine.dart
- `_addMedicine` -> `Navigator.push(CreateNameMedicinePage)`
- `_buildMedicineCard` -> `Navigator.push(RemindListScreen)`
- `_buildBottomBar` -> `Navigator.pushReplacement(Home)`
- Uses `showDialog` in `_showDetails` and `_confirmDelete`

### lib/Home/pages/set_remind/remind_list_screen.dart
- `_addPlan` -> `Navigator.push(SetRemindScreen)` returning `ReminderPlan`
- `_editPlan` -> `Navigator.push(SetRemindScreen)` returning `ReminderPlan`
- `_deletePlan` -> `showDialog` and `Navigator.pop` to close

### lib/Home/pages/set_remind/setRemind_screen.dart
- `_prevStep` -> `Navigator.pop` when on first step
- `_savePlan` -> `Navigator.pop` with `ReminderPlan`

### lib/OCR/camera_ocr.dart
- `_processImage` -> `Navigator.push(OcrResultPage)`; if text returned -> `Navigator.pop` with text
- AppBar back -> `Navigator.pop` if `canPop`

### lib/OCR/ocr_result_page.dart
- `OcrSuccessPage.initState` -> `Navigator.pushReplacement(OcrResultPage)`
- Back/search button -> `Navigator.pop` returning OCR text

## E) Shared Data Contracts & Cross-file Variables
### Supabase client (`Supabase.instance.client`)
- Defined/initialized: `Supabase.initialize` in `lib/main.dart`
- Read/write: `lib/API/auth_gate.dart`, `lib/API/authen_login.dart`, `lib/API/auth_session.dart`, `lib/pages/login.dart`, `lib/pages/otp.dart`, `lib/pages/forget_password.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/library_profile.dart`, `lib/services/medicine_api.dart`
- What breaks if changed: all auth/session/token flows
- Example usages: `AuthenLoginEmail.signInWithEmail` (`lib/API/authen_login.dart`), `MedicineApi._getAccessToken` (`lib/services/medicine_api.dart`)

### Environment variable `API_BASE_URL`
- Defined/loaded: `.env` via `dotenv.load` in `lib/main.dart`
- Read/write: `lib/services/profile_api.dart`, `lib/services/medicine_api.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/library_profile.dart`
- What breaks if changed: backend API calls and image URL composition
- Example usages: `ProfileApi` constructor (`lib/services/profile_api.dart`), `MedicineApi._baseUrl` (`lib/services/medicine_api.dart`)

### `kDisableAuthGate`
- Defined: `lib/main.dart`
- Read/write: `defaultPage()` in `lib/main.dart`
- What breaks if changed: entry routing (AuthGate vs LoginScreen)
- Example usages: `defaultPage()` in `lib/main.dart`

### Supabase access token
- Source: `Supabase.instance.client.auth.currentSession?.accessToken`
- Read/write: `AuthSession.accessToken` (`lib/API/auth_session.dart`), `MedicineApi._getAccessToken` (`lib/services/medicine_api.dart`), `ProfileScreen`/`SelectProfile`/`LibraryProfile`
- What breaks if changed: any API call requiring Bearer token
- Example usages: `ProfileApi.createProfile` called with token from `ProfileScreen`

### Profile model (`ProfileModel`)
- Defined: `lib/Model/profile_model.dart`
- Read/write: `lib/Home/pages/home.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`
- What breaks if changed: profile display and cross-screen data flow
- Example usages: `ProfileScreen._goNext` builds `ProfileModel` and passes to `LibraryProfile`

### Medicine models (`MedicineCatalogItem`, `MedicineDraft`, `MedicineItem`)
- Defined: `lib/Model/medicine_model.dart`
- Read/write: `lib/Home/pages/add_medicine/*`, `lib/Home/pages/set_remind/*`, `lib/OCR/ocr_result_page.dart`, `lib/services/medicine_api.dart`
- What breaks if changed: add/search flows, reminder binding, API parsing
- Example usages: `MedicineApi.fetchMedicineCatalog` returns `MedicineCatalogItem`, `SummaryMedicinePage` builds `MedicineItem`

### Reminder plan (`ReminderPlan`, `ReminderDose`)
- Defined: `lib/Home/pages/set_remind/setFuctionRemind.dart`
- Read/write: `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`
- What breaks if changed: reminder creation and listing UI
- Example usages: `_ReminderPlanStore.upsertPlan` (`lib/Home/pages/set_remind/remind_list_screen.dart`)

### Route-level `profileId`
- Defined/passed via: `Navigator.pushNamed('/home' | '/list_medicine', arguments: ...)`
- Read/write: consumed in `lib/main.dart` for `/list_medicine`
- What breaks if changed: profile-specific data loading
- Example usages: `Home` sends `profileId` to `/list_medicine`, `SelectProfile` sends `profileId` to `/home`

## F) API / Backend Communication
- Supabase init: `Supabase.initialize` in `lib/main.dart` uses string literals for `anonKey` and `url` (values not printed here)
- Supabase Auth: `AuthenSignUpEmail.signUpWithEmail`, `AuthenLoginEmail.signInWithEmail`, `LoginWithGoogle.signInWithOAuth`, `AuthenLogout.signOut` in `lib/API/authen_login.dart`
- Password recovery: `Supabase.auth.resetPasswordForEmail` in `lib/pages/login.dart`, `Supabase.auth.updateUser` + `signOut` in `lib/pages/forget_password.dart`
- OTP verify: `lib/pages/otp.dart` sends `http.post` to Supabase `/auth/v1/verify` (using `supabaseAnonKey`), then POSTs to `/api/mobile/v1/auth/sync-user`
- Profile API (Dio): `lib/services/profile_api.dart`
  - `POST /api/mobile/v1/profile/create`
  - `PATCH /api/mobile/v1/profile/update`
  - `GET /api/mobile/v1/profile/list`
  - `DELETE /api/mobile/v1/profile/delete`
- Medicine API (http): `lib/services/medicine_api.dart`
  - `GET /api/admin/v1/medicine/list` (params: `search`, `page`, `pageSize`, `order`, `includeDeleted`)
  - `POST /api/mobile/v1/medicine-list/create` (multipart: `profileId`, `mediId`, `mediNickname`, `picture`)
  - `GET /api/mobile/v1/medicine-list/list` (query: `profileId`)
- Token attachment: `Authorization: Bearer <access_token>` from `Supabase.instance.client.auth.currentSession?.accessToken`
- Error handling patterns: `MedicineApi` throws based on status/body, `ProfileApi` checks status manually, UI shows `SnackBar`, `ListMedicinePage` sanitizes HTML error strings

## G) OCR / Camera / Image Handling Flow
1) User starts from `FindMedicinePage` -> taps scan -> `CameraOcrPage`
2) `CameraOcrPage` uses `CameraController` or `ImagePicker` to obtain an image file
3) Calls `OcrImageCropper.crop` to crop the image
4) Calls `OcrTextService.recognize` (ML Kit `TextRecognizer` with latin script) to extract text
5) Opens `OcrResultPage` to show image + editable text; pressing search `Navigator.pop` returns the text
6) `CameraOcrPage` receives the text and `Navigator.pop`s back to `FindMedicinePage` to fill the search field
7) `OcrSuccessPage` exists in `lib/OCR/ocr_result_page.dart` but is not used by `CameraOcrPage` right now

## H) Critical Risks / Bug-Prone Points (Top 10)
1) `kDisableAuthGate = true` in `lib/main.dart` bypasses `AuthGate`, potentially ignoring existing sessions
2) Route `/list_medicine` expects `settings.arguments` as `int` in `lib/main.dart`, but callers sometimes pass a `Map` or nothing (`lib/Home/pages/home.dart`, `lib/widgets/app_drawer.dart`)
3) `ListMedicinePage` uses `_profileId = 1` instead of `widget.profileId` (`lib/Home/pages/add_medicine/list_medicine.dart`), causing wrong profile data
4) `/home` receives arguments from `SelectProfile`, but `Home` does not read route arguments (`lib/Home/pages/select_profile.dart`, `lib/Home/pages/home.dart`)
5) Hardcoded Supabase `anonKey`/URL in `lib/main.dart` and `lib/pages/otp.dart` (with TODO to align keys) risks mismatch or leakage
6) `lib/main.dart` prints full `dotenv.env` to console, risking secret exposure
7) `ProfileApi` logs token prefixes and full responses (`lib/services/profile_api.dart`), which may leak sensitive data
8) OTP flow does not validate the `/auth/sync-user` response before navigation (`lib/pages/otp.dart`)
9) Info icon in `SummaryMedicinePage` calls `showMedicineDetailDialog` which returns early (`lib/Home/pages/add_medicine/detail_medicine.dart`), resulting in dead UI
10) OCR uses `TextRecognitionScript.latin` (`lib/OCR/ocr_text_service.dart`), which may underperform for Thai text

## I) Sequence Diagram Seed (Ready-to-draw)
1) Sign Up + OTP verification
- Participants: User, `SignupScreen`, Supabase Auth, `OTPScreen`, Supabase Verify API, Backend API, `LoginScreen`
- Steps:
  1. User -> `SignupScreen`: enter email/password
  2. `SignupScreen` -> Supabase Auth: `signUp`
  3. Supabase Auth -> `SignupScreen`: success/error
  4. `SignupScreen` -> `OTPScreen`: navigate with email
  5. User -> `OTPScreen`: enter OTP
  6. `OTPScreen` -> Supabase Verify API: POST `/auth/v1/verify`
  7. Supabase Verify API -> `OTPScreen`: return `access_token`
  8. `OTPScreen` -> Backend API: POST `/api/mobile/v1/auth/sync-user`
  9. `OTPScreen` -> `LoginScreen`: `pushReplacement`

2) Sign In
- Participants: User, `LoginScreen`, Supabase Auth, `ProfileScreen`
- Steps:
  1. User -> `LoginScreen`: enter email/password
  2. `LoginScreen` -> Supabase Auth: `signInWithPassword`
  3. Supabase Auth -> `LoginScreen`: session token
  4. `LoginScreen` -> `ProfileScreen`: `push` or `pushReplacement` on `signedIn`

3) Password Recovery
- Participants: User, `LoginScreen`, Supabase Auth, `ForgetPassword`
- Steps:
  1. User -> `LoginScreen`: tap forgot password
  2. `LoginScreen` -> Supabase Auth: `resetPasswordForEmail` (custom scheme redirect)
  3. Supabase Auth -> `LoginScreen`: `AuthChangeEvent.passwordRecovery`
  4. `LoginScreen` -> `ForgetPassword`: `pushReplacement`
  5. `ForgetPassword` -> Supabase Auth: `updateUser` + `signOut`
  6. `ForgetPassword` -> `LoginScreen`: `pushAndRemoveUntil`

4) App open with existing session
- Participants: App, `main()`, `AuthGate`, Supabase Auth, `ProfileScreen`/`LoginScreen`
- Steps:
  1. App -> `main()`: load `.env`, `Supabase.initialize`
  2. `main()` -> `defaultPage()`: choose `AuthGate` when `kDisableAuthGate=false`
  3. `AuthGate` -> Supabase Auth: read `currentSession`
  4. Supabase Auth -> `AuthGate`: session/null
  5. `AuthGate` -> `ProfileScreen` or `LoginScreen`

5) OCR capture -> crop -> result
- Participants: User, `FindMedicinePage`, `CameraOcrPage`, Camera/ImagePicker, `OcrImageCropper`, `OcrTextService`, `OcrResultPage`
- Steps:
  1. User -> `FindMedicinePage`: tap scan
  2. `FindMedicinePage` -> `CameraOcrPage`: `push`
  3. `CameraOcrPage` -> Camera/ImagePicker: capture/select image
  4. `CameraOcrPage` -> `OcrImageCropper`: crop image
  5. `CameraOcrPage` -> `OcrTextService`: OCR text
  6. `CameraOcrPage` -> `OcrResultPage`: `push`
  7. `OcrResultPage` -> `CameraOcrPage`: `pop` with OCR text
  8. `CameraOcrPage` -> `FindMedicinePage`: `pop` with OCR text

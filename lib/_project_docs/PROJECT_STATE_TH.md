# สถานะโปรเจกต์

## A) ภาพรวมโปรเจกต์
- วัตถุประสงค์แอป: จัดการโปรไฟล์ผู้ใช้/ผู้ป่วย, เพิ่ม-ค้นหายา (รองรับ OCR), ตั้งเตือนการทานยา และดูประวัติการทานยา
- โมดูลหลักใน lib/:
  - Auth/Onboarding: `lib/main.dart`, `lib/API/*`, `lib/pages/*`
  - โปรไฟล์และหน้า Home: `lib/Home/pages/home.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/buddy.dart`
  - จัดการยา: `lib/Home/pages/add_medicine/*`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`
  - ระบบแจ้งเตือน: `lib/Home/pages/set_remind/*`
  - OCR/กล้อง: `lib/OCR/*`
  - โมเดลและวิดเจ็ตแชร์: `lib/Model/*`, `lib/widgets/*`
- บริการ/แพ็กเกจภายนอกที่ใช้: `supabase_flutter`, `flutter_dotenv`, `http`, `dio`, `camera`, `image_picker`, `image_cropper`, `google_mlkit_text_recognition`, `flutter_otp_text_field`, `intl`

## B) แผนที่การพึ่งพาไฟล์และโมดูล (Tree + Graph)
### B1) โครงสร้างไฟล์ (เฉพาะ .dart)
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

### B2) Dependency graph (ไฟล์สำคัญ)
#### lib/main.dart
- Imports (ภายในโปรเจกต์): `lib/API/auth_gate.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/history.dart`, `lib/Home/pages/home.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`, `lib/OCR/camera_ocr.dart`, `lib/pages/forget_password.dart`, `lib/pages/login.dart`, `lib/pages/signup.dart`
- คลาส/ฟังก์ชันหลัก: `main()`, `MyApp`, `defaultPage()`, `kDisableAuthGate`
- ถูกใช้งานโดย: Flutter entrypoint
- เรียก/ใช้งานต่อ: `dotenv.load`, `Supabase.initialize`, `initializeDateFormatting`, `Intl.defaultLocale`, `MaterialApp.onGenerateRoute` สำหรับเส้นทาง `/login`, `/signup`, `/profile`, `/select_profile`, `/home`, `/forget_password`, `/library_profile`, `/list_medicine`, `/history`, `/camera_ocr`

#### lib/API/auth_gate.dart
- Imports (ภายในโปรเจกต์): `lib/pages/login.dart`, `lib/Home/pages/profile_screen.dart`
- คลาส/ฟังก์ชันหลัก: `AuthGate`
- ถูกใช้งานโดย: `lib/main.dart`
- เรียก/ใช้งานต่อ: เช็ค `Supabase.instance.client.auth.currentSession` แล้วคืน `ProfileScreen` หรือ `LoginScreen`

#### lib/API/auth_session.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `AuthSession`
- ถูกใช้งานโดย: ยังไม่มีไฟล์อื่นอิมพอร์ต
- เรียก/ใช้งานต่อ: อ่าน `Supabase.instance.client.auth.currentSession`

#### lib/API/authen_login.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `AuthenSignUpEmail`, `LoginWithGoogle`, `AuthenLoginEmail`, `AuthenLogout`, ตัวแปร `supabase`
- ถูกใช้งานโดย: `lib/pages/login.dart`, `lib/pages/signup.dart`, `lib/widgets/app_drawer.dart`
- เรียก/ใช้งานต่อ: `supabase.auth.signUp`, `supabase.auth.signInWithPassword`, `supabase.auth.signInWithOAuth`, `supabase.auth.signOut`

#### lib/pages/login.dart
- Imports (ภายในโปรเจกต์): `lib/pages/signup.dart`, `lib/widgets/login_button.dart`, `lib/API/authen_login.dart`, `lib/pages/forget_password.dart`, `lib/Home/pages/profile_screen.dart`
- คลาส/ฟังก์ชันหลัก: `LoginScreen`, `_LoginScreenState`, `_handleLogin`, `_handleGoogleLogin`, `forgetPassword`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/API/auth_gate.dart`, `lib/pages/forget_password.dart`, `lib/pages/otp.dart`, `lib/widgets/app_drawer.dart`
- เรียก/ใช้งานต่อ: `AuthenLoginEmail.signInWithEmail`, `LoginWithGoogle.signInWithGoogle`, `Supabase.auth.onAuthStateChange`, `Supabase.auth.resetPasswordForEmail`, นำทางไป `SignupScreen`, `ProfileScreen`, `ForgetPassword`

#### lib/pages/signup.dart
- Imports (ภายในโปรเจกต์): `lib/pages/otp.dart`, `lib/API/authen_login.dart`
- คลาส/ฟังก์ชันหลัก: `SignupScreen`, `_SignupScreenState`, `_handleSignup`, `validatePassword`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/pages/login.dart`
- เรียก/ใช้งานต่อ: `AuthenSignUpEmail.signUpWithEmail`, นำทางไป `OTPScreen`

#### lib/pages/otp.dart
- Imports (ภายในโปรเจกต์): `lib/pages/login.dart`
- คลาส/ฟังก์ชันหลัก: `OTPScreen`, `_OTPScreenState`, `confirmOTP`, `_parseJwt`
- ถูกใช้งานโดย: `lib/pages/signup.dart`
- เรียก/ใช้งานต่อ: `http.post` ไป Supabase verify endpoint (ใช้ตัวแปร `supabaseAnonKey`), `http.post` ไป `/api/mobile/v1/auth/sync-user`, `Supabase.auth.resend`, นำทางไป `LoginScreen`

#### lib/pages/forget_password.dart
- Imports (ภายในโปรเจกต์): `lib/widgets/login_button.dart`, `lib/pages/login.dart`
- คลาส/ฟังก์ชันหลัก: `ForgetPassword`, `_ForgetPassword`, `_handleResetPassword`, `validatePassword`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/pages/login.dart`
- เรียก/ใช้งานต่อ: `Supabase.auth.updateUser`, `Supabase.auth.signOut`, นำทางแบบ `pushAndRemoveUntil` ไป `LoginScreen`

#### lib/Home/pages/profile_screen.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/library_profile.dart`, `lib/Model/profile_model.dart`, `lib/services/profile_api.dart`
- คลาส/ฟังก์ชันหลัก: `ProfileScreen`, `_ProfileScreenState`, `_onCameraTap`, `_goNext`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/API/auth_gate.dart`, `lib/pages/login.dart`
- เรียก/ใช้งานต่อ: `ProfileApi.createProfile`, `Supabase.auth.currentSession`, `ImagePicker`, นำทางไป `LibraryProfile`

#### lib/Home/pages/library_profile.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/buddy.dart`, `lib/Model/profile_model.dart`, `lib/services/profile_api.dart`, `lib/widgets/profile_widget.dart`
- คลาส/ฟังก์ชันหลัก: `LibraryProfile`, `_LibraryProfileState`, `_loadProfiles`, `_editProfile`, `_confirmDeleteProfile`, `_deleteProfile`, `_addProfile`, `create_profile`, `update_profile`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/Home/pages/profile_screen.dart`
- เรียก/ใช้งานต่อ: `ProfileApi.fetchProfiles`, `ProfileApi.createProfile`, `ProfileApi.updateProfile`, `ProfileApi.deleteProfile`, `ImagePicker`, `showDialog`, นำทางไป `MyBuddy`

#### lib/Home/pages/select_profile.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/home.dart`, `lib/Model/profile_model.dart`, `lib/services/profile_api.dart`, `lib/widgets/app_drawer.dart`
- คลาส/ฟังก์ชันหลัก: `SelectProfile`, `_SelectProfileState`, `_loadProfiles`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/Home/pages/home.dart`, `lib/Home/pages/buddy.dart`
- เรียก/ใช้งานต่อ: `ProfileApi.fetchProfiles`, `Supabase.auth.currentSession`, นำทางไป `/home` ด้วย `Navigator.pushNamed`

#### lib/Home/pages/home.dart
- Imports (ภายในโปรเจกต์): `lib/widgets/app_drawer.dart`, `lib/Model/profile_model.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/select_profile.dart`
- คลาส/ฟังก์ชันหลัก: `Home`, `_Home`, `_MedicineReminder`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`
- เรียก/ใช้งานต่อ: นำทางไป `/list_medicine` ด้วย `Navigator.pushNamed`, นำทางแบบ `pushReplacement` ไป `SelectProfile` และ `Home`

#### lib/Home/pages/buddy.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/select_profile.dart`
- คลาส/ฟังก์ชันหลัก: `MyBuddy`, `_MyBuddyState`
- ถูกใช้งานโดย: `lib/Home/pages/library_profile.dart`
- เรียก/ใช้งานต่อ: นำทางไป `SelectProfile`

#### lib/Home/pages/history.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `HistoryPage`, `_HistoryPageState`, `MedicineHistoryItem`, `MedicineTakeStatus`, `_DateField`, `_HistoryRow`
- ถูกใช้งานโดย: `lib/main.dart`
- เรียก/ใช้งานต่อ: `showDatePicker`, `Navigator.pop`, มี TODO สำหรับเรียก API ประวัติ

#### lib/Home/pages/note_medicine.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: ไม่มี (ไฟล์ว่าง)
- ถูกใช้งานโดย: ไม่มี

#### lib/Home/pages/add_medicine/createName_medicine.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/add_medicine/find_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/widgets/medicine_step_timeline.dart`
- คลาส/ฟังก์ชันหลัก: `CreateNameMedicinePage`, `_CreateNameMedicinePageState`, `_ImageCircleButton`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/list_medicine.dart`
- เรียก/ใช้งานต่อ: สร้าง `MedicineDraft`, ใช้ `ImagePicker`, นำทางไป `FindMedicinePage`, ส่งกลับ `MedicineItem`

#### lib/Home/pages/add_medicine/find_medicine.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/add_medicine/add_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/OCR/camera_ocr.dart`, `lib/widgets/medicine_step_timeline.dart`
- คลาส/ฟังก์ชันหลัก: `FindMedicinePage`, `_FindMedicinePageState`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/createName_medicine.dart`
- เรียก/ใช้งานต่อ: นำทางไป `AddMedicinePage`, นำทางไป `CameraOcrPage`, ส่งกลับ `MedicineItem`

#### lib/Home/pages/add_medicine/add_medicine.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/add_medicine/request_medicine.dart`, `lib/Home/pages/add_medicine/summary_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`, `lib/widgets/medicine_step_timeline.dart`
- คลาส/ฟังก์ชันหลัก: `AddMedicinePage`, `_AddMedicinePageState`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/find_medicine.dart`
- เรียก/ใช้งานต่อ: `MedicineApi.fetchMedicineCatalog`, แสดงผล/กรองรายการ, นำทางไป `SummaryMedicinePage`, เปิด `RequestMedicinePage` เมื่อไม่พบผลลัพธ์

#### lib/Home/pages/add_medicine/summary_medicine.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/add_medicine/detail_medicine.dart`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`, `lib/widgets/medicine_step_timeline.dart`
- คลาส/ฟังก์ชันหลัก: `SummaryMedicinePage`, `_SummaryMedicinePageState`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/add_medicine.dart`
- เรียก/ใช้งานต่อ: `MedicineApi.addMedicineToProfile`, เรียก `showMedicineDetailDialog`, ส่งกลับ `MedicineItem`

#### lib/Home/pages/add_medicine/detail_medicine.dart
- Imports (ภายในโปรเจกต์): `lib/Model/medicine_model.dart`
- คลาส/ฟังก์ชันหลัก: ฟังก์ชัน `showMedicineDetailDialog`, วิดเจ็ต `_MedicineDetailContent`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/summary_medicine.dart`
- เรียก/ใช้งานต่อ: `showDialog` (ปัจจุบันถูก return ออกทันทีเพื่อปิดการใช้งาน)

#### lib/Home/pages/add_medicine/request_medicine.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `RequestMedicinePage`, `_RequestMedicinePageState`, `_ImageCircleButton`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/add_medicine.dart`
- เรียก/ใช้งานต่อ: ใช้ `ImagePicker`, `Navigator.pop` หลังส่งคำร้อง (ตอนนี้เป็น mock)

#### lib/Home/pages/add_medicine/list_medicine.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/add_medicine/createName_medicine.dart`, `lib/Home/pages/home.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`, `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Model/medicine_model.dart`, `lib/services/medicine_api.dart`, `lib/widgets/app_drawer.dart`
- คลาส/ฟังก์ชันหลัก: `ListMedicinePage`, `_ListMedicinePageState`
- ถูกใช้งานโดย: `lib/main.dart`, `lib/Home/pages/home.dart`
- เรียก/ใช้งานต่อ: `MedicineApi.fetchProfileMedicineList`, นำทางไป `CreateNameMedicinePage`, `RemindListScreen`, `Home`, ใช้ `showDialog`

#### lib/Home/pages/set_remind/setFuctionRemind.dart
- Imports (ภายในโปรเจกต์): `lib/Model/medicine_model.dart`
- คลาส/ฟังก์ชันหลัก: `ReminderDose`, `ReminderPlan`, `MealTimingIcon`, ฟังก์ชัน UI `type_frequency`, `detail_time`, `summary_rejimen`, helper `buildMedicineImage`, `formatTime`
- ถูกใช้งานโดย: `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`
- เรียก/ใช้งานต่อ: ใช้ข้อมูลจาก `MedicineItem` เพื่อสร้าง UI

#### lib/Home/pages/set_remind/setRemind_screen.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/set_remind/setFuctionRemind.dart`, `lib/Model/medicine_model.dart`
- คลาส/ฟังก์ชันหลัก: `SetRemindScreen`, `_SetRemindScreenState`, `_CircleNavButton`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`
- เรียก/ใช้งานต่อ: สร้าง/แก้ไข `ReminderPlan` แล้ว `Navigator.pop` ส่งกลับให้ผู้เรียก

#### lib/Home/pages/set_remind/remind_list_screen.dart
- Imports (ภายในโปรเจกต์): `lib/Home/pages/set_remind/setFuctionRemind.dart`, `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Model/medicine_model.dart`
- คลาส/ฟังก์ชันหลัก: `RemindListScreen`, `_RemindListScreenState`, `_ReminderPlanStore`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/list_medicine.dart`
- เรียก/ใช้งานต่อ: นำทางไป `SetRemindScreen`, จัดเก็บแผนเตือนแบบ in-memory

#### lib/Model/medicine_model.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `MedicineCatalogItem`, `MedicineDraft`, `MedicineItem`, `MedicineCatalogItem.fromJson`, `MedicineItem.mediId`
- ถูกใช้งานโดย: add_medicine flow, OCR, reminder, `lib/services/medicine_api.dart`
- เรียก/ใช้งานต่อ: ใช้เป็นสัญญาข้อมูลร่วม (data contract)

#### lib/Model/profile_model.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `ProfileModel`
- ถูกใช้งานโดย: `lib/Home/pages/home.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`
- เรียก/ใช้งานต่อ: เป็นโมเดลโปรไฟล์ร่วม

#### lib/services/medicine_api.dart
- Imports (ภายในโปรเจกต์): `lib/Model/medicine_model.dart`
- คลาส/ฟังก์ชันหลัก: `MedicineApi`, `fetchMedicineCatalog`, `fetchProfileMedicineList`, `addMedicineToProfile`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/add_medicine.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`, `lib/Home/pages/add_medicine/summary_medicine.dart`
- เรียก/ใช้งานต่อ: อ่าน `API_BASE_URL` จาก `.env`, ดึง access token จาก `Supabase.instance.client`, เรียก HTTP endpoints ของ backend

#### lib/services/profile_api.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `ProfileApi`, `createProfile`, `updateProfile`, `fetchProfiles`, `deleteProfile`
- ถูกใช้งานโดย: `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`
- เรียก/ใช้งานต่อ: อ่าน `API_BASE_URL` จาก `.env`, ใช้ `Dio` ส่ง multipart/form-data ไป backend

#### lib/services/mock_auth_service.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `MockAuthService`
- ถูกใช้งานโดย: ไม่มี (ถูกคอมเมนต์ใน `lib/pages/login.dart`)

#### lib/OCR/camera_ocr.dart
- Imports (ภายในโปรเจกต์): `lib/OCR/ocr_camera_frame.dart`, `lib/OCR/ocr_image_cropper.dart`, `lib/OCR/ocr_result_page.dart`, `lib/OCR/ocr_text_service.dart`
- คลาส/ฟังก์ชันหลัก: `CameraOcrPage`, `_CameraOcrPageState`
- ถูกใช้งานโดย: `lib/Home/pages/add_medicine/find_medicine.dart`, `lib/main.dart`
- เรียก/ใช้งานต่อ: ใช้ `CameraController`, `ImagePicker`, `OcrImageCropper.crop`, `OcrTextService.recognize`, นำทางไป `OcrResultPage`

#### lib/OCR/ocr_result_page.dart
- Imports (ภายในโปรเจกต์): `lib/widgets/medicine_step_timeline.dart`, `lib/Model/medicine_model.dart`
- คลาส/ฟังก์ชันหลัก: `OcrSuccessPage`, `OcrResultPage`, `_CircleIconButton`
- ถูกใช้งานโดย: `lib/OCR/camera_ocr.dart`
- เรียก/ใช้งานต่อ: `Navigator.pushReplacement` ไป `OcrResultPage`, `Navigator.pop` ส่งข้อความ OCR กลับ

#### lib/OCR/ocr_text_service.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `OcrTextService`
- ถูกใช้งานโดย: `lib/OCR/camera_ocr.dart`
- เรียก/ใช้งานต่อ: ML Kit `TextRecognizer.processImage`

#### lib/OCR/ocr_image_cropper.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `OcrImageCropper`
- ถูกใช้งานโดย: `lib/OCR/camera_ocr.dart`
- เรียก/ใช้งานต่อ: `ImageCropper.cropImage`

#### lib/OCR/ocr_camera_frame.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `OcrCameraFrame`
- ถูกใช้งานโดย: `lib/OCR/camera_ocr.dart`
- เรียก/ใช้งานต่อ: วิดเจ็ต UI แสดงเฟรมกล้อง

#### lib/widgets/app_drawer.dart
- Imports (ภายในโปรเจกต์): `lib/API/authen_login.dart`, `lib/pages/login.dart`
- คลาส/ฟังก์ชันหลัก: `AppDrawer`
- ถูกใช้งานโดย: `lib/Home/pages/home.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/add_medicine/list_medicine.dart`
- เรียก/ใช้งานต่อ: `AuthenLogout.signOut`, `Navigator.pushReplacementNamed` ไป `/home`, `/list_medicine`, `/history`, `/library_profile`, `/select_profile`, และ `Navigator.pushAndRemoveUntil` ไป `LoginScreen`

#### lib/widgets/login_button.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `LoginButton`, `SignupButton`, `resetPassword`
- ถูกใช้งานโดย: `lib/pages/login.dart`, `lib/pages/forget_password.dart`
- เรียก/ใช้งานต่อ: วิดเจ็ต UI เท่านั้น

#### lib/widgets/medicine_step_timeline.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `MedicineStepTimeline`
- ถูกใช้งานโดย: add_medicine flow และ `lib/OCR/ocr_result_page.dart`
- เรียก/ใช้งานต่อ: วิดเจ็ต UI เท่านั้น

#### lib/widgets/profile_widget.dart
- Imports (ภายในโปรเจกต์): ไม่มี
- คลาส/ฟังก์ชันหลัก: `ProfileWidget`
- ถูกใช้งานโดย: `lib/Home/pages/library_profile.dart`
- เรียก/ใช้งานต่อ: วิดเจ็ต UI เท่านั้น

## C) ลำดับการทำงาน Auth & Onboarding (End-to-end)
1) `main()` ใน `lib/main.dart` โหลด `.env` ผ่าน `dotenv.load`, เริ่ม `Supabase.initialize`, ตั้งค่า locale แล้วรัน `MyApp`
2) `defaultPage()` เลือกหน้าเริ่มต้นตาม `kDisableAuthGate` (ปัจจุบัน `true` -> `LoginScreen`; ถ้า `false` -> `AuthGate`)
3) `AuthGate` (`lib/API/auth_gate.dart`) เช็ค `supabase.auth.currentSession` ถ้ามี session ไป `ProfileScreen` ถ้าไม่มีกลับ `LoginScreen`
4) Login: `LoginScreen._handleLogin` เรียก `AuthenLoginEmail.signInWithEmail` แล้วนำทางไป `ProfileScreen` (และมี listener `auth.onAuthStateChange` ที่ `signedIn` -> `pushReplacement` ไป `ProfileScreen`)
5) Sign Up: `SignupScreen._handleSignup` เรียก `AuthenSignUpEmail.signUpWithEmail` ถ้าสำเร็จ (หรือเจอ error แบบ already registered) -> `Navigator.push` ไป `OTPScreen`
6) OTP: `OTPScreen.confirmOTP` เรียก `http.post` ไป Supabase `/auth/v1/verify` ด้วยตัวแปร `supabaseAnonKey` -> ได้ `access_token` -> `http.post` ไป `/api/mobile/v1/auth/sync-user` -> `Navigator.pushReplacement` ไป `LoginScreen`
7) Google OAuth: `LoginWithGoogle.signInWithOAuth` ใช้ redirect URI แบบ custom scheme
8) Password recovery: `LoginScreen.forgetPassword` เรียก `supabase.auth.resetPasswordForEmail`; เมื่อเกิด `AuthChangeEvent.passwordRecovery` จะ `pushReplacement` ไป `ForgetPassword`; จากนั้น `ForgetPassword` เรียก `supabase.auth.updateUser` -> `signOut` -> กลับ `LoginScreen`
9) หลัง login: `ProfileScreen` เรียก `ProfileApi.createProfile` แล้วนำทางไป `LibraryProfile`; `SelectProfile` ใช้ profile ที่เลือกเพื่อไป `Home`

## D) แผนที่การนำทาง (Navigation Map)
### lib/pages/login.dart
- `_handleLogin` -> `Navigator.push(ProfileScreen)`; เงื่อนไข: form valid + login success; side effects: setState `_isLoading`
- `auth.onAuthStateChange` -> `Navigator.pushReplacement(ForgetPassword)` เมื่อ `passwordRecovery`; `Navigator.pushReplacement(ProfileScreen)` เมื่อ `signedIn`
- ปุ่มสมัครสมาชิก -> `Navigator.push(SignupScreen)`
- `forgetPassword()` dialog -> `Navigator.pop` เพื่อปิด dialog

### lib/pages/signup.dart
- `_handleSignup` -> `Navigator.push(OTPScreen)` เมื่อสมัครสำเร็จหรือ error แบบ already registered
- ปุ่มกลับ -> `Navigator.pop` เพื่อกลับหน้าเดิม
- `Navigator.pop` ภายใน dialog/alert (ปิด dialog)

### lib/pages/otp.dart
- `confirmOTP` สำเร็จ -> `Navigator.pushReplacement(LoginScreen)`
- AppBar back -> `Navigator.pop`

### lib/pages/forget_password.dart
- `_handleResetPassword` สำเร็จ -> `Navigator.pushAndRemoveUntil(LoginScreen, (_) => false)`

### lib/widgets/app_drawer.dart
- `_go` -> `Navigator.pop` (ปิด drawer) แล้ว `Navigator.pushReplacementNamed` ไป `/home`, `/list_medicine`, `/history`, `/library_profile`, `/select_profile`
- `logout` -> `Navigator.pushAndRemoveUntil(LoginScreen, (_) => false)`

### lib/Home/pages/profile_screen.dart
- `_goNext` -> `Navigator.pushReplacement(LibraryProfile)` หลังสร้างโปรไฟล์

### lib/Home/pages/library_profile.dart
- ปุ่มไปหน้า Buddy -> `Navigator.push(MyBuddy)`
- หลายจุดใช้ `Navigator.pop` เพื่อปิด dialog (add/edit/delete)

### lib/Home/pages/select_profile.dart
- ไม่มี token -> `Navigator.pop` กลับหน้าก่อนหน้า
- ปุ่มยืนยัน -> `Navigator.pushNamed('/home', arguments: {'profileId': ...})`

### lib/Home/pages/home.dart
- ปุ่ม Home -> `Navigator.pushReplacement(Home)`
- ปุ่มโปรไฟล์ -> `Navigator.pushReplacement(SelectProfile)`
- ปุ่มยา -> `Navigator.pushNamed('/list_medicine', arguments: {'profileId': ...})`

### lib/Home/pages/buddy.dart
- ปุ่มไปต่อ -> `Navigator.push(SelectProfile)`

### lib/Home/pages/history.dart
- ปุ่ม back -> `Navigator.pop`

### lib/Home/pages/add_medicine/createName_medicine.dart
- `_goNext` -> `Navigator.push(FindMedicinePage)` และเมื่อได้ผลลัพธ์ -> `Navigator.pop` ส่ง `MedicineItem`

### lib/Home/pages/add_medicine/find_medicine.dart
- `_goNext` -> `Navigator.push(AddMedicinePage)` และเมื่อได้ผลลัพธ์ -> `Navigator.pop` ส่ง `MedicineItem`
- `_scanByCamera` -> `Navigator.push(CameraOcrPage)` แล้วรับข้อความ OCR

### lib/Home/pages/add_medicine/add_medicine.dart
- `_showNotFoundDialog` -> `Navigator.pop` ปิด dialog; `Navigator.push(RequestMedicinePage)` เมื่อผู้ใช้กดส่งคำร้อง
- `_goNext` -> `Navigator.push(SummaryMedicinePage)` และเมื่อบันทึกสำเร็จ -> `Navigator.pop` ส่ง `MedicineItem`

### lib/Home/pages/add_medicine/summary_medicine.dart
- `_saveMedicine` -> `Navigator.pop` ส่ง `MedicineItem` (แม้กรณี error)
- ปุ่ม info -> เรียก `showMedicineDetailDialog` (ตอนนี้ return ทันที)

### lib/Home/pages/add_medicine/detail_medicine.dart
- ปุ่มปิด dialog -> `Navigator.pop`

### lib/Home/pages/add_medicine/request_medicine.dart
- `_submitRequest` -> `Navigator.pop`

### lib/Home/pages/add_medicine/list_medicine.dart
- `_addMedicine` -> `Navigator.push(CreateNameMedicinePage)`
- `_buildMedicineCard` -> `Navigator.push(RemindListScreen)`
- `_buildBottomBar` -> `Navigator.pushReplacement(Home)`
- ใช้ `showDialog` ใน `_showDetails` และ `_confirmDelete`

### lib/Home/pages/set_remind/remind_list_screen.dart
- `_addPlan` -> `Navigator.push(SetRemindScreen)` รับ `ReminderPlan`
- `_editPlan` -> `Navigator.push(SetRemindScreen)` รับ `ReminderPlan`
- `_deletePlan` -> `showDialog` และ `Navigator.pop` ปิด dialog

### lib/Home/pages/set_remind/setRemind_screen.dart
- `_prevStep` -> `Navigator.pop` เมื่ออยู่ step แรก
- `_savePlan` -> `Navigator.pop` ส่ง `ReminderPlan`

### lib/OCR/camera_ocr.dart
- `_processImage` -> `Navigator.push(OcrResultPage)`; ถ้าได้ข้อความ -> `Navigator.pop` ส่งข้อความกลับ
- AppBar back -> `Navigator.pop` หาก `canPop`

### lib/OCR/ocr_result_page.dart
- `OcrSuccessPage.initState` -> `Navigator.pushReplacement(OcrResultPage)`
- ปุ่ม back / ปุ่มค้นหา -> `Navigator.pop` (ส่งข้อความ OCR กลับ)

## E) สัญญาข้อมูลร่วมและตัวแปรข้ามไฟล์ (Shared Contracts)
### Supabase client (`Supabase.instance.client`)
- นิยาม/ตั้งค่า: `Supabase.initialize` ใน `lib/main.dart`
- อ่าน/เขียน: `lib/API/auth_gate.dart`, `lib/API/authen_login.dart`, `lib/API/auth_session.dart`, `lib/pages/login.dart`, `lib/pages/otp.dart`, `lib/pages/forget_password.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/library_profile.dart`, `lib/services/medicine_api.dart`
- ถ้าเปลี่ยนจะกระทบ: ทุก flow ที่ใช้ session/access token หรือ auth listener
- ตัวอย่างการใช้: `AuthenLoginEmail.signInWithEmail` (`lib/API/authen_login.dart`), `MedicineApi._getAccessToken` (`lib/services/medicine_api.dart`)

### Environment variable `API_BASE_URL`
- นิยาม/ตั้งค่า: โหลดจาก `.env` ใน `lib/main.dart`
- อ่าน/เขียน: `lib/services/profile_api.dart`, `lib/services/medicine_api.dart`, `lib/Home/pages/select_profile.dart`, `lib/Home/pages/library_profile.dart`
- ถ้าเปลี่ยนจะกระทบ: ทุก API call และการแสดงรูปจาก backend
- ตัวอย่างการใช้: `ProfileApi` constructor (`lib/services/profile_api.dart`), `MedicineApi._baseUrl` (`lib/services/medicine_api.dart`)

### `kDisableAuthGate`
- นิยาม: `lib/main.dart`
- อ่าน/เขียน: `defaultPage()` ใน `lib/main.dart`
- ถ้าเปลี่ยนจะกระทบ: เส้นทางเริ่มต้นของแอป (ข้าม/ไม่ข้าม AuthGate)
- ตัวอย่างการใช้: `defaultPage()` ใน `lib/main.dart`

### Access token จาก Supabase
- นิยาม/ที่มา: `Supabase.instance.client.auth.currentSession?.accessToken`
- อ่าน/เขียน: `AuthSession.accessToken` (`lib/API/auth_session.dart`), `MedicineApi._getAccessToken` (`lib/services/medicine_api.dart`), `ProfileScreen`/`SelectProfile`/`LibraryProfile`
- ถ้าเปลี่ยนจะกระทบ: ทุก API call ที่ต้องใช้ Bearer token
- ตัวอย่างการใช้: `ProfileApi.createProfile` (เรียกด้วย token จาก `ProfileScreen`)

### โมเดลโปรไฟล์ (`ProfileModel`)
- นิยาม: `lib/Model/profile_model.dart`
- อ่าน/เขียน: `lib/Home/pages/home.dart`, `lib/Home/pages/library_profile.dart`, `lib/Home/pages/profile_screen.dart`, `lib/Home/pages/select_profile.dart`
- ถ้าเปลี่ยนจะกระทบ: การแสดงชื่อ/รูปโปรไฟล์และการส่งค่าไปหน้าต่าง ๆ
- ตัวอย่างการใช้: `ProfileScreen._goNext` สร้าง `ProfileModel` ก่อนส่งต่อ

### โมเดลยา (`MedicineCatalogItem`, `MedicineDraft`, `MedicineItem`)
- นิยาม: `lib/Model/medicine_model.dart`
- อ่าน/เขียน: `lib/Home/pages/add_medicine/*`, `lib/Home/pages/set_remind/*`, `lib/OCR/ocr_result_page.dart`, `lib/services/medicine_api.dart`
- ถ้าเปลี่ยนจะกระทบ: การสร้างรายการยา, การค้นหา, การตั้งเตือน
- ตัวอย่างการใช้: `MedicineApi.fetchMedicineCatalog` คืน `MedicineCatalogItem`, `SummaryMedicinePage` สร้าง `MedicineItem`

### แผนเตือนยา (`ReminderPlan`, `ReminderDose`)
- นิยาม: `lib/Home/pages/set_remind/setFuctionRemind.dart`
- อ่าน/เขียน: `lib/Home/pages/set_remind/setRemind_screen.dart`, `lib/Home/pages/set_remind/remind_list_screen.dart`
- ถ้าเปลี่ยนจะกระทบ: หน้าตั้งเตือนและรายการเตือน
- ตัวอย่างการใช้: `_ReminderPlanStore.upsertPlan` (`lib/Home/pages/set_remind/remind_list_screen.dart`)

### ข้อมูล `profileId` ที่ส่งผ่าน route
- นิยาม/ส่งค่า: `Navigator.pushNamed('/home' | '/list_medicine', arguments: ...)`
- อ่าน/เขียน: รับค่าใน `lib/main.dart` (route `/list_medicine`)
- ถ้าเปลี่ยนจะกระทบ: การโหลดข้อมูลโปรไฟล์/รายการยา
- ตัวอย่างการใช้: `Home` ส่ง `profileId` ไป `/list_medicine`, `SelectProfile` ส่ง `profileId` ไป `/home`

## F) การสื่อสารกับ Backend / API
- Supabase init: `Supabase.initialize` ใน `lib/main.dart` ใช้ค่า `anonKey` และ `url` แบบ string literal (ไม่พิมพ์ค่าในรายงานนี้)
- Supabase Auth: `AuthenSignUpEmail.signUpWithEmail`, `AuthenLoginEmail.signInWithEmail`, `LoginWithGoogle.signInWithOAuth`, `AuthenLogout.signOut` ใน `lib/API/authen_login.dart`
- Password recovery: `Supabase.auth.resetPasswordForEmail` ใน `lib/pages/login.dart`, `Supabase.auth.updateUser` + `signOut` ใน `lib/pages/forget_password.dart`
- OTP verify: `lib/pages/otp.dart` ส่ง `http.post` ไป Supabase `/auth/v1/verify` (ใช้ตัวแปร `supabaseAnonKey`) แล้ว POST ต่อไป `/api/mobile/v1/auth/sync-user`
- Profile API (Dio): `lib/services/profile_api.dart`
  - `POST /api/mobile/v1/profile/create`
  - `PATCH /api/mobile/v1/profile/update`
  - `GET /api/mobile/v1/profile/list`
  - `DELETE /api/mobile/v1/profile/delete`
- Medicine API (http): `lib/services/medicine_api.dart`
  - `GET /api/admin/v1/medicine/list` (params: `search`, `page`, `pageSize`, `order`, `includeDeleted`)
  - `POST /api/mobile/v1/medicine-list/create` (multipart: `profileId`, `mediId`, `mediNickname`, `picture`)
  - `GET /api/mobile/v1/medicine-list/list` (query: `profileId`)
- การแนบ token: ส่ง `Authorization: Bearer <access_token>` จาก `Supabase.instance.client.auth.currentSession?.accessToken`
- รูปแบบจัดการ error: `MedicineApi` โยน Exception จาก body/status, `ProfileApi` ตรวจ status เอง, UI แสดง `SnackBar` และมีการ sanitize HTML ใน `ListMedicinePage`

## G) ลำดับ OCR / กล้อง / จัดการรูป
1) ผู้ใช้เริ่มจาก `FindMedicinePage` -> กดสแกน -> `CameraOcrPage`
2) `CameraOcrPage` ใช้ `CameraController` หรือ `ImagePicker` เพื่อได้ไฟล์รูป
3) เรียก `OcrImageCropper.crop` เพื่อตัดรูป
4) เรียก `OcrTextService.recognize` (ML Kit `TextRecognizer` script: latin) เพื่ออ่านข้อความ
5) เปิด `OcrResultPage` แสดงรูป + แก้ไขข้อความ, กดค้นหาแล้ว `Navigator.pop` ส่งข้อความกลับ
6) `CameraOcrPage` รับข้อความและ `Navigator.pop` กลับไป `FindMedicinePage` เพื่อเติมช่องค้นหา
7) มี `OcrSuccessPage` ใน `lib/OCR/ocr_result_page.dart` แต่ปัจจุบันไม่ได้ถูกเรียกใช้งานจาก `CameraOcrPage`

## H) จุดเสี่ยง/บั๊กที่ควรระวัง (Top 10)
1) `kDisableAuthGate = true` ใน `lib/main.dart` ทำให้ข้าม `AuthGate` และอาจไม่สอดคล้องกับ session จริง
2) เส้นทาง `/list_medicine` ใน `lib/main.dart` คาดว่า `settings.arguments` เป็น `int` แต่ผู้เรียกบางจุดส่งเป็น `Map` หรือไม่ส่งค่า (`lib/Home/pages/home.dart`, `lib/widgets/app_drawer.dart`)
3) `ListMedicinePage` ใช้ `_profileId = 1` ไม่ได้ใช้ `widget.profileId` (`lib/Home/pages/add_medicine/list_medicine.dart`) ทำให้โหลดข้อมูลผิดโปรไฟล์
4) `/home` รับ arguments จาก `SelectProfile` แต่ `Home` ไม่อ่านค่า route arguments (`lib/Home/pages/select_profile.dart`, `lib/Home/pages/home.dart`)
5) มีการ hardcode `anonKey`/Supabase URL ใน `lib/main.dart` และ `lib/pages/otp.dart` (และมี TODO ให้ใช้ key เดียวกัน) เสี่ยง mismatch หรือหลุดความลับ
6) `lib/main.dart` พิมพ์ `dotenv.env` ทั้งหมดลง console เสี่ยงเผยค่า secret ใน log
7) `ProfileApi` พิมพ์ token prefix และ response ลง log (`lib/services/profile_api.dart`) อาจเสี่ยงข้อมูลรั่ว
8) OTP flow ไม่ตรวจผล `sync-user` ก่อนนำทาง (`lib/pages/otp.dart`) อาจทำให้ backend ไม่ sync แต่ยังไปต่อ
9) ปุ่ม info ใน `SummaryMedicinePage` เรียก `showMedicineDetailDialog` ที่ถูก return ทันที (`lib/Home/pages/add_medicine/detail_medicine.dart`) ทำให้ UI ไม่ทำงาน
10) OCR ใช้ `TextRecognitionScript.latin` (`lib/OCR/ocr_text_service.dart`) อาจอ่านภาษาไทยได้ไม่ดี ส่งผลกับการค้นหา

## I) Sequence Diagram Seed (Ready-to-draw)
1) สมัครสมาชิก + ยืนยัน OTP
- Participants: User, `SignupScreen`, Supabase Auth, `OTPScreen`, Supabase Verify API, Backend API, `LoginScreen`
- Steps:
  1. User -> `SignupScreen`: กรอกอีเมล/รหัสผ่าน
  2. `SignupScreen` -> Supabase Auth: `signUp`
  3. Supabase Auth -> `SignupScreen`: success/error
  4. `SignupScreen` -> `OTPScreen`: นำทางพร้อม email
  5. User -> `OTPScreen`: กรอก OTP
  6. `OTPScreen` -> Supabase Verify API: POST `/auth/v1/verify`
  7. Supabase Verify API -> `OTPScreen`: ส่ง `access_token`
  8. `OTPScreen` -> Backend API: POST `/api/mobile/v1/auth/sync-user`
  9. `OTPScreen` -> `LoginScreen`: `pushReplacement`

2) เข้าสู่ระบบ (Sign In)
- Participants: User, `LoginScreen`, Supabase Auth, `ProfileScreen`
- Steps:
  1. User -> `LoginScreen`: กรอกอีเมล/รหัสผ่าน
  2. `LoginScreen` -> Supabase Auth: `signInWithPassword`
  3. Supabase Auth -> `LoginScreen`: session token
  4. `LoginScreen` -> `ProfileScreen`: `push` หรือ `pushReplacement` เมื่อ `signedIn`

3) ขอเปลี่ยนรหัสผ่าน (Password Recovery)
- Participants: User, `LoginScreen`, Supabase Auth, `ForgetPassword`
- Steps:
  1. User -> `LoginScreen`: กดลืมรหัสผ่าน
  2. `LoginScreen` -> Supabase Auth: `resetPasswordForEmail` (redirect custom scheme)
  3. Supabase Auth -> `LoginScreen`: `AuthChangeEvent.passwordRecovery`
  4. `LoginScreen` -> `ForgetPassword`: `pushReplacement`
  5. `ForgetPassword` -> Supabase Auth: `updateUser` + `signOut`
  6. `ForgetPassword` -> `LoginScreen`: `pushAndRemoveUntil`

4) เปิดแอปด้วย session เดิม
- Participants: App, `main()`, `AuthGate`, Supabase Auth, `ProfileScreen`/`LoginScreen`
- Steps:
  1. App -> `main()`: load `.env`, `Supabase.initialize`
  2. `main()` -> `defaultPage()`: เลือก `AuthGate` เมื่อ `kDisableAuthGate=false`
  3. `AuthGate` -> Supabase Auth: อ่าน `currentSession`
  4. Supabase Auth -> `AuthGate`: session/null
  5. `AuthGate` -> `ProfileScreen` หรือ `LoginScreen`

5) OCR capture -> crop -> result
- Participants: User, `FindMedicinePage`, `CameraOcrPage`, Camera/ImagePicker, `OcrImageCropper`, `OcrTextService`, `OcrResultPage`
- Steps:
  1. User -> `FindMedicinePage`: กดสแกน
  2. `FindMedicinePage` -> `CameraOcrPage`: `push`
  3. `CameraOcrPage` -> Camera/ImagePicker: ถ่าย/เลือกรูป
  4. `CameraOcrPage` -> `OcrImageCropper`: crop รูป
  5. `CameraOcrPage` -> `OcrTextService`: OCR text
  6. `CameraOcrPage` -> `OcrResultPage`: `push`
  7. `OcrResultPage` -> `CameraOcrPage`: `pop` ส่งข้อความ OCR
  8. `CameraOcrPage` -> `FindMedicinePage`: `pop` ส่งข้อความกลับ

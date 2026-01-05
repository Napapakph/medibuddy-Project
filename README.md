# medibuddy

แอป Flutter สำหรับระบบล็อกอิน / สมัครสมาชิก / ยืนยันตัวตนด้วย OTP และเชื่อมต่อ Supabase

> คอมเมนต์และคำอธิบายใน README นี้เป็นภาษาไทยทั้งหมด เพื่อช่วยให้เข้าใจโครงสร้างโปรเจกต์ได้ง่ายขึ้น

---

## 1. ภาพรวมโปรเจกต์

- Framework หลัก: `Flutter` (ใช้ `material.dart` เป็น UI หลัก)
- Backend as a Service: `supabase_flutter` (ใช้สำหรับสมัครสมาชิก / resend OTP / จัดการ auth)
- การยืนยันตัวตนด้วยรหัส OTP: `flutter_otp_text_field`
- ล็อกอินผ่าน Google: `google_sign_in` (เตรียม dependency ไว้แล้วใน `pubspec.yaml`)
- HTTP client: `http` (ใช้ในหน้า OTP เพื่อยิง REST API ไป Supabase และ backend ภายนอก)

ไฟล์ Dart หลักทั้งหมดอยู่ในโฟลเดอร์ `lib/` แบ่งตามหน้าจอ (pages), service, widget และ API layer

---

## 2. รายละเอียดแต่ละไฟล์หลักใน `lib/`

### 2.1 `lib/main.dart`
- หน้าที่:
  - เป็น entry point ของแอป (`main()`)
  - เรียก `Supabase.initialize(...)` เพื่อเชื่อมต่อโปรเจกต์ Supabase (ใช้ `url` และ `anonKey`)
  - รัน `MyApp` ซึ่งเป็น `MaterialApp` หลักของระบบ
  - กำหนด `initialRoute` และ `routes` สำหรับ
    - `/login` → `LoginScreen`
    - `/signup` → `SignupScreen`
    - `/otp` → `OTPScreen`
- ใช้ library:
  - `package:flutter/material.dart`
  - `package:supabase_flutter/supabase_flutter.dart`
  - local imports: `pages/login.dart`, `pages/signup.dart`, `pages/otp.dart`

---

### 2.2 โฟลเดอร์ `lib/pages/`

#### 2.2.1 `lib/pages/login.dart`
- หน้าที่:
  - หน้าล็อกอินหลักของแอป
  - มี `Form` พร้อม `TextFormField` สำหรับกรอก Email / Password
  - ใช้ `_formKey` เพื่อ `validate()` ฟอร์มก่อนทำงาน
  - ใช้ `MockAuthService` จำลองการล็อกอินด้วยอีเมล/รหัสผ่าน (ยังไม่ผูกกับ Supabase จริง)
  - มีปุ่มไปหน้าสมัครสมาชิก, ปุ่มลืมรหัสผ่าน (แสดง Dialog), และปุ่ม Login ปกติ
  - มีโครงปุ่มล็อกอินด้วย Google (เตรียมไว้ใช้งานร่วมกับ `google_sign_in`)
- ใช้ library:
  - `package:flutter/material.dart` – สร้าง UI ด้วย Widget ต่าง ๆ เช่น `Scaffold`, `TextFormField`, `SnackBar`
  - `../services/mock_auth_service.dart` – เรียก service ล็อกอินจำลอง
  - `package:google_sign_in/google_sign_in.dart` – ไว้สำหรับ Google Sign-In
  - `signup.dart` – นำทางไปหน้าสมัครสมาชิก
  - `../widgets/login_button.dart` – ใช้ปุ่ม UI ที่แยกออกมาเป็น widget

#### 2.2.2 `lib/pages/signup.dart`
- หน้าที่:
  - หน้าสมัครสมาชิกด้วยอีเมลและรหัสผ่าน
  - มี `Form` ที่ประกอบด้วย:
    - ช่องกรอกอีเมล
    - ช่องกรอกรหัสผ่าน
    - ช่องยืนยันรหัสผ่าน
    - กฎการตั้งรหัสผ่าน (ความยาว / ตัวใหญ่ / ตัวเล็ก / ตัวเลขหรือสัญลักษณ์)
  - มีฟังก์ชัน `_handleSignup()`
    - `validate()` ฟอร์มผ่าน `_formKey`
    - ถ้าข้อมูลไม่ครบ/ไม่ตรงตามเงื่อนไข → แสดง `SnackBar` เป็นภาษาไทย
    - ถ้าผ่าน → เรียก `_authAPI.signUpWithEmail(...)` ซึ่งเชื่อมไป Supabase
    - ถ้าสมัครสำเร็จ → แสดงข้อความแจ้งเตือน และ `Navigator.push` ไปหน้า `OTPScreen` พร้อมส่งค่า `email`
  - ใช้สถานะ `_isLoading` เพื่อปิดปุ่มตอนกำลังยิง API
- ใช้ library:
  - `package:flutter/material.dart`
  - local imports:
    - `otp.dart` – ไปหน้า OTP หลังสมัครสำเร็จ
    - `../API/authen_login.dart` – เรียกฟังก์ชันสมัครสมาชิกผ่าน Supabase

#### 2.2.3 `lib/pages/otp.dart`
- หน้าที่:
  - หน้ายืนยัน OTP สำหรับอีเมลที่สมัครเข้ามา
  - รับพารามิเตอร์ `email` ผ่าน `OTPScreen({required this.email})`
  - มีช่องกรอก OTP แบบ 6 หลักผ่าน `OtpTextField`
  - เมื่อกดปุ่มยืนยัน OTP:
    - อ่านค่าจาก `_otp.text`
    - ตรวจว่าไม่ว่าง → ถ้าว่างแสดง `SnackBar`
    - ยิง `http.post` ไปที่ Supabase REST API `/auth/v1/verify` เพื่อ verify token
    - ถ้า `statusCode != 200` → แสดง error
    - ถ้า success → อ่าน `access_token` จาก response
    - ยิง HTTP ต่อไปยัง backend ภายนอก (`/api/auth/sync-user`) พร้อมส่ง `Authorization: Bearer <access_token>`
    - แสดง `AlertDialog` ขึ้นมาพร้อมแสดง `access_token` (เพื่อ debug และตรวจสอบว่าได้ token จริง)
  - มีปุ่ม `Resend OTP` ที่เรียก
    - `Supabase.instance.client.auth.resend(type: OtpType.signup, email: widget.email)`
  - มีปุ่มยืนยัน (OutlinedButton) ที่เรียก `confirmOTP()`
- ใช้ library:
  - `package:flutter/material.dart`
  - `package:flutter_otp_text_field/flutter_otp_text_field.dart`
  - `dart:convert` – ใช้ `jsonEncode` / `jsonDecode` สร้าง/อ่าน JSON
  - `package:http/http.dart` as `http` – ใช้ยิง REST API ไป Supabase และ backend ภายนอก
  - `package:supabase_flutter/supabase_flutter.dart` – ใช้ฟังก์ชัน resend OTP
  - local import: `login.dart` (เตรียมไว้สำหรับนำทางกลับ / ใช้งานภายใน)

#### 2.2.4 `lib/pages/forget_password.dart`
- หน้าที่ (โดยรวมจากชื่อไฟล์และการอ้างอิง):
  - รองรับ flow การลืมรหัสผ่าน / ตั้งรหัสผ่านใหม่
  - ไฟล์นี้ถูกเรียกผ่าน dialog ใน `login.dart` (ฟังก์ชัน `forgetPassword()`)
  - มี TextField ให้กรอกอีเมลและปุ่มส่งคำขอรีเซ็ตรหัสผ่าน (ปัจจุบันยังไม่เรียก API จริง)

#### 2.2.5 `lib/pages/new_password.dart`
- หน้าที่ (ตามชื่อไฟล์):
  - เตรียมไว้สำหรับหน้าตั้งรหัสผ่านใหม่ หลังจากผู้ใช้ยืนยันตัวตนแล้ว
  - สามารถขยายเพิ่มให้เชื่อมกับ API reset password ของ backend/Supabase ได้ภายหลัง

#### 2.2.6 `lib/pages/note.txt`
- หน้าที่:
  - ไฟล์จดโน้ต/แนวคิดของผู้พัฒนา (ไม่ใช่ไฟล์โค้ด Dart)
  - ใช้บันทึกไอเดีย / แผนงาน / ข้อความประกอบการพัฒนา

---

### 2.3 โฟลเดอร์ `lib/API/`

#### 2.3.1 `lib/API/authen_login.dart`
- หน้าที่:
  - เป็นชั้น abstraction สำหรับเรียก Supabase Auth API
  - กำหนดตัวแปร `supabase = Supabase.instance.client`
  - คลาส `AuthenLogin` มีเมธอด `signUpWithEmail({required String email, required String password})`
    - เรียก `supabase.auth.signUp(email: email, password: password)`
    - ถ้า `res.user == null` → คืนค่า String ข้อความ error (ภาษาไทย)
    - จับ `AuthException` แล้วคืนค่า `e.message`
    - จับ error อื่น ๆ แล้วคืนข้อความ error ทั่วไป (ภาษาไทย)
  - ถ้าไม่มี error → คืนค่า `null` หมายถึงสมัครสำเร็จ
- ใช้ library:
  - `package:supabase_flutter/supabase_flutter.dart`

---

### 2.4 โฟลเดอร์ `lib/services/`

#### 2.4.1 `lib/services/mock_auth_service.dart`
- หน้าที่:
  - จำลองระบบล็อกอินเพื่อใช้ทดสอบ UI โดยไม่ต้องมี backend จริง
  - กำหนดค่า mock ภายใน:
    - `_mockEmail = 'test@email.com'`
    - `_mockPassword = '123456'`
  - เมธอด `login({required String email, required String password})`:
    - คืนค่า `true` ถ้า email/password ตรงกับค่าที่ mock ไว้
    - ใช้ร่วมกับหน้า `login.dart`
- ใช้ library:
  - ไม่มี import เพิ่ม เพราะใช้เฉพาะ Dart พื้นฐาน

---

### 2.5 โฟลเดอร์ `lib/widgets/`

#### 2.5.1 `lib/widgets/login_button.dart`
- หน้าที่:
  - รวมปุ่มที่ใช้งานซ้ำในหลายหน้า เช่น ปุ่ม Login และปุ่ม Signup

- คลาส `LoginButton`:
  - Stateless widget สำหรับปุ่มล็อกอินที่เต็มความกว้าง (`width: double.infinity`)
  - พารามิเตอร์:
    - `text` (String) – ข้อความบนปุ่ม (ตอนนี้ตัว widget ใช้ข้อความคงที่เป็นภาษาไทย)
    - `onPressed` (VoidCallback) – ฟังก์ชันที่เรียกเมื่อกดปุ่ม
    - `isLoading` (bool) – ถ้า true จะปิดปุ่มและแสดง `CircularProgressIndicator`
  - ใช้ `ElevatedButton.styleFrom(...)` ตั้งสีพื้นหลัง / รูปทรง / padding

- คลาส `SignupButton`:
  - Stateless widget สำหรับปุ่มสมัครสมาชิก
  - พารามิเตอร์:
    - `text` – ข้อความบนปุ่ม
    - `onPressed` – ฟังก์ชันเมื่อกดปุ่ม
  - ใช้ `ElevatedButton` สีฟ้าอ่อน (`0xFFB7DAFF`) ตัวหนังสือสีดำ

- ใช้ library:
  - `package:flutter/material.dart`

---

### 2.6 โฟลเดอร์ `lib/Home/`

#### 2.6.1 `lib/Home/pages/home.dart`
- หน้าที่:
  - หน้า Home แบบง่าย ๆ สำหรับทดสอบหลังล็อกอิน สามารถขยายต่อในอนาคต
  - แสดง `AppBar()` ว่าง ๆ และข้อความ `Hi` กลางหน้า
- ใช้ library:
  - `package:flutter/material.dart`

---

### 2.7 โฟลเดอร์ `lib/OCR/`

#### 2.7.1 `lib/OCR/camera_ocr.dart`
- หน้าที่:
  - ไฟล์นี้ยังว่าง (ไม่มีโค้ดภายใน)
  - น่าจะถูกเตรียมไว้สำหรับฟีเจอร์ถ่ายรูป/สแกนข้อความ (OCR) ในอนาคต

---

## 3. Assets และการตั้งค่าใน `pubspec.yaml`

ไฟล์ `pubspec.yaml` กำหนด dependencies หลักดังนี้:

- `flutter` – SDK หลัก
- `cupertino_icons` – ไอคอนสไตล์ iOS
- `google_sign_in` – รองรับ Google Login
- `supabase_flutter` – ใช้งาน Supabase Auth / Database
- `flutter_otp_text_field` – widget กรอก OTP แบบช่องแยก

ส่วน Assets:

- `assets/cat_login.png` – ใช้ในหน้า `login.dart`
- `assets/Sign_up_cat.png` – ใช้ในหน้า `signup.dart`
- `assets/OTP.png` – ใช้ในหน้า `otp.dart`

---

## 4. โฟลเดอร์แพลตฟอร์ม (Android / iOS / Web / Desktop)

ไฟล์เหล่านี้ส่วนใหญ่เป็นไฟล์ที่ Flutter สร้างอัตโนมัติ เช่น

- `android/` – Gradle, AndroidManifest, MainActivity.kt ฯลฯ
- `ios/` – Xcode project, Info.plist ฯลฯ
- `web/` – `index.html`, `manifest.json`, รูป icon ต่าง ๆ
- `windows/`, `linux/`, `macos/` – ไฟล์ CMake และ bootstrap สำหรับ desktop

โดยทั่วไปไม่ต้องแก้ไฟล์เหล่านี้มากนัก ถ้าไม่เกี่ยวกับการตั้งค่าพิเศษของแพลตฟอร์มนั้น ๆ

---

## 5. สรุปการทำงานรวมของแอป

1. ผู้ใช้เปิดแอป → `main.dart` รัน `MyApp` และเปิดหน้า `/login`
2. ผู้ใช้สามารถ:
   - ล็อกอินด้วยอีเมล/รหัสผ่าน (ทดสอบผ่าน `MockAuthService`)
   - กดไปหน้าสมัครสมาชิก → `SignupScreen`
3. ใน `SignupScreen`:
   - กรอกอีเมล / ตั้งรหัสผ่าน / ยืนยันรหัสผ่าน
   - ฟอร์มจะ `validate()` ก่อน
   - ถ้าผ่าน → เรียก `AuthenLogin.signUpWithEmail()` (Supabase) เพื่อสมัคร และไปหน้า OTP
4. ใน `OTPScreen`:
   - ผู้ใช้กรอก OTP 6 หลัก
   - แอปจะยิง REST API ไป verify กับ Supabase และ sync กับ backend ภายนอก
   - ถ้าสำเร็จ → มี access token แสดงใน Dialog (ใช้ debug / ทดสอบ)
5. สามารถต่อยอดไปหน้า `homePage` หรือฟีเจอร์อื่น ๆ ได้ภายหลัง

---

## 6. หมายเหตุสำหรับผู้พัฒนา

- คีย์ Supabase (`anonKey`) ในโค้ดควรย้ายไปเก็บอย่างปลอดภัย (เช่น dotenv หรือ secret manager) ก่อน deploy จริง
- ไฟล์ `camera_ocr.dart` ยังไม่มีการใช้งาน สามารถนำมาใช้สำหรับ OCR ในอนาคต
- `MockAuthService` ใช้สำหรับทดสอบ UI เท่านั้น ไม่ควรใช้ในโปรดักชัน


## สำคัญมาก ถ้าเปลี่ยน sever อย่าลืมไปแก้ใน \android\app\src\main\res\xml\network_security_config.xml ด้วย


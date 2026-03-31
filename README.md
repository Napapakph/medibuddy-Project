# 📱 Medibuddy Mobile Application

## 1. ภาพรวมโปรเจค (Project Overview)

Medibuddy เป็นแอปพลิเคชันมือถือสำหรับจัดการและแจ้งเตือนการรับประทานยา พัฒนาด้วย Flutter โดยออกแบบมาเพื่อช่วยให้ผู้ใช้งานสามารถติดตามตารางการกินยา รับการแจ้งเตือนตรงเวลา และบันทึกการรับประทานยาได้อย่างสะดวก

แอปนี้มีเป้าหมายเพื่อช่วยเพิ่มความสม่ำเสมอในการกินยา และเป็นระบบบันทึกข้อมูลสุขภาพที่เชื่อถือได้สำหรับผู้ใช้งาน

### ฟีเจอร์หลัก

- **การติดตามยา (Medication Tracking)**  
  บันทึกรายละเอียดยา ปริมาณ และเวลาที่ต้องรับประทาน

- **ระบบแจ้งเตือนอัตโนมัติ (Automated Reminders)**  
  แจ้งเตือนทั้งแบบ push notification และ local notification ตามเวลาที่กำหนด

- **การยืนยันการกินยา (Intake Confirmation)**  
  ผู้ใช้สามารถบันทึกว่าได้กินยา ข้ามยา หรือเลื่อนเวลา พร้อมเพิ่มหมายเหตุได้

- **Text-to-Speech (TTS)**  
  อ่านข้อมูลยาออกเสียง เพื่อช่วยผู้ใช้ในการรับข้อมูลแบบเสียง

- **OCR (สแกนข้อความจากกล้อง)**  
  ใช้กล้องเพื่อสแกนฉลากยาและดึงข้อความอัตโนมัติ

- **การจัดการโปรไฟล์ (Profile Management)**  
  รองรับหลายโปรไฟล์ เช่น ใช้ดูแลสมาชิกในครอบครัว

---

## 2. เทคโนโลยีที่ใช้ (Tech Stack)

- **Framework:** Flutter
- **Language:** Dart

### แพ็กเกจสำคัญ

- `dio` → ใช้สำหรับเรียก API และจัดการ network request
- `flutter_tts` → ใช้สำหรับระบบอ่านออกเสียง (Text-to-Speech)
- `firebase_messaging` และ `flutter_local_notifications` → ใช้สำหรับระบบแจ้งเตือน
- `google_mlkit_text_recognition` และ `camera` → ใช้สำหรับ OCR (อ่านตัวอักษรจากภาพ)
- `flutter_dotenv` → ใช้จัดการ environment variables
- `shared_preferences` และ `flutter_secure_storage` → ใช้เก็บข้อมูลภายในเครื่องอย่างปลอดภัย

---

## 3. โครงสร้างโปรเจค (Project Structure)

โปรเจคถูกจัดโครงสร้างแบบแยกหน้าที่ (modular) เพื่อให้ดูแลและพัฒนาต่อได้ง่าย

- **`lib/screens/`** (รวมถึงโฟลเดอร์ฟีเจอร์ เช่น `lib/alarm_medicine/`)  
  ใช้เก็บหน้าจอหลักของแอป (UI) และ routing ต่างๆ

- **`lib/widgets/`**  
  ใช้เก็บ component UI ที่สามารถนำกลับมาใช้ซ้ำได้ เช่น ปุ่ม, toast, container แบบ custom

- **`lib/models/`**  
  ใช้กำหนดโครงสร้างข้อมูล (data model) และการแปลง JSON

- **`lib/services/`**  
  ใช้จัดการการเชื่อมต่อกับ API และ logic ที่เกี่ยวกับ backend  
  (เช่น `auth_manager`, `log_api`)  
  โดยแยกออกจาก UI เพื่อให้โค้ดสะอาดและดูแลง่าย

---

## 4. ความต้องการของระบบ (Requirements)

ก่อนรันโปรเจค ต้องมีสิ่งเหล่านี้:

- **Flutter SDK:** เวอร์ชัน 3.5.0 ขึ้นไป
- **Dart SDK:** มาพร้อมกับ Flutter

### IDE

- Android Studio
- Visual Studio Code (พร้อม Flutter extension)

### อุปกรณ์

- Emulator (Android / iOS)
- หรือเครื่องจริง (แนะนำสำหรับทดสอบกล้องและ notification)

---

## 5. การติดตั้งและรันโปรเจค (Installation & Setup)

### 1. Clone โปรเจค

```bash
git clone <repository_url>
cd medibuddy
```

### 2. ติดตั้ง dependencies

ดึง package ทั้งหมดจาก `pubspec.yaml`

````bash
flutter pub get

### 3. ตั้งค่า environment

สร้างไฟล์ `.env` ใน root ของโปรเจค และกำหนดค่า API

```bash
API_BASE_URL=https://api.yourbackend.com
### 4. รันแอป

เปิด emulator หรือเชื่อมต่อมือถือ แล้วรัน:

```bash
flutter run
````

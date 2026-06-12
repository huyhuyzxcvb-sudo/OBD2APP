cat > /home/claude/README.md << 'ENDOFFILE'
# OBD2 Diagnostics App

Ứng dụng Android đọc dữ liệu xe qua cổng OBD-II sử dụng thiết bị ELM327 Bluetooth, được xây dựng bằng Flutter/Dart.

---

## Tính năng chính

- Kết nối Bluetooth Classic với thiết bị ELM327
- Đọc 5 thông số xe theo thời gian thực: RPM, tốc độ, nhiệt độ nước làm mát, vị trí bướm ga, điện áp ắc quy
- Dashboard trực quan với đồng hồ đo hình cung tùy chỉnh
- Hệ thống cảnh báo thông minh 3 mức (Normal / Warning / Critical)
- Lưu trữ lịch sử dữ liệu SQLite + đồng bộ Supabase Cloud
- Biểu đồ thống kê 24h / 7 ngày
- Quản lý thông tin xe theo mã VIN

---

## Yêu cầu hệ thống

| Thành phần | Phiên bản tối thiểu |
|-----------|---------------------|
| Hệ điều hành máy tính | Windows 10/11 (64-bit) |
| Java JDK | 17 trở lên |
| Android Studio | 2023.x trở lên |
| Flutter SDK | 3.x (stable) |
| Android SDK | API 21 (Android 5.0) trở lên |
| Điện thoại Android | Android 5.0 trở lên |

---

## Bước 1 — Cài đặt Java Development Kit (JDK)

1. Truy cập: https://www.oracle.com/java/technologies/downloads/#java17
2. Tải **JDK 17** phiên bản Windows x64 Installer
3. Chạy file cài đặt và làm theo hướng dẫn
4. Kiểm tra cài đặt thành công:

```cmd
java -version
```

Kết quả mong đợi:
```
java version "17.x.x"
```

---

## Bước 2 — Cài đặt Android Studio

1. Tải tại: https://developer.android.com/studio
2. Chạy file cài đặt, chọn **Standard** setup
3. Trong quá trình cài đặt đảm bảo chọn:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device
4. Sau khi cài xong, mở Android Studio → **SDK Manager** → cài thêm:
   - Android SDK Platform **API 35** (hoặc mới nhất)
   - Android SDK Build-Tools

---

## Bước 3 — Cài đặt Flutter SDK

1. Truy cập: https://flutter.dev/docs/get-started/install/windows
2. Tải file nén Flutter SDK
3. Giải nén vào thư mục: `C:\src\flutter`
4. Thêm Flutter vào biến môi trường PATH:
   - Mở **Control Panel** → **System** → **Advanced system settings**
   - Chọn **Environment Variables**
   - Tìm biến **Path** → **Edit** → **New**
   - Thêm: `C:\src\flutter\bin`
   - Nhấn OK để lưu
5. Mở Command Prompt mới và chạy:

```cmd
flutter doctor
```

Kết quả mong đợi:
```
[✓] Flutter (Channel stable)
[✓] Android toolchain
[✓] Android Studio
[✓] Connected device
```

6. Nếu có cảnh báo Android licenses, chạy:

```cmd
flutter doctor --android-licenses
```
Nhấn `y` để chấp nhận tất cả.

---

## Bước 4 — Cài đặt Visual Studio Code (khuyến nghị)

1. Tải tại: https://code.visualstudio.com
2. Cài đặt extension **Flutter**:
   - Mở VS Code → nhấn `Ctrl+Shift+X`
   - Tìm **Flutter** → nhấn **Install**
   - Extension Dart sẽ được cài tự động kèm theo

---

## Bước 5 — Clone dự án

```cmd
git clone https://github.com/huyhuyzxcvb-sudo/OBD2APP.git
cd OBD2APP
```

Hoặc tải trực tiếp file ZIP từ GitHub → giải nén vào thư mục làm việc.

---

## Bước 6 — Cài đặt dependencies

Mở terminal trong thư mục dự án và chạy:

```cmd
flutter pub get
```

---

## Bước 7 — Cấu hình Supabase (tùy chọn)

Dự án đã được cấu hình sẵn với tài khoản Supabase demo. Nếu muốn dùng tài khoản Supabase riêng:

1. Tạo tài khoản tại: https://supabase.com
2. Tạo project mới
3. Tạo 2 bảng trong SQL Editor:

```sql
-- Bảng lưu thông số xe
CREATE TABLE obd_records (
  id            BIGSERIAL PRIMARY KEY,
  vin           TEXT,
  rpm           FLOAT,
  speed         FLOAT,
  coolant_temp  FLOAT,
  throttle_pos  FLOAT,
  battery_volt  FLOAT,
  timestamp     BIGINT,
  is_synced     INTEGER DEFAULT 1
);

-- Bảng lưu thông tin xe
CREATE TABLE vehicles (
  vin        TEXT PRIMARY KEY,
  first_seen BIGINT,
  last_seen  BIGINT,
  name       TEXT,
  plate      TEXT
);
```

4. Tắt Row Level Security (RLS) cho cả 2 bảng
5. Mở file `lib/core/constants/app_constants.dart` và cập nhật:

```dart
static const String supabaseUrl    = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

---

## Bước 8 — Kết nối điện thoại Android

1. Trên điện thoại Android, bật **Chế độ lập trình**:
   - Vào **Cài đặt** → **Giới thiệu về điện thoại**
   - Nhấn **Số hiệu bản dựng** 7 lần liên tiếp
   - Quay lại **Cài đặt** → **Tùy chọn nhà phát triển**
   - Bật **Gỡ lỗi USB**
2. Cắm điện thoại vào máy tính bằng cáp USB
3. Kiểm tra điện thoại đã được nhận diện:

```cmd
flutter devices
```

---

## Bước 9 — Chạy ứng dụng

```cmd
flutter run
```

Hoặc nhấn `F5` trong VS Code.

---

## Build file APK

Để tạo file APK cài đặt trên điện thoại:

```cmd
# APK chung cho tất cả thiết bị
flutter build apk --release

# APK riêng cho từng kiến trúc CPU (nhỏ hơn)
flutter build apk --split-per-abi
```

File APK được tạo tại:
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## Cách sử dụng ứng dụng

### Kết nối thiết bị ELM327

1. Ghép nối thiết bị ELM327 với điện thoại qua Bluetooth (mã PIN: **1234**)
2. Cắm thiết bị ELM327 vào cổng OBD-II dưới bảng táp-lô xe
3. Bật khóa điện xe (không cần nổ máy)
4. Mở ứng dụng → nhấn vào **thanh kết nối** ở đầu màn hình
5. Chọn thiết bị ELM327 từ danh sách

### Xem dữ liệu realtime

- Tab **Dashboard**: xem thông số xe theo thời gian thực
- Tab **Thống kê**: xem biểu đồ lịch sử 24h hoặc 7 ngày

### Hệ thống cảnh báo

| Màu | Mức độ | Ý nghĩa |
|-----|--------|---------|
| Cam | Warning | Cần chú ý |
| Đỏ nhấp nháy | Critical | Nguy hiểm — rung thiết bị |

---

## Cấu trúc dự án

```
lib/
├── core/
│   ├── constants/     ← Hằng số, theme
│   ├── errors/        ← Định nghĩa lỗi
│   └── utils/         ← Logger
├── domain/
│   └── entities/      ← Model dữ liệu, Warning Rules
├── data/
│   └── datasources/   ← Bluetooth, SQLite, Supabase, Warning Manager
└── presentation/
    ├── providers/     ← Riverpod providers
    ├── screens/       ← Dashboard, Statistics
    └── widgets/       ← ArcGauge, MetricCard, WarningOverlay
```

---

## Các lỗi thường gặp

### flutter doctor báo thiếu Android toolchain
```cmd
# Cài đặt Android licenses
flutter doctor --android-licenses
```

### Gradle build failed
```cmd
flutter clean
flutter pub get
flutter run
```

### Không tìm thấy thiết bị
```cmd
# Kiểm tra điện thoại đã bật USB Debugging chưa
flutter devices
```

### Lỗi kết nối Bluetooth
- Kiểm tra quyền Bluetooth trong Cài đặt → Ứng dụng → OBD2
- Đảm bảo đã ghép nối ELM327 trước khi mở app

---

## Thông tin đề tài

- **Tên đề tài:** Lập trình phần mềm đọc thông tin hệ thống điều khiển động cơ bằng thiết bị chẩn đoán dựa trên chip ELM327
- **Ngôn ngữ:** Dart
- **Framework:** Flutter
- **Nền tảng:** Android
- **Sinh viên thực hiện:** Nguyễn Viết Huy

---

## Liên hệ

Nếu gặp vấn đề khi cài đặt hoặc sử dụng, vui lòng tạo **Issue** trên GitHub:
https://github.com/huyhuyzxcvb-sudo/OBD2APP/issues
ENDOFFILE
echo "Done"
Output

Done

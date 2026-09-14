# 📸 Meme — Gen Z Social Expense Tracker & Visual Spending Diary

<p align="center">
  <img src="assets/images/logo.png" alt="Meme Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>"Every expense tells a story."</b><br/>
  Ứng dụng quản lý tài chính cá nhân & nhóm kết hợp mạng xã hội chia sẻ khoảnh khắc chi tiêu phong cách Locket dành cho Gen Z.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.0.0-blue.svg?style=for-the-badge&logo=semver&logoColor=white" alt="Version 2.0.0"/>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Cloud_Firestore-FFA000?style=for-the-badge&logo=firebase&logoColor=white" alt="Firestore"/>
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen?style=for-the-badge" alt="Platforms"/>
</p>

---

## 🌟 Tổng quan dự án (Project Overview)

Khác với các ứng dụng quản lý chi tiêu truyền thống vốn chỉ xoay quanh những con số khô khan và bảng biểu phức tạp, **Meme** biến việc ghi chép tài chính thành **nhật ký thị giác đầy cảm xúc**. Người dùng ghi lại từng khoản thu chi kèm hình ảnh/video ngắn thực tế, cảm xúc, vị trí check-in và chia sẻ cùng bạn bè, người thân hoặc nhóm quỹ chung.

---

## 🚀 Tính năng nổi bật đã hoàn thiện (Implemented Features)

> 📖 **Xem chi tiết toàn bộ tính năng & tài liệu kỹ thuật tại:** [`APP_FEATURES.md`](./APP_FEATURES.md)

### 📸 1. Trải nghiệm chụp ảnh & video chuẩn Locket
- **Camera tức thì (Viewfinder Square):** Chụp ảnh khung vuông với hỗ trợ camera trước/sau.
- **Tự động chống lật ảnh selfie (Mirroring WYSIWYG):** Ảnh và video quay bằng camera trước tự động xử lý lật gương chuẩn xác như lúc nhìn vào màn hình.
- **Quay video khoảnh khắc ngắn (5s):** Hỗ trợ quay video ngắn kèm trích xuất thumbnail đại diện tự động và bật/tắt tiếng.
- **Nhập chi tiêu siêu tốc bằng Giọng nói (Voice Expense AI Parser):** Tự động bóc tách số tiền, danh mục, hành động bằng xử lý ngôn ngữ tự nhiên (NLP rule-based đa ngữ Anh/Việt: *"ăn bún bò 35k"*, *"đổ xăng 50 cành"*, *"lương 15 củ"*...).
- **Đính kèm vị trí GPS:** Gắn vị trí thực tế vào từng giao dịch kèm Reverse Geocoding.

### 👥 2. Tài chính xã hội & Quỹ nhóm (Social Finance & Group Fund)
- **Quyền riêng tư linh hoạt:** Tùy chọn chia sẻ *Riêng tư (Private)*, *Mọi người (Friends)*, *Bạn thân (Close Friends)* hoặc *Nhóm quỹ (Group)*.
- **Quản lý Quỹ nhóm (Group Wallet):** Theo dõi số dư chung, nạp tiền vào quỹ, chi tiêu từ quỹ nhóm, kiểm tra lịch sử đóng góp giữa các thành viên.
- **Bảng tin khoảnh khắc (Feed):** Xem luồng chi tiêu của bạn bè, thả tim, gửi reaction emoji và bình luận tương tác thời gian thực.
- **Gắn thẻ bạn bè (@mention):** Gắn thẻ bạn bè vào giao dịch với cơ chế kiểm soát quyền riêng tư chặt chẽ.
- **Nhắn tin trực tiếp & Nhóm (Chat System):** Trò chuyện 1-1 và trò chuyện nhóm với chủ đề bong bóng chat sinh động, xem ảnh/video trực tiếp.

### 📅 3. Lịch kỷ niệm dạng sợi chỉ (Threaded Polaroid Calendar)
- **Lưới lịch nối tiếp độc đáo:** Hiển thị ảnh kỷ niệm từng ngày với các sợi dây nét đứt nghệ thuật uốn lượn riêng cho từng tháng.
- **Viền phân biệt Thu / Chi trực quan:** Viền ảnh màu đỏ cho **Chi tiêu (Expense)** và viền màu xanh lá cho **Thu nhập (Income)**.
- **Mốc kỷ niệm đầu tiên (Milestone Header):** Tự động tính toán và vinh danh ngày tạo tài khoản hoặc ngày gửi Meme đầu tiên ở đỉnh lịch (*"Meme đầu tiên của bạn đã được gửi vào ngày..."*).
- **Xem chi tiết ngày (Day Detail Sheet):** Mở xem toàn bộ danh sách giao dịch trong ngày với giao diện lướt thẻ mượt mà.

### 📊 4. Thống kê thông minh & Bản đồ chi tiêu (Analytics & Map)
- **Biểu đồ trực quan:** Thống kê thu chi theo Ngày, Tuần, Tháng, Năm bằng biểu đồ tương tác (`fl_chart`).
- **Phân bổ danh mục:** Tỷ lệ % chi tiêu từng danh mục kèm danh sách giao dịch chi tiết.
- **Bản đồ chi tiêu (Spending Map):** Hiển thị toàn bộ các điểm bạn đã tiêu tiền trên bản đồ thực tế với bản đồ nhiệt/cụm ghim sinh động.
- **Quản lý ngân sách đa kỳ hạn (Budget System):** Thiết lập hạn mức ngân sách (Tuần, Tháng, Năm), cảnh báo vượt hạn mức và chu kỳ tự động.

### 🎮 5. Gamification & Cá nhân hóa
- **Chuỗi ngày chi tiêu (Spending Streak):** Duy trì chuỗi ngày ghi chép liên tục, mở khóa các danh hiệu và huy hiệu thành tích độc quyền.
- **Daily Moments:** Lời chào, biểu tượng cảm xúc và thông điệp thay đổi thông minh theo khung giờ và tình hình chi tiêu trong ngày.
- **Meme Rewind (Story nhìn lại tài chính):** Trải nghiệm xem lại tổng kết chi tiêu tháng/năm dạng Story chuyển động bắt mắt (tương tự Spotify Wrapped).
- **Đa ngôn ngữ & Tiền tệ:** Chuyển đổi linh hoạt giữa Tiếng Việt (VNĐ) và Tiếng Anh (USD, EUR, v.v.).

---

## 🔮 Lộ trình phát triển trong tương lai (Future Roadmap & Custom AI Integration)

Trong các phiên bản tiếp theo, **Meme** sẽ tích hợp hệ thống **Trí tuệ nhân tạo tự phát triển (Custom-built In-house AI & Computer Vision)** nhằm tối ưu hóa toàn diện trải nghiệm người dùng:

- [ ] 🤖 **AI Auto-Categorization cho ảnh thông thường (Smart Vision Classification):**
  Mô hình AI thị giác tự huấn luyện (Custom Vision Model) tự động nhận diện chủ thể và ngữ cảnh trong mọi bức ảnh chụp/tải lên (đồ ăn, trà sữa, mua sắm quần áo, đồ công nghệ, du lịch, xăng xe...) để **tự động gợi ý và chọn danh mục chi tiêu (Category)** chính xác mà người dùng không cần chọn thủ công.
- [ ] 🧾 **AI Quét hoá đơn & Tự động phân tích danh mục (Smart Receipt OCR & Auto-Categorization):**
  Mô hình OCR & Document AI tự xây dựng giúp quét hóa đơn/biên lai mua sắm bằng camera, tự động trích xuất số tiền, tên điểm bán, thời gian, đồng thời **phân tích chi tiết các mặt hàng trên hóa đơn để tự động điền và chọn danh mục chi tiêu** tương ứng chỉ trong 1 chạm.
- [ ] ✨ **AI Smart Caption Generator (Tự động sinh caption vui nhộn):**
  Tự động phân tích biểu cảm, sự vật trong ảnh để sinh ra các câu caption dí dỏm, hài hước, bắt trend chuẩn phong cách Gen Z và meme văn hóa mạng.
- [ ] 🧠 **AI Financial Advisor & Spending Roast:**
  Hệ thống AI tự phân tích hành vi và thói quen tài chính định kỳ, đưa ra lời khuyên tối ưu chi tiêu hoặc kích hoạt chế độ "Roast" trêu đùa khi phát hiện chi tiêu vượt định mức.
- [ ] 🎙️ **Conversational AI Assistant (Trợ lý tài chính đàm thoại):**
  Tương tác và hỏi đáp trực tiếp bằng ngôn ngữ tự nhiên (*"Tháng này mình đã chi bao nhiêu cho trà sữa?"*, *"Hôm nay còn bao nhiêu tiền để ăn tối?"*).
- [ ] 🧩 **Interactive iOS & Android Widgets:**
  Widget tương tác trực tiếp trên màn hình chính, xem nhanh khoảnh khắc Meme mới nhất từ bạn bè và theo dõi hạn mức tài chính trong ngày.


---

## 🛠️ Công nghệ & Kiến trúc (Tech Stack)

### Frontend
- **Framework:** [Flutter](https://flutter.dev/) (Channel stable, Dart 3.x)
- **State Management:** `Provider`
- **Navigation & Routing:** Named Routes & Modal Bottom Sheets
- **Graphics & Animation:** Canvas CustomPainter, `fl_chart`, `flutter_map`, `cached_network_image`
- **Media Processing:** `image` (4.x), `video_player`, `video_thumbnail`, `camera`

### Backend & Cloud Services
- **Authentication:** Firebase Auth (Email/Password, Google Sign-In)
- **Database:** Cloud Firestore (NoSQL, Real-time streams & Collection Group queries)
- **Storage / Media:** Locket Media Upload CDN & Firebase Storage
- **Push Notifications:** Firebase Cloud Messaging (FCM) & `flutter_local_notifications`

---

## 📂 Cấu trúc thư mục (Project Structure)

```text
lib/
├── core/
│   ├── constants/       # Màu sắc (AppColors), kích thước, text styles, streak milestones
│   ├── extensions/      # Localization extensions, date/time helpers
│   ├── routes/          # App route names & route generator
│   ├── services/        # Natural language expense parser, speech-to-text, GPS location
│   ├── theme/           # AppTheme, CameraTheme
│   └── utils/           # Currency formatters, input formatters
├── data/
│   ├── datasources/     # Remote & local data sources
│   ├── models/          # TransactionModel, UserModel, BudgetModel, GroupModel...
│   └── repositories/    # TransactionRepository, UserRepository, AuthRepository...
├── features/
│   ├── auth/            # Đăng ký, đăng nhập, quên mật khẩu
│   ├── budget/          # Quản lý ngân sách, chu kỳ chi tiêu
│   ├── capture/         # Camera, quay video, nhận diện giọng nói, xem trước
│   ├── chat/            # Nhắn tin 1-1, chat nhóm, tùy chỉnh bong bóng chat
│   ├── feed/            # Bảng tin khoảnh khắc bạn bè, reaction, comment
│   ├── home/            # Dashboard chính, Lịch kỷ niệm, chi tiết ngày, Daily moments
│   ├── profile/         # Hồ sơ cá nhân, bạn bè, nhóm quỹ, cài đặt danh mục
│   ├── rewind/          # Story nhìn lại chi tiêu tháng / năm
│   └── stats/           # Biểu đồ phân tích tài chính, bản đồ chi tiêu
├── l10n/                # Hỗ trợ song ngữ (app_vi.arb, app_en.arb)
└── main.dart            # Entry point ứng dụng
```

---

## 💻 Hướng dẫn cài đặt & Chạy ứng dụng (Getting Started)

### 1. Yêu cầu môi trường
- Flutter SDK `>= 3.22.0`
- Dart SDK `>= 3.4.0`
- Android Studio / VS Code với Flutter & Dart Extension
- Thiết bị thật hoặc giả lập Android / iOS

### 2. Cài đặt

```bash
# Clone repository
git clone https://github.com/duyvinh09/meme-app.git

# Di chuyển vào thư mục dự án
cd memeapp

# Tải các packages phụ thuộc
flutter pub get

# Sinh mã bản địa hóa (L10n)
flutter gen-l10n

# Chạy ứng dụng
flutter run
```

---

## 📄 Bản quyền (License)

Dự án được xây dựng với mục đích học tập, nghiên cứu và phát triển sản phẩm cá nhân.  
*Phát triển với ❤️ bằng Flutter & Firebase.*

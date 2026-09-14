# 📱 TÀI LIỆU TỔNG HỢP TOÀN BỘ TÍNH NĂNG ỨNG DỤNG MEME (V2.0)
> **Meme — Gen Z Social Expense Tracker & Visual Spending Diary**  
> *"Every expense tells a story."*  
> Mô hình ứng dụng kết hợp đột phá giữa **Quản lý tài chính cá nhân/nhóm** và **Mạng xã hội chia sẻ khoảnh khắc chi tiêu phong cách Locket**.

---

## 📑 MỤC LỤC TỔNG QUAN

1. [Xác thực & Quản lý Tài khoản (Authentication & Account)](#1-xác-thực--quản-lý-tài-khoản)
2. [Ghi nhận Thu / Chi & Nhập liệu Giọng nói (Smart Expense Input & Voice Parser)](#2-ghi-nhận-thu--chi--nhập-liệu-giọng-nói)
3. [Camera Khoảnh khắc & Xử lý Đa phương tiện (Locket Camera & Media Studio)](#3-camera-khoảnh-khắc--xử-lý-đa-phương-tiện)
4. [Lịch Kỷ niệm Kèm Viền Thu/Chi & Mốc Milestone (Threaded Polaroid Calendar)](#4-lịch-kỷ-niệm-kèm-viền-thuchi--mốc-milestone)
5. [Bảng tin Tương tác Xã hội & Cảm xúc Bay (Social Feed & Flying Reactions)](#5-bảng-tin-tương-tác-xã-hội--cảm-xúc-bay)
6. [Hệ thống Trò chuyện Thời gian thực & Quyền riêng tư (Realtime Chat & Privacy Presence)](#6-hệ-thống-trò-chuyện-thời-gian-thực--quyền-riêng-tư)
7. [Mạng lưới Bạn bè, Gắn thẻ Scoped & Quản lý Quỹ nhóm (Friends & Group Fund)](#7-mạng-lưới-bạn-bè-gắn-thẻ-scoped--quản-lý-quỹ-nhóm)
8. [Quản lý Ngân sách & Cảnh báo Hạn mức (Dynamic Budgeting System)](#8-quản-lý-ngân-sách--cảnh-báo-hạn-mức)
9. [Thống kê, Báo cáo & Bản đồ Chi tiêu Tương tác (Analytics & Interactive Map)](#9-thống-kê-báo-cáo--bản-đồ-chi-tiêu-tương-tác)
10. [Tổng kết Chi tiêu dạng Story Chuyển động (Meme Rewind / Financial Wrapped)](#10-tổng-kết-chi-tiêu-dạng-story-chuyển-động-meme-rewind)
11. [Cá nhân hóa, Chuỗi Streak & Tùy biến Giao diện (Gamification & Custom Themes)](#11-cá-nhân-hóa-chuỗi-streak--tùy-biến-giao-diện)
12. [Hệ thống Đa ngôn ngữ, Thông báo Kép & Đa nền tảng (System & Dual Notifications)](#12-hệ-thống-đa-ngôn-ngữ-thông-báo-kép--đa-nền-tảng)
13. [Lộ trình Phát triển AI Tự Xây dựng (Future Custom-built In-house AI)](#13-lộ-trình-phát-triển-ai-tự-xây-dựng-future-roadmap)

---

## 1. XÁC THỰC & QUẢN LÝ TÀI KHOẢN

- **Đăng ký tài khoản (Register)**:
  - Đăng ký qua Email & Mật khẩu hoặc Đăng nhập nhanh với Google Sign-In.
  - Thiết lập thông tin cá nhân ban đầu: Tên hiển thị (Display Name), `@username` duy nhất trên hệ thống, ảnh đại diện và đơn vị tiền tệ mặc định.
  - Tự động đồng bộ hồ sơ lên Firestore (`/users/{userId}`).
- **Đăng nhập & Phiên làm việc (Login & Sessions)**:
  - Đăng nhập bảo mật qua Firebase Authentication.
  - Tự động ghi nhớ phiên đăng nhập và tự làm mới token.
- **Quên mật khẩu & Khôi phục (Forgot Password)**:
  - Gửi email đặt lại mật khẩu an toàn theo tiêu chuẩn quốc tế.
- **Quản lý Hồ sơ Cá nhân (Profile Management)**:
  - Cập nhật Tên hiển thị, Username, Tiểu sử / Trạng thái (Bio / Note).
  - Tải lên ảnh đại diện chất lượng cao với cơ chế xoay vòng CDN đa kênh.
- **Kiểm soát Trạng thái Hoạt động Thời gian thực (Online Presence Control)**:
  - Tùy chọn 3 cấp độ: **Công khai (Public)**, **Bạn bè (Friends)**, hoặc **Tắt (None)**.
  - Hiển thị chấm xanh thời gian thực khi đang hoạt động trong danh sách Chat, Cuộc trò chuyện, và Danh sách Bạn bè.
  - **Chế độ công khai khi tìm kiếm**: Người khác tìm kiếm `@username` sẽ thấy chấm xanh nếu chủ tài khoản đang online và bật chế độ Public.
- **Đăng xuất & Quyền riêng tư xóa tài khoản (GDPR Compliant)**:
  - Đăng xuất an toàn, thu hồi FCM token trên thiết bị.
  - Tính năng **Xóa vĩnh viễn tài khoản (Delete Account)**: Xóa sạch toàn bộ giao dịch, bạn bè, nhóm và dữ liệu media liên quan.

---

## 2. GHI NHẬN THU / CHI & NHẬP LIỆU GIỌNG NÓI

- **Ghi chép Thu / Chi siêu tốc (Income & Expense Tracking)**:
  - Bàn phím số tích hợp bộ định dạng tiền tệ thông minh (Money Input Formatter) hiển thị dấu phân cách hàng nghìn theo thời gian thực.
  - Hỗ trợ đầy đủ phân loại: **Chi tiêu (Expense)** và **Thu nhập (Income)**.
  - Chọn danh mục chi tiêu trực quan từ danh sách biểu tượng đa màu sắc (Ăn uống, Mua sắm, Di chuyển, Hóa đơn, Nhà cửa, Lương, Thưởng...).
  - Nhập Chú thích (Caption) và Ghi chú phụ (Notes).
  - Tùy chỉnh linh hoạt Ngày & Giờ giao dịch.
- **Nhập chi tiêu bằng Giọng nói (Speech-to-Text & Expense Parser Engine)**:
  - Nhận diện giọng nói tiếng Việt / tiếng Anh bằng micro 1 chạm.
  - **Bộ phân tích cú pháp ngôn ngữ tự nhiên độc quyền (`ExpenseParser`)**:
    - Nhận diện linh hoạt từ ngữ chỉ số tiền: *"45 nghìn"*, *"50k"*, *"150 cành"*, *"1 củ rưỡi"*, *"hai trăm rưỡi"*, *"1 tỷ 200 triệu"*, *"trăm tỷ"*, v.v.
    - Tự động bóc tách từ khóa hành động để gán Danh mục chính xác (*"ăn phở"* -> Ăn uống, *"đổ xăng"* -> Di chuyển, *"mua áo"* -> Mua sắm, *"nhận lương"* -> Thu nhập).
    - Tự động làm sạch chú thích và điền tự động vào form giao dịch.
- **Đính kèm Vị trí Địa lý (GPS Reverse Geocoding)**:
  - Tự động xác định tọa độ GPS chính xác tại thời điểm giao dịch.
  - Chuyển đổi tọa độ thành tên đường, quận/huyện, thành phố hiển thị trực quan.
- **Gắn thẻ Bạn bè đa cấp độ quyền riêng tư (Scoped Mention Tagging)**:
  - Gõ `@` để mở danh sách gợi ý bạn bè thông minh.
  - Bộ lọc gợi ý giới hạn an toàn theo quyền riêng tư của bài viết:
    - *Mọi người (Friends)*: Chỉ gợi ý `Friends(A)`.
    - *Bạn thân (Close Friends)*: Chỉ gợi ý `CloseFriends(A)`.
    - *Nhóm quỹ (Group)*: Giao thoa `Members(Group) ∩ Friends(A)` (loại bỏ hoàn toàn người lạ trong nhóm).
    - *Riêng tư (Only Me)*: Vô hiệu hóa gắn thẻ.
  - **Tương tác khi bấm vào `@username` trên bài viết**:
    - Bấm vào chính mình: Hiển thị badge *"Bạn (chính mình)"*.
    - Bấm vào người đã kết bạn: Mở nút *"Nhắn tin"* trò chuyện ngay.
    - Bấm vào người chưa kết bạn: Mở nút *"Thêm bạn bè"* / *"Đã gửi lời mời"*.
- **Quyền riêng tư bài viết (Granular Privacy Settings)**:
  - `friends` (**Mọi người / Bạn bè**): Chia sẻ với toàn bộ bạn bè 2 chiều đã kết bạn.
  - `close_friends` (**Bạn thân ⭐**): Chỉ bạn bè nằm trong danh sách Bạn thân mới xem được.
  - `group` (**Nhóm 👥**): Chỉ các thành viên trong nhóm quỹ tương ứng xem được.
  - `private` (**Chỉ mình tôi 🔒**): Lưu trữ sổ thu chi nội bộ cá nhân, không đăng lên Feed.

---

## 3. CAMERA KHOẢNH KHẮC & XỬ LÝ ĐA PHƯƠNG TIỆN

- **Camera Tức thì Chuẩn Locket (Square Viewfinder)**:
  - Khung ngắm chụp ảnh vuông 1:1 mang đậm phong cách Locket hiện đại.
  - Chuyển đổi mượt mà giữa Camera Trước (Selfie) và Camera Sau.
  - Bật/tắt đèn Flash trợ sáng linh hoạt.
- **Tự động Chống Lật Ảnh Selfie (WYSIWYG Mirroring Engine)**:
  - Xử lý lật gương ảnh và video camera trước theo thời gian thực.
  - Cam kết ảnh/video sau khi lưu giống hệt 100% hình ảnh người dùng nhìn thấy qua khung ngắm lúc chụp (What You See Is What You Get).
- **Quay Video Khoảnh khắc Ngắn (5s Quick Video Capture)**:
  - Giữ nút chụp để quay video khoảnh khắc chi tiêu ngắn (5 giây).
  - Tùy chọn Bật/Tắt thu âm thanh khi quay.
  - Tự động trích xuất Thumbnail đại diện cho video để tải siêu tốc trên Feed và Lịch.
- **Bộ sưu tập Chủ đề Giao diện Camera (Camera Themes)**:
  - Tùy biến khung viền và nút chụp theo nhiều phong cách độc đáo: *Classic, Modern, Cyberpunk, Cute Pastel, Neon Night, Vintage Film...*
- **Hạ tầng Tải lên Đa phương tiện Tối ưu (Dual Media Pipeline)**:
  - Hỗ trợ tải lên ảnh/video qua dịch vụ Locket CDN API đa tài khoản xoay vòng.
  - Tích hợp Cloudinary Media Storage dự phòng đảm bảo tốc độ tải media luôn ổn định.

---

## 4. LỊCH KỶ NIỆM KÈM VIỀN THU/CHI & MỐC MILESTONE

- **Lịch Polaroid Dạng Sợi Chỉ Nối Tiếp (Threaded Polaroid Calendar Grid)**:
  - Lưới lịch tháng hiển thị từng ngày dưới dạng nhãn dán ảnh (Polaroid Sticker Thumbnail).
  - Đường nét đứt nghệ thuật uốn lượn liên kết các ngày có phát sinh khoảnh khắc giao dịch trong tháng.
- **Viền Nhãn Dán Phân Biệt Thu / Chi Trực Quan**:
  - 🔴 **Viền Đỏ**: Biểu thị ngày có giao dịch **Chi tiêu (Expense)**.
  - 🟢 **Viền Xanh Lá**: Biểu thị ngày có giao dịch **Thu nhập (Income)**.
- **Mốc Kỷ Niệm Đầu Tiên (Milestone Header Banner)**:
  - Tự động phân tích lịch sử tài khoản và hiển thị banner vinh danh tại tháng mở tài khoản / gửi giao dịch đầu tiên:  
    *"Khoảnh khắc Meme đầu tiên của bạn đã được ghi lại vào ngày DD/MM/YYYY"* (kèm bản địa hóa tiếng Anh: *"Your first Meme was sent on..."*).
- **Xem Chi tiết Ngày (Day Detail Screen & Multi-Moment Viewer)**:
  - Bấm vào ngày bất kỳ trên lịch để mở danh sách chi tiết các khoản thu chi trong ngày.
  - Lướt xem toàn màn hình từng bức ảnh/video khoảnh khắc với đầy đủ chú thích, số tiền và địa điểm.
  - **Nút Chụp Nhanh trên Header**: Bấm nút Camera ngay tại thanh công cụ trên cùng để ghi nhận ngay giao dịch mới mà không cần thoát ra màn hình chính.

---

## 5. BẢNG TIN TƯƠNG TÁC XÃ HỘI & CẢM XÚC BAY

- **Lướt Bảng Tin Khoảnh khắc (Interactive Social Feed)**:
  - Trải nghiệm xem bài viết mượt mà dạng thẻ khoảnh khắc kèm ảnh/video sắc nét.
  - Hiển thị đầy đủ thông tin: Người đăng, Khung Avatar động, Thời gian tương đối, Số tiền & Danh mục, Địa điểm check-in, Chú thích kèm thẻ bạn bè.
- **Thả Cảm xúc Bay Động (Flying Reactions Animator)**:
  - Thanh phản hồi nhanh với bộ Emoji sinh động (❤️, 😂, 😮, 🔥, 💸, 👍, v.v.).
  - Hiệu ứng Emoji bay lơ lửng toàn màn hình (Flying Reaction Particle Effect) khi bạn bè tương tác.
  - Thanh Post Activity Bar hiển thị avatar của những người bạn vừa thả cảm xúc gần nhất.
- **Theo dõi Hoạt động Bài viết & Lượt xem (Post Activity & View Tracker)**:
  - Ghi nhận lượt xem thông minh (chỉ kích hoạt khi người dùng đang mở tab Bảng tin và dừng tại bài viết).
  - Bottom Sheet tổng hợp danh sách người đã xem, người đã thả tim kèm mốc thời gian chi tiết.
- **Banner Nổi Báo Bài Đăng Mới (Floating New Post Alert)**:
  - Tự động xuất hiện nút nổi khi có bài đăng mới từ bạn bè, bấm vào để tự cuộn mượt mà lên đầu trang.

---

## 6. HỆ THỐNG TRÒ CHUYỆN THỜI GIAN THỰC & QUYỀN RIÊNG TƯ

- **Trò chuyện 1-1 & Trò chuyện Nhóm (Direct & Group Realtime Chat)**:
  - Nhắn tin văn bản thời gian thực thông qua Firestore Streams cực nhanh.
  - Chia sẻ trực tiếp giao dịch hoặc khoảnh khắc chi tiêu vào cuộc hội thoại.
- **Tương tác Tin nhắn Nâng cao**:
  - **Thả Emoji Reaction trực tiếp lên từng tin nhắn**: Giữ tin nhắn để thả cảm xúc nhanh.
  - **Thu hồi tin nhắn (Unsend / Recall)**: Xóa tin nhắn ở cả 2 phía.
  - **Xóa tin nhắn phía tôi (Delete for me)**: Ẩn tin nhắn chỉ ở thiết bị của mình.
  - **Chỉ báo đang nhập tin (Real-time Typing Indicator)**.
  - **Tự động lưu bản nháp (Chat Drafts)**: Giữ nguyên nội dung đang gõ dở khi thoát màn hình.
- **Bộ sưu tập Chủ đề Bong bóng Chat (Chat Bubble Themes)**:
  - Nhiều phong cách bong bóng chat đẹp mắt: *Default, Sunset Glow, Deep Ocean, Cyberpunk, Lavender, Mint Fresh, Neon, Matcha...*
- **Quản trị Nhóm Chat Toàn diện**:
  - Tạo nhóm chat mới, đổi tên nhóm, thay đổi ảnh đại diện nhóm.
  - Mời thêm thành viên từ danh bạ bạn bè.
  - Rời nhóm (Self Leave) và Quyền quản trị viên xóa thành viên (Kick Member).

---

## 7. MẠNG LƯỚI BẠN BÈ, GẮN THẺ SCOPED & QUẢN LÝ QUỸ NHÓM

- **Tìm kiếm & Kết bạn (Friends Discovery)**:
  - Tìm kiếm chính xác người dùng qua `@username`.
  - Hiển thị chấm xanh online và khung avatar trực tiếp trên kết quả tìm kiếm nếu người dùng đang hoạt động công khai.
- **Quản lý Lời mời Kết bạn (Friend Requests Center)**:
  - Phân tách 2 tab rõ ràng: **Lời mời đã nhận** và **Lời mời đã gửi**.
  - Hiển thị trạng thái hoạt động và avatar người dùng trên cả hai tab.
  - Chấp nhận, từ chối hoặc thu hồi lời mời kết bạn tức thì.
- **Danh sách Bạn bè & Đánh dấu Bạn thân (Close Friends ⭐)**:
  - Danh bạ bạn bè trực quan với tìm kiếm nhanh.
  - Đánh dấu / Hủy đánh dấu "Bạn thân" (⭐) để phân cấp quyền riêng tư khi đăng bài.
  - Đặt **Biệt danh cá nhân (Custom Nickname)** cho bạn bè.
- **Quản lý Quỹ nhóm & Chi tiêu Chung (Group Fund & Wallet)**:
  - Tạo nhóm chi tiêu chung (Gia đình, Bạn cùng phòng, Quỹ du lịch, Hội bạn thân...).
  - Đặt hạn mức mục tiêu quỹ nhóm (Fund Target Goal) kèm thanh tiến độ trực quan.
  - Thống kê tỷ lệ đóng góp của từng thành viên, số tiền đã chi, số dư quỹ còn lại và phân bổ danh mục chi tiêu của nhóm.
  - Tự động ghi nhận giao dịch chi từ quỹ hoặc thành viên nạp tiền vào quỹ.

---

## 8. QUẢN LÝ NGÂN SÁCH & CẢNH BÁO HẠN MỨC

- **Thiết lập Ngân sách theo Danh mục (Category Budgets)**:
  - Đặt hạn mức chi tiêu chi tiết cho từng nhóm danh mục (Ăn uống, Giải trí, Mua sắm, v.v.).
  - Gán icon đại diện và mã màu sắc riêng biệt cho từng hạn mức ngân sách.
- **Chu kỳ Ngân sách Tự động (Flexible Budget Cycles)**:
  - Tự động tính toán theo chu kỳ hàng tháng, hàng tuần hoặc mốc thời gian tùy chỉnh.
  - Tự động cộng dồn số tiền đã chi khi có giao dịch mới.
  - Tự động hoàn lại hạn mức khi người dùng chỉnh sửa hoặc xóa giao dịch.
- **Cảnh báo Vượt Hạn mức Thông minh**:
  - Thanh tiến độ (Progress Bar) đổi màu trực quan: Xanh (An toàn) ➔ Vàng (Cảnh báo >80%) ➔ Đỏ (Vượt 100% ngân sách).
- **Lịch sử Ngân sách (Budget History)**:
  - Lưu trữ và tra cứu lịch sử chi tiêu của các chu kỳ trước để đánh giá năng lực tiết kiệm.

---

## 9. THỐNG KÊ, BÁO CÁO & BẢN ĐỒ CHI TIÊU TƯƠNG TÁC

- **Báo cáo Thu - Chi Tổng quan**:
  - Thống kê tổng số tiền Đã Thu, Đã Chi và Số dư khả dụng trong kỳ.
  - Biểu đồ tròn phân bổ tỷ trọng chi tiêu từng danh mục bằng `fl_chart`.
- **Phân tích Danh mục Chi tiết (Category Detail Screen)**:
  - Xem chi tiết từng khoản chi của danh mục được chọn trong kỳ.
  - Tính toán số tiền trung bình mỗi ngày và danh sách toàn bộ ảnh/giao dịch thuộc danh mục đó.
- **Bản đồ Giao dịch Tương tác (Interactive Transaction Map)**:
  - Hiển thị toàn bộ các điểm chi tiêu của người dùng trên bản đồ số OpenStreetMap (`flutter_map`).
  - Gom cụm điểm chi tiêu thông minh (Map Marker Clustering) kèm tóm tắt tổng số tiền và số lượng giao dịch tại từng khu vực.
  - Bấm vào ghim trên bản đồ để mở xem khoảnh khắc và hóa đơn chi tiêu tại địa điểm đó.

---

## 10. TỔNG KẾT CHI TIÊU DẠNG STORY CHUYỂN ĐỘNG (MEME REWIND)

> *Trải nghiệm nhìn lại hành trình tài chính sống động lấy cảm hứng từ Spotify Wrapped & Instagram Stories.*

- **Lựa chọn Chu kỳ Tổng kết**: Tuần này (This Week), Tháng này (This Month), Năm nay (This Year), hoặc Tùy chỉnh (Custom Range).
- **8 Slide Chuyển động Mượt mà**:
  1. **Overview Story**: Tổng quan số tiền đã chi, số lượng giao dịch và số ngày hoạt động.
  2. **Top Spending Story**: Vinh danh khoản chi tiêu lớn nhất trong chu kỳ kèm hình ảnh thực tế.
  3. **Biggest Day Story**: Ngày bạn "vung tay quá trán" nhiều nhất và lý do chi tiêu.
  4. **Category Breakdown Story**: Danh mục chiếm tỷ trọng ngân sách cao nhất.
  5. **Comparison Story**: So sánh mức tăng/giảm chi tiêu so với chu kỳ liền trước.
  6. **Streak Story**: Thống kê chuỗi ngày kiên trì ghi chép tài chính.
  7. **Moments Story**: Trình chiếu các bức ảnh/khoảnh khắc chi tiêu đẹp nhất.
  8. **Summary Story**: Thẻ tổng kết thành tích tài chính sẵn sàng chụp ảnh màn hình để chia sẻ lên mạng xã hội.
- **Tương tác Cảm ứng**: Chạm giữ để tạm dừng, vuốt trái/phải để chuyển slide, thanh tiến độ phân đoạn tự động chạy.

---

## 11. CÁ NHÂN HÓA, CHUỖI STREAK & TÙY BIẾN GIAO DIỆN

- **Hệ thống Chuỗi Ngày Ghi Chép (Spending Streak)**:
  - Đếm chuỗi ngày ghi chép liên tục (Current Streak) và Kỷ lục chuỗi cao nhất (Best Streak).
  - Thẻ Streak Card nổi bật tại trang chủ tạo động lực duy trì thói quen tài chính mỗi ngày.
  - Bảng chi tiết chuỗi ngày (Streak Detail Sheet) vinh danh các mốc thành tích.
- **Daily Moments & Lời Chào 12 Khung Giờ**:
  - Hệ thống lời chào và biểu tượng cảm xúc thay đổi thông minh theo 12 khung giờ trong ngày (Rạng sáng, Bình minh, Sáng sớm, Giờ đi làm, Buổi trưa, Buổi chiều, Hoàng hôn, Buổi tối, Đêm muộn...).
  - Thông điệp thay đổi linh hoạt theo tình hình chi tiêu và trạng thái ngân sách cá nhân.
- **Khung Avatar Độc quyền (Avatar Frames & Live Painters)**:
  - Tùy chọn nhiều khung Avatar cá tính: *Mặc định, Neon Glow, Rực lửa (Fire), Vàng hoàng gia (Golden), Cầu vồng (Rainbow), Gamer LED, Cyberpunk, Trái tim (Love)...*
- **Thay đổi Icon Ứng dụng ngoài Màn hình chính (Dynamic Launcher Icons)**:
  - Tùy biến biểu tượng app hiển thị trên màn hình điện thoại (Default Icon, Neon Icon, Classic Icon, Gold Icon...).
- **Tạo Danh mục Chi tiêu Tùy chỉnh (Custom User Categories)**:
  - Tự tạo danh mục mới theo nhu cầu cá nhân.
  - Chọn icon từ kho biểu tượng đa dạng và bảng mã màu sắc tùy ý.

---

## 12. HỆ THỐNG ĐA NGÔN NGỮ, THÔNG BÁO KÉP & ĐA NỀN TẢNG

- **Đa Ngôn ngữ Hoàn chỉnh (Localization)**:
  - Hỗ trợ đầy đủ **Tiếng Việt** và **Tiếng Anh (English)** trên toàn bộ giao diện, thông báo và hộp thoại.
  - Chuyển đổi ngôn ngữ tức thì trong Cài đặt mà không cần khởi động lại ứng dụng.
- **Đa Tiền tệ & Tự động Quy đổi Tỷ giá (Multi-Currency)**:
  - Hỗ trợ các đơn vị tiền tệ phổ biến: **VNĐ (₫)**, **USD ($)**, EUR, JPY...
  - Tự động cập nhật tỷ giá hối đoái để quy đổi tương đương.
- **Giao diện Sáng / Tối (Theme Mode)**:
  - Hỗ trợ Chế độ Sáng (Light Mode), Chế độ Tối (Dark Mode) và Chế độ Theo hệ thống thiết bị.
  - Thiết kế thích ứng tối ưu cho cả điện thoại màn hình nhỏ, màn hình lớn và máy tính bảng (iPad / Tablet).
- **Hệ thống Thông báo Kép (Dual Notifications)**:
  - **Firebase Cloud Messaging (FCM)**: Nhận thông báo đẩy từ xa khi có tin nhắn mới, lời mời kết bạn, bạn bè đăng khoảnh khắc.
  - **In-App Notification Host**: Banner thông báo nội bộ trượt từ trên xuống sống động khi người dùng đang mở ứng dụng.
- **Báo cáo Lỗi & Góp ý (Feedback & Support)**:
  - Trung tâm phản hồi ý kiến và báo lỗi trực tiếp tới đội ngũ phát triển.

---

## 13. LỘ TRÌNH PHÁT TRIỂN AI TỰ XÂY DỰNG (FUTURE ROADMAP)

Trong các phiên bản tiếp theo, **Meme** sẽ tích hợp hệ sinh thái **Trí tuệ nhân tạo tự phát triển (Custom-built In-house AI Models & Computer Vision)**:

- [ ] 🤖 **AI Auto-Categorization cho ảnh thông thường:**
  Mô hình AI thị giác tự huấn luyện (In-house Custom Vision Model) tự động nhận diện chủ thể và ngữ cảnh trong mọi bức ảnh chụp/tải lên (đồ ăn, trà sữa, quần áo, công nghệ, xăng xe, du lịch...) để **tự động gợi ý và chọn danh mục chi tiêu (Category)** chính xác mà không cần chọn thủ công.
- [ ] 🧾 **AI Quét hóa đơn & Tự động phân tích danh mục (Smart Receipt OCR):**
  Mô hình Document OCR tự xây dựng giúp quét hóa đơn mua sắm bằng camera, tự động bóc tách số tiền, tên cửa hàng, ngày giờ và **phân tích chi tiết các mặt hàng để tự động điền form và chọn danh mục chi tiêu** chỉ trong 1 chạm.
- [ ] ✨ **AI Smart Caption Generator:**
  Tự động phân tích ngữ cảnh và cảm xúc trong ảnh để sinh caption dí dỏm, hài hước chuẩn phong cách Gen Z và meme văn hóa mạng.
- [ ] 🧠 **AI Financial Advisor & Spending Roast:**
  Trợ lý AI tự phân tích thói quen tài chính định kỳ, đưa ra lời khuyên tiết kiệm hoặc kích hoạt chế độ "Roast" trêu đùa khi chi tiêu vượt hạn mức.
- [ ] 🎙️ **Conversational AI Assistant:**
  Trò chuyện và hỏi đáp trực tiếp bằng ngôn ngữ tự nhiên để tra cứu chi tiêu (*"Tháng này mình đã tiêu hết bao nhiêu tiền cà phê?"*).
- [ ] 🧩 **Interactive iOS & Android Widgets:**
  Widget màn hình chính hiển thị nhanh ảnh Meme mới nhất từ bạn thân và số dư ngân sách trong ngày.

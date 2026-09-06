# TÀI LIỆU TỔNG HỢP TOÀN BỘ TÍNH NĂNG ỨNG DỤNG MEMEAPP (FINNSOCIAL)

> **Mô hình ứng dụng**: Ứng dụng Quản lý Tài chính Cá nhân kết hợp Mạng xã hội Chia sẻ Khoảnh khắc Chi tiêu *(Social Expense & Moment Tracking App — lấy cảm hứng từ sự kết hợp giữa Locket Widget và Money Lover / FinTech)*.

---

## MỤC LỤC TỔNG QUAN

1. [Xác thực & Quản lý Tài khoản (Authentication & Account)](#1-xác-thực--quản-lý-tài-khoản)
2. [Quản lý Giao dịch & Khoảnh khắc Chi tiêu (Transaction & Moments)](#2-quản-lý-giao-dịch--khoảnh-khắc-chi-tiêu)
3. [Bảng tin Tương tác Xã hội (Social Moments Feed)](#3-bảng-tin-tương-tác-xã-hội-social-feed)
4. [Hệ thống Trò chuyện & Nhắn tin (Realtime & Group Chat)](#4-hệ-thống-trò-chuyện--nhắn-tin-chat)
5. [Quản lý Ngân sách & Hạn mức Chi tiêu (Budgeting System)](#5-quản-lý-ngân-sách--hạn-mức-chi-tiêu)
6. [Thống kê, Báo cáo & Bản đồ Chi tiêu (Analytics & Map View)](#6-thống-kê-báo-cáo--bản-đồ-chi-tiêu)
7. [Tổng kết Chi tiêu dạng Story (Rewind Stories / Wrapped)](#7-tổng-kết-chi-tiêu-dạng-story-rewind)
8. [Mạng lưới Bạn bè & Nhóm bạn (Friends & Groups Network)](#8-mạng-lưới-bạn-bè--nhóm-bạn)
9. [Cá nhân hóa & Tùy biến Giao diện (Customization & Themes)](#9-cá-nhân-hóa--tùy-biến-giao-diện)
10. [Hệ thống & Cài đặt Ứng dụng (System, Localization & Settings)](#10-hệ-thống--cài-đặt-ứng-dụng)

---

## 1. XÁC THỰC & QUẢN LÝ TÀI KHOẢN

- **Đăng ký tài khoản (Register)**:
  - Đăng ký bằng Email & Mật khẩu.
  - Thiết lập thông tin ban đầu: Tên hiển thị (Display Name), Username (duy nhất), Tiền tệ mặc định.
  - Tự động đồng bộ hồ sơ lên Firestore (`/users/{userId}`).
- **Đăng nhập (Login)**:
  - Đăng nhập bảo mật qua Firebase Authentication.
  - Lưu phiên đăng nhập an toàn trên thiết bị.
- **Quên mật khẩu (Forgot Password)**:
  - Gửi email đặt lại mật khẩu bảo mật về hòm thư người dùng.
- **Quản lý Hồ sơ & Bảo mật tài khoản**:
  - Đổi Tên hiển thị, Username, Tiểu sử (User Note/Status).
  - Đổi Email đăng nhập tài khoản.
  - Trạng thái hoạt động thời gian thực (Online / Offline status, Last seen).
  - Cập nhật và thu hồi token thiết bị (FCM Device Tokens).
- **Đăng xuất & Xóa tài khoản vĩnh viễn (Account Deletion)**:
  - Đăng xuất an toàn, xóa token push trên thiết bị.
  - Xóa vĩnh viễn tài khoản kèm toàn bộ dữ liệu giao dịch, bạn bè theo tiêu chuẩn quyền riêng tư GDPR.

---

## 2. QUẢN LÝ GIAO DỊCH & KHOẢNH KHẮC CHI TIÊU

- **Ghi nhận Thu / Chi (Income & Expense Tracking)**:
  - Nhập số tiền với bộ định dạng tiền tệ thông minh theo thời gian thực (Money Input Formatter).
  - Phân loại Danh mục chi tiêu (Ăn uống, Mua sắm, Di chuyển, Hóa đơn, Lương, Thưởng, v.v.).
  - Ghi chú chi tiết (Notes) và Chú thích bài đăng (Captions).
  - Tùy chọn ngày giờ giao dịch linh hoạt.
- **Chụp ảnh & Quay video Khoảnh khắc (Locket-style Camera)**:
  - Tích hợp Camera chụp ảnh hoặc quay video ngắn trực tiếp lúc chi tiêu.
  - Hỗ trợ đổi Camera trước/sau, bật/tắt đèn Flash.
  - Tự động tạo Thumbnail cho video giúp tải nhanh trên giao diện.
  - Đa dạng chủ đề giao diện Camera (Camera Themes: Classic, Modern, Cyberpunk, Cute, Neon...).
- **Đính kèm Vị trí Địa lý (GPS Location Geocoding)**:
  - Tự động lấy tọa độ GPS chính xác khi ghi nhận giao dịch.
  - Tự động dịch ngược tọa độ sang địa chỉ/tên địa điểm hiển thị trực quan.
- **Gắn thẻ bạn bè (Tag Friends)**:
  - Gắn thẻ bạn bè cùng tham gia buổi ăn uống, chi tiêu.
- **Thiết lập Quyền riêng tư Giao dịch (Privacy Control)**:
  - `private` (Chỉ mình tôi): Lưu sổ thu chi cá nhân, không hiển thị lên Feed.
  - `friends` (Bạn bè): Chia sẻ khoảnh khắc cho toàn bộ danh sách bạn bè.
  - `close_friends` (Bạn thân): Chỉ chia sẻ cho những người được đánh dấu bạn thân.
  - `group` (Nhóm): Chia sẻ vào một nhóm bạn cụ thể.
- **Hạ tầng Tải lên Đa phương tiện Tối ưu**:
  - Hỗ trợ upload ảnh/video qua Locket API Service đa tài khoản xoay vòng.
  - Tích hợp Cloudinary Media Storage dự phòng.

---

## 3. BẢNG TIN TƯƠNG TÁC XÃ HỘI (SOCIAL FEED)

- **Lướt Bảng tin Khoảnh khắc (Interactive Social Feed)**:
  - Trải nghiệm xem bài viết mượt mà dạng thẻ khoảnh khắc kèm ảnh/video sắc nét.
  - Hiển thị đầy đủ thông tin: Người đăng, Avatar kèm khung, Thời gian đăng, Số tiền & Danh mục, Địa điểm, Chú thích.
- **Thả Cảm xúc Bay Động (Flying Reactions & Post Activity)**:
  - Thanh nhập cảm xúc nhanh với các Emoji sinh động (❤️, 😂, 😮, 🔥, 💸, 👍, v.v.).
  - Hiệu ứng Emoji bay lơ lửng toàn màn hình (Flying Reaction Animator) khi có người thả cảm xúc.
  - Thanh Post Activity Bar hiển thị avatar của những bạn bè đã tương tác gần nhất.
- **Theo dõi Lượt xem (Post Views Tracker)**:
  - Tự động ghi nhận lượt xem khi người dùng lướt qua bài đăng.
  - Sheet chi tiết danh sách bạn bè đã xem bài viết kèm mốc thời gian.
- **Banner Thông báo Bài đăng mới (New Post Floating Banner)**:
  - Tự động xuất hiện nút nổi khi bạn bè vừa đăng khoảnh khắc mới để người dùng bấm cuộn lên đầu xem ngay.

---

## 4. HỆ THỐNG TRÒ CHUYỆN & NHẮN TIN (CHAT)

- **Chat Trực tiếp 1-1 & Chat Nhóm (Direct & Group Conversations)**:
  - Nhắn tin văn bản thời gian thực qua Firestore Streams.
  - Chia sẻ trực tiếp bài đăng giao dịch/khoảnh khắc vào cuộc trò chuyện.
- **Tương tác Tin nhắn Nâng cao**:
  - **Thả Emoji Reaction trực tiếp lên từng tin nhắn** (Menu Action Overlay).
  - **Thu hồi tin nhắn (Unsend / Message Recall)** cho cả 2 phía.
  - **Xóa tin nhắn phía tôi (Delete for me)**.
  - **Chỉ báo đang nhập tin (Real-time Typing Indicator)**.
  - **Lưu bản nháp tin nhắn tự động (Chat Drafts)**: Không bị mất nội dung đang soạn khi chuyển màn hình.
  - **Đánh dấu Đã đọc / Chưa đọc (Read Receipts & Unread Badges)**.
- **Tùy biến Chủ đề Bong bóng Chat (Chat Bubble Themes)**:
  - Nhiều bộ theme bong bóng chat độc đáo: Default, Sunset, Ocean, Cyberpunk, Lavender, Mint, Neon, Matcha, v.v.
  - Bộ vẽ trang trí bong bóng riêng biệt (Custom Painters).
- **Quản lý Nhóm Chat Toàn diện**:
  - Tạo nhóm chat mới, đặt tên nhóm, đổi ảnh đại diện nhóm.
  - Thêm thành viên vào nhóm.
  - Thành viên tự rời nhóm (Self Leave).
  - Trưởng nhóm có quyền xóa thành viên (Kick Member).

---

## 5. QUẢN LÝ NGÂN SÁCH & HẠN MỨC CHI TIÊU

- **Thiết lập Ngân sách theo Danh mục (Category Budgets)**:
  - Đặt hạn mức chi tiêu cho từng danh mục (Ăn uống, Giải trí, Mua sắm...).
  - Thiết lập icon đại diện và mã màu sắc riêng biệt cho từng gói ngân sách.
- **Chu kỳ Ngân sách Linh hoạt (Budget Cycles)**:
  - Tự động tính toán theo chu kỳ hàng tháng hoặc mốc thời gian tùy chọn.
  - Tự động cập nhật số tiền đã chi khi có giao dịch mới phát sinh.
  - Tự động hoàn lại số dư ngân sách khi chỉnh sửa hoặc xóa giao dịch chi tiêu.
- **Cảnh báo Ngân sách Trực quan**:
  - Thanh tiến độ (Progress Bar) hiển thị tỷ lệ đã chi / hạn mức còn lại.
  - Đổi màu cảnh báo trực quan khi chi tiêu vượt ngưỡng an toàn hoặc vượt 100% ngân sách.
- **Lịch sử Chu kỳ Ngân sách (Budget History)**:
  - Lưu trữ và tra cứu lịch sử chi tiêu của các tháng/chu kỳ trước đó để so sánh hiệu quả tiết kiệm.

---

## 6. THỐNG KÊ, BÁO CÁO & BẢN ĐỒ CHI TIÊU

- **Báo cáo Thu - Chi Tổng quan**:
  - Thống kê tổng số tiền Đã Thu, Đã Chi và Số dư khả dụng trong kỳ.
  - Biểu đồ phân bổ tỷ trọng chi tiêu theo từng danh mục.
- **Phân tích Danh mục Chi tiết (Category Detail Screen)**:
  - Xem chi tiết từng khoản chi của danh mục được chọn trong kỳ.
  - Tính toán số tiền trung bình mỗi ngày và danh sách các giao dịch liên quan.
- **Bản đồ Giao dịch Tương tác (Interactive Transaction Map)**:
  - Hiển thị toàn bộ các điểm chi tiêu của người dùng trên bản đồ định vị vệ tinh / bản đồ số.
  - Gom cụm điểm chi tiêu (Map Clustering) thông minh kèm tóm tắt tổng số tiền và số lượng giao dịch tại từng địa điểm.
  - Bấm vào điểm ghim trên bản đồ để mở chi tiết giao dịch / khoảnh khắc đã chụp tại đó.
- **Hệ thống Chuỗi ngày Ghi chép (Streak System)**:
  - Đếm chuỗi ngày ghi chép chi tiêu liên tục (Current Streak) và Kỷ lục chuỗi cao nhất (Best Streak).
  - Thẻ Streak Card nổi bật tại trang chủ tạo động lực duy trì thói quen quản lý tài chính.
  - Sheet thống kê chi tiết chuỗi ngày (Streak Detail Sheet).

---

## 7. TỔNG KẾT CHI TIÊU DẠNG STORY (REWIND)

> *Tính năng tổng kết tài chính tương tác sinh động tương tự Spotify Wrapped / Instagram Stories.*

- **Lựa chọn Chu kỳ Tổng kết Đa dạng**:
  - Tuần này (This Week), Tháng này (This Month), Năm nay (This Year), hoặc Khoảng thời gian Tùy chỉnh (Custom Range).
- **Trải nghiệm Story Trực quan & Tự động chạy**:
  - **Overview Story**: Tổng quan số tiền đã chi, số lượng giao dịch và số ngày hoạt động.
  - **Top Spending Story**: Vinh danh khoản chi tiêu lớn nhất trong chu kỳ kèm hình ảnh khoảnh khắc.
  - **Biggest Day Story**: Ngày người dùng chi tiêu nhiều tiền nhất và lý do chi tiêu.
  - **Category Breakdown Story**: Danh mục chiếm nhiều ngân sách nhất trong kỳ.
  - **Comparison Story**: So sánh mức tăng/giảm chi tiêu so với chu kỳ trước đó.
  - **Streak Story**: Thống kê chuỗi ngày kiên trì ghi chép trong kỳ.
  - **Moments Story**: Bộ sưu tập trình chiếu các bức ảnh/khoảnh khắc đẹp nhất khi chi tiêu.
  - **Summary Story**: Thẻ tóm tắt toàn bộ thành tích tài chính để người dùng chụp màn hình chia sẻ lên mạng xã hội.

---

## 8. MẠNG LƯỚI BẠN BÈ & NHÓM BẠN

- **Tìm kiếm & Kết bạn (Add Friends)**:
  - Tìm kiếm người dùng khác thông qua Username chính xác.
  - Gửi lời mời kết bạn tức thì.
- **Quản lý Lời mời Kết bạn (Friend Requests)**:
  - Tab danh sách lời mời đã nhận và lời mời đã gửi.
  - Chấp nhận hoặc từ chối kết bạn với cập nhật quan hệ 2 chiều an toàn.
- **Danh sách Bạn bè & Bạn thân (Close Friends)**:
  - Xem danh sách toàn bộ bạn bè.
  - Đánh dấu / Hủy đánh dấu "Bạn thân" (Close Friend) để kiểm soát quyền xem bài đăng riêng tư.
  - Đặt Biệt danh tùy chỉnh (Custom Nickname) cho từng người bạn.
- **Nhóm Bạn bè (Groups)**:
  - Tạo các nhóm bạn (Gia đình, Bạn trọ, Nhóm du lịch, Đồng nghiệp...).
  - Quản lý danh sách nhóm và xem thành viên trong từng nhóm.

---

## 9. CÁ NHÂN HÓA & TÙY BIẾN GIAO DIỆN

- **Khung Avatar Độc quyền (Avatar Frames)**:
  - Tùy chọn nhiều khung Avatar cá tính: *Mặc định (Default), Neon Glow, Rực lửa (Fire), Vàng hoàng gia (Golden), Cầu vồng (Rainbow), Gamer LED, Cyberpunk, Trái tim (Love), v.v.*
  - Bộ vẽ tùy biến Shader / Paint thời gian thực bao quanh avatar trên toàn ứng dụng.
- **Thay đổi Icon Ứng dụng ngoài màn hình chính (Dynamic App Icons)**:
  - Tùy biến biểu tượng ứng dụng hiển thị trên Launcher của điện thoại (Default Icon, Neon Icon, Classic Icon, Gold Icon...).
- **Quản lý Danh mục Tùy biến (Custom User Categories)**:
  - Người dùng có thể tự tạo thêm danh mục chi tiêu mới theo nhu cầu cá nhân.
  - Tự chọn Icon từ kho Icon phong phú (App Icon Registry) và bảng mã màu sắc.
- **Tùy biến Giao diện Camera & Chat**:
  - Chọn Theme Camera chụp ảnh (Retrowave, Minimal, Film, v.v.).
  - Chọn Theme Bong bóng trò chuyện.

---

## 10. HỆ THỐNG & CÀI ĐẶT ỨNG DỤNG

- **Đa Ngôn ngữ Hoàn chỉnh (Localization)**:
  - Hỗ trợ đầy đủ **Tiếng Việt** và **Tiếng Anh** trên toàn bộ màn hình, thông báo và hộp thoại.
  - Tự động lưu ngôn ngữ đã chọn và áp dụng ngay lập tức không cần khởi động lại app.
- **Đa Tiền tệ & Tự động Quy đổi Tỷ giá**:
  - Hỗ trợ các đơn vị tiền tệ: **VND (₫)**, **USD ($)**, v.v.
  - Tích hợp dịch vụ cập nhật tỷ giá hối đoái tự động (Exchange Rate Service) hỗ trợ chuyển đổi linh hoạt.
- **Giao diện Sáng / Tối (Theme Mode)**:
  - Chế độ Sáng (Light Mode) thanh lịch.
  - Chế độ Tối (Dark Mode) hiện đại, bảo vệ mắt và tiết kiệm pin OLED.
  - Chế độ Theo hệ thống thiết bị (System Default).
- **Hệ thống Thông báo Kép (Dual Notification System)**:
  - **Firebase Cloud Messaging (FCM)**: Nhận thông báo đẩy từ xa khi có tin nhắn mới, lời mời kết bạn, bạn bè đăng khoảnh khắc.
  - **In-App Notification Host**: Banner thông báo nội bộ trượt từ trên xuống sống động khi người dùng đang mở ứng dụng.
- **Trung tâm Phản hồi & Báo cáo (Feedback & Reports)**:
  - Gửi ý kiến đóng góp / báo lỗi trực tiếp tới đội ngũ phát triển.
  - Báo cáo nội dung hoặc tài khoản vi phạm tiêu chuẩn cộng đồng.

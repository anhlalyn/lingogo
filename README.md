# LingoGo

Ứng dụng Flutter học tiếng Anh, Trung, Nhật và Hàn từ đặc tả LingoGo.

## Chạy

```powershell
flutter pub get
flutter run
```

Firebase tự khởi tạo từ lib/firebase_options.dart đã tạo bằng FlutterFire CLI.
Không cần USE_FIREBASE. Xem FIREBASE_SETUP.md để cấu hình và kiểm tra tài khoản.

## Tính năng hiện có

- Bắt buộc đăng nhập/đăng ký trước khi học; khôi phục phiên Firebase còn hợp lệ.
- Quên mật khẩu gửi liên kết qua email, kiểm tra biểu mẫu và thông báo lỗi.
- Đăng xuất có xác nhận và xóa toàn bộ ngăn xếp điều hướng.
- Chọn 4 ngôn ngữ, 23 cấp độ; thêm 69 bài thực hành ban đầu bên cạnh 6 bài cũ.
- Anh A1–C2, Trung HSK 1–6, Nhật N5–N1 và Hàn TOPIK cấp 1–6.
- Luyện nghe giọng đọc, nói qua micro và viết có Gemini góp ý; xem [COURSES_SETUP.md](COURSES_SETUP.md).
- Trắc nghiệm, điền từ, sắp xếp câu, ghép cặp; giải thích và kết quả.
- Đạt 70% mở bài tiếp theo; 30 XP/bài đạt, không cộng lại khi ôn.
- Flashcard và hẹn ôn từ đã nhớ sau 3 ngày.
- Hồ sơ, tiến độ, lịch ôn và ngày học lưu cục bộ riêng theo Firebase UID.
- Điện thoại và desktop có bố cục tương ứng.

Tiến độ chưa đồng bộ giữa các thiết bị. Dữ liệu demo cũ vẫn được giữ riêng,
không tự gán cho tài khoản mới. Đăng xuất không xóa dữ liệu học đã lưu.
Mục tiêu phút/ngày chưa đo thời lượng hay gửi thông báo tự động.
Đã có quản trị bài học thủ công và AI tạo nháp, tải bài đã xuất bản từ Firestore.
Xem [CONTENT_SETUP.md](CONTENT_SETUP.md) để quản lý bài và quyền Admin.
Gia sư và tạo bài nháp dùng Gemini qua Firebase AI Logic trên Spark, theo hạn mức miễn phí của Google.
Xem [AI_SETUP.md](AI_SETUP.md) để bật AI Logic và đăng ký App Check; không cần khóa AI trong Flutter hoặc Cloud Functions.
Logo, icon và màn hình chờ đã tích hợp; prompt ở assets/branding/README.md. Audio chưa có.
Tiến độ vẫn lưu cục bộ; Admin lưu nội dung qua Firestore transaction có Rules và nhật ký nguyên tử.

## Mã nguồn

- lib/main.dart: khởi tạo Firebase, thông báo lỗi và thử lại.
- lib/auth_service.dart: xác thực Firebase và theo dõi phiên.
- lib/auth_page.dart: đăng nhập, đăng ký, quên mật khẩu.
- lib/bootstrap.dart, lib/branding.dart: màn hình chờ, thử lại và bộ nhận diện.
- lib/tutor_page.dart: hội thoại gia sư Gemini.
- lib/app.dart: chặn truy cập khi chưa xác thực, giao diện học và hồ sơ.
- lib/data.dart, lib/languages.dart: nội dung và lưu tiến độ theo UID.
- lib/lesson_page.dart: bài tập và kết quả.
- lib/content_repository.dart, lib/spark_content_repository.dart: đọc bài published, quản trị trực tiếp với Rules.
- lib/gemini_service.dart, lib/app_check_setup.dart: Firebase AI Logic và xác thực ứng dụng.
- lib/admin_page.dart: soạn/sửa nháp, xem trước, xuất bản, lưu trữ và yêu cầu AI tạo nháp.
- functions/: công cụ cấp quyền, kiểm thử Rules và backend cũ không còn được app gọi.

## Kiểm tra

```powershell
flutter analyze
flutter test
```

Kiểm thử tự động dùng auth giả, không tạo tài khoản/gửi email thật.
iOS cần macOS/Xcode và chưa được kiểm thử.

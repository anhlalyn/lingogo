# Firebase và tài khoản LingoGo

Ứng dụng hiện bắt buộc xác thực trước khi vào học. Firebase được khởi tạo tự động;
không cần truyền USE_FIREBASE=true. Không còn nút kết nối hay màn hình kiểm tra Firestore.

## Chạy ứng dụng đã cấu hình

```powershell
cd D:\app\lingogo
flutter run -d emulator-5554
```

Chọn thiết bị khác bằng `flutter devices`, rồi `flutter run -d DEVICE_ID`.
Trình duyệt: `flutter run -d chrome`.
Sau khi cập nhật mã, dừng app cũ bằng q và chạy lại để áp dụng luồng khởi tạo mới.

## Luồng người dùng

- Chưa đăng nhập: mở màn hình Đăng nhập, có nút Đăng ký và Quên mật khẩu.
- Đăng ký: email hợp lệ, mật khẩu ít nhất 6 ký tự, nhập lại phải khớp.
- Đăng nhập/đăng ký thành công: chọn ngôn ngữ và mục tiêu nếu tài khoản chưa thiết lập trên thiết bị.
- Quên mật khẩu: nhập email, gửi liên kết; mở email và hoàn tất đặt lại trên trang Firebase.
- Đã có phiên hợp lệ: Firebase SDK khôi phục phiên, không yêu cầu nhập mật khẩu mỗi lần mở app.
- Cá nhân: tên, email và Đăng xuất. Đăng xuất trở về màn hình đăng nhập, xóa ngăn xếp điều hướng.

Tiến độ, từ vựng ôn tập và hồ sơ cục bộ lưu riêng theo UID; chưa đồng bộ nhiều thiết bị.
Dữ liệu demo cũ dùng chung vẫn nằm ở khóa lingogo.v1, không tự gán cho tài khoản nào.
Đăng xuất không xóa tiến độ của tài khoản trên thiết bị. Không lưu mật khẩu trong SharedPreferences.

## Cấu hình lại khi cần

Firebase Console: https://console.firebase.google.com/
Dự án hiện tại: lingogo-f526e. Authentication → Sign-in method → bật Email/Password.
Google có thể bật trong Console, nhưng app hiện chỉ triển khai đăng nhập email/mật khẩu.

```powershell
firebase.cmd login
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure --project=lingogo-f526e --platforms=android,web
```

CLI tạo lib/firebase_options.dart và các file nền tảng. Không thay cấu hình thật bằng placeholder.
Không đưa private key/service-account JSON vào ứng dụng.
iOS cần cấu hình thêm nền tảng ios và build trên macOS/Xcode.

## Email đặt lại mật khẩu

Firebase Console → Authentication → Templates → Password reset:
chỉnh tên hiển thị/người gửi nếu cần. Kiểm tra Inbox và Spam của email bạn sở hữu.
Ứng dụng hiển thị thông báo chung sau khi yêu cầu thành công để không tiết lộ email đã đăng ký.
Đường liên kết đặt lại được gửi bởi Firebase; không có việc tự đổi mật khẩu trực tiếp trong app.

## Firestore Rules

Đăng nhập, đăng ký và quên mật khẩu dùng Firebase Authentication, không cần mở quyền Firestore.
File firestore.rules hiện cho người đã đăng nhập đọc bài published và Admin đọc nháp/lưu trữ.
Chỉ Admin có Custom Claim mới được ghi bài bằng transaction kèm nhật ký; người học không được ghi nội dung.
Tiến độ học vẫn lưu cục bộ, chưa có quyền ghi tiến độ lên Firestore.
Không đổi rules thành allow read, write: if true để xử lý lỗi đăng nhập.
Xem CONTENT_SETUP.md để quản trị nội dung và AI_SETUP.md để bật Gemini trên Spark.

## Xử lý lỗi

- Email/Password chưa bật: bật nhà cung cấp trong Authentication của đúng dự án.
- Sai thông tin: kiểm tra email và mật khẩu, hoặc dùng Quên mật khẩu.
- Không có mạng/quá nhiều yêu cầu: app thông báo lỗi và cho thử lại.
- Không khởi tạo được dịch vụ: app chỉ có nút Thử lại, không bỏ qua đăng nhập để vào học.
- Không nhận email: kiểm tra Spam, email đã nhập và Templates trong Firebase Console.
- Windows báo symlink support: bật Developer Mode rồi chạy flutter pub get.
- Android dùng Kotlin 2.4.21, compilerOptions DSL và minSdk 24 để tương thích SDK hiện tại.

## Kiểm tra

```powershell
flutter analyze
flutter test
```

Kiểm thử tự động dùng dịch vụ xác thực giả để kiểm tra giao diện và điều hướng;
không tạo tài khoản hay gửi email thật. Kiểm tra thực tế bằng tài khoản/email bạn sở hữu.

Tài liệu chính thức:
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/docs/auth/flutter/password-auth
- https://firebase.google.com/docs/auth/flutter/manage-users

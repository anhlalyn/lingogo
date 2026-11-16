# Dùng Gemini miễn phí với Firebase Spark

Bản hiện tại đã chuyển sang Firebase AI Logic + Gemini Developer API.
Không dùng OpenAI, Cloud Functions, Secret Manager hoặc API key riêng trong app.
Đã sửa mã và kiểm thử; bạn cần bật AI Logic và đăng ký App Check trong Console để gọi AI thật.
Không build APK trong lần thay đổi này theo yêu cầu của bạn.

## 1. Giữ dự án ở Spark

Mở https://console.firebase.google.com/project/lingogo-f526e/overview
Kiểm tra gói ở góc dưới bên trái là Spark. Không chọn Upgrade/Blaze và không liên kết Cloud Billing.
Nếu dự án đã liên kết billing, cần kiểm tra dịch vụ đang dùng trước khi tự đổi gói;
đường free tier này yêu cầu dự án không liên kết billing.

Gemini Developer API có free tier cho model hỗ trợ, với hạn mức theo dự án/tài khoản.
Khi hết hạn mức, app báo để thử lại; mã không tự chuyển sang nhà cung cấp hoặc model trả phí.
Miễn phí không có nghĩa không giới hạn. Firestore trên Spark cũng có hạn mức riêng.

## 2. Bật Firebase AI Logic

Trong dự án lingogo-f526e:

1. Thanh bên → AI Services → AI Logic.
2. Bấm Get started.
3. Chọn Gemini Developer API (không chọn Agent Platform/Vertex AI).
4. Hoàn thành các bước bật API/dịch vụ mà Firebase hướng dẫn.
5. Giữ gói Spark; nếu màn hình yêu cầu bật billing, kiểm tra lại nhà cung cấp/model đã chọn.

Firebase AI Logic xử lý kết nối đến Gemini. Không lấy Firebase apiKey trong
firebase_options.dart để gọi trực tiếp Generative Language API, không dán khóa AI vào Flutter.
Không cần chạy functions:secrets:set hoặc deploy functions theo hướng dẫn cũ.

Model mặc định trong app: gemini-3.5-flash-lite, có free tier văn bản theo tài liệu tại thời điểm triển khai.
Nếu Google thay khả năng hỗ trợ, chọn model văn bản có free tier trong tài khoản của bạn rồi chạy:

```powershell
flutter run -d emulator-5554 --dart-define=GEMINI_MODEL=TEN_MODEL_CO_FREE_TIER
```

Không dùng model yêu cầu billing, và không liên kết billing nếu bạn muốn giữ chế độ không trả phí.

## 3. App Check cho Android giả lập

Firebase AI Logic hiện yêu cầu App Check. Mã đã tự dùng Debug Provider khi chạy Flutter debug,
và Play Integrity khi chạy bản release Android. Không tắt enforcement để vượt bước cấu hình.

Mở terminal VS Code trong dự án:

```powershell
cd D:\app\lingogo
flutter pub get
flutter run -d emulator-5554
```

Nếu pub get báo requires symlink support trên Windows, bật Settings → System → For developers →
Developer Mode rồi chạy lại. Lệnh flutter run là chạy thử trên giả lập; không cần flutter build apk.

Trong app, đăng nhập → AI gia sư → gửi một câu ngắn, ví dụ Hello.
Lần đầu có thể báo App Check chưa hợp lệ. Trong terminal, tìm dòng tương tự:

```text
DebugAppCheckProvider: Enter this debug secret into the allow list ...
```

Sao chép debug token trên máy của bạn rồi:

1. Firebase Console → Security → App Check → Apps.
2. Tìm ứng dụng Android com.example.lingogo.
3. Menu dấu ba chấm → Manage debug tokens → Add debug token.
4. Đặt tên, ví dụ Android emulator, dán token rồi lưu.
5. Chờ cấu hình có hiệu lực, dừng app bằng q và chạy lại flutter run.
6. Vào AI gia sư gửi lại Hello.

Debug token là thông tin tin cậy của thiết bị thử nghiệm: chỉ nhập vào Console, không gửi qua chat.
Nếu Console yêu cầu đăng ký ứng dụng trước, chọn Play Integrity và làm theo hướng dẫn đăng ký;
trong môi trường debug, SDK vẫn dùng token debug đã cho phép.

Khi phát hành thật, cần cấu hình Play Integrity cho Android hoặc App Attest/Device Check cho iOS.
Không dùng Debug Provider trong bản phát hành.

## 4. Firestore Rules và quản lý bài không cần Functions

Bản Spark cho Admin ghi bằng transaction, kèm audit log nguyên tử; người học không được ghi nội dung.
Rules kiểm tra Custom Claim admin, trạng thái nháp/xuất bản/lưu trữ, kiểu dữ liệu, số lượng từ/câu,
revision và nhật ký. App kiểm tra độ dài từng trường và tính nhất quán của đáp án trước khi ghi.
Không có nút tự cấp quyền Admin.

Rules mới được kiểm thử bằng Firestore Emulator trước khi triển khai.
Nếu cần tự cập nhật Rules sau này:

```powershell
firebase.cmd deploy --only firestore:rules --project lingogo-f526e
```

Không chạy firebase deploy --only functions. firebase.json hiện không còn cấu hình triển khai Functions.
Thư mục functions giữ công cụ cấp quyền/kiểm thử và backend cũ để tham khảo, không được app gọi.

UID đã được cấp Admin: akcpQx1zDdgVSgTRm4z1Cygdfjg2.
Đăng xuất/đăng nhập lại để nhận claim, vào Cá nhân → Quản lý bài học.

- Tự soạn bài: nhập nội dung → Lưu bản nháp → Xem trước → Xuất bản.
- AI tạo bản nháp: chọn ngôn ngữ/chủ đề → Gemini tạo → kiểm tra và sửa → Xuất bản.
- Mỗi bài ngắn tối đa 5 từ vựng và 4 câu hỏi, hỗ trợ đủ 4 dạng bài tập.
- Bài xuất bản giữ nguyên nội dung; muốn sửa, tạo bản sao mới. Lưu trữ không xóa điểm cũ.
- Không tự xuất bản kết quả AI. Rules kiểm tra quyền và cấu trúc giới hạn; app đối chiếu đáp án, Admin kiểm duyệt kiến thức.
- AI thành công nhưng lưu Firestore lỗi: bản nháp được giữ trong bộ nhớ phiên để thử lưu lại mà
  không gọi lại Gemini ngay. Đóng app sẽ mất phần chưa lưu.

## 5. Web (tùy chọn, nên hoàn tất Android trước)

Đăng ký ứng dụng Web trong App Check với reCAPTCHA v3 và hostname đang dùng.
Site key reCAPTCHA là khóa công khai, khác khóa API Gemini. Chạy:

```powershell
flutter run -d chrome --dart-define=APP_CHECK_WEB_SITE_KEY=SITE_KEY_CUA_BAN
```

Không có site key web thì app vẫn đăng nhập/học/soạn thủ công được; AI sẽ bị App Check từ chối.
Đừng dùng token debug Android cho ứng dụng web.

## Dữ liệu và hạn mức

- Hội thoại chỉ giữ trong phiên app, không tạo bộ cache hội thoại trên Firestore như backend cũ.
- Chỉ gửi tối đa 8 tin nhắn lịch sử, tối đa 1200 ký tự tin nhắn mới, câu trả lời giới hạn độ dài.
- Không gửi UID/email cho Gemini trong prompt. Chính sách dữ liệu free tier do Google quy định.
- Hạn mức 20 lượt/ngày và 200 lượt toàn dự án của backend cũ không còn áp dụng.
  Hạn mức thực tế do Gemini Developer API/Firebase AI Logic của dự án quyết định.
- App Check giúp xác thực ứng dụng, không thay thế quyền Admin; quyền ghi nội dung vẫn do Rules bảo vệ.
- Tiến độ học vẫn lưu cục bộ riêng theo UID, chưa đồng bộ thiết bị.

## Lỗi thường gặp

- Service API chưa bật: hoàn tất AI Logic → Get started với Gemini Developer API.
- App Check token không hợp lệ: đăng ký debug token đúng Android app rồi chạy lại.
- Không gọi được Gemini trên web: kiểm tra site key reCAPTCHA và hostname.
- Quota exceeded: hết hạn mức miễn phí hoặc tài khoản/model không được cấp quota; chờ hoặc kiểm tra quota trong Console/AI Studio. Không tự nâng billing.
- Permission denied khi lưu bài: đăng nhập lại đúng Admin, kiểm tra Rules mới và nhật ký transaction.
- Bài tạo sai định dạng: app từ chối lưu; thử một chủ đề ngắn và cụ thể hơn.

## Kiểm tra mã (không build APK)

```powershell
flutter analyze
flutter test
firebase.cmd emulators:exec --only firestore --project demo-lingogo "npm.cmd --prefix functions run test:rules"
```

Kiểm thử Gemini sử dụng phản hồi giả lập, không gọi API thật hay tiêu thụ quota của bạn.
Cần thử thực tế sau khi hoàn tất các bước Console và App Check ở trên.

Tài liệu chính thức:
- https://firebase.google.com/docs/ai-logic/get-started
- https://firebase.google.com/docs/ai-logic/app-check
- https://firebase.google.com/docs/ai-logic/pricing?api=dev
- https://ai.google.dev/gemini-api/docs/pricing

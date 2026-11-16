# Khóa học và luyện nghe, nói, viết

## Nội dung hiện có

- Anh: A1, A2, B1, B2, C1, C2.
- Trung: HSK 1–6 theo lộ trình sáu cấp bạn yêu cầu.
- Nhật: JLPT N5, N4, N3, N2, N1.
- Hàn: TOPIK I cấp 1–2 và TOPIK II cấp 3–6.

Đã thêm 69 bài thực hành khởi đầu, mỗi cấp 3 bài, giữ các bài cũ.
Đây là nội dung tự soạn theo độ khó định hướng, chưa phải toàn bộ giáo trình
chính thức hay bộ luyện thi đã kiểm định; không cam kết đạt chứng chỉ.
Từ vựng của các bài mới là câu/cụm luyện tập có bản dịch và phiên âm với Trung/Nhật/Hàn.
Tiến độ bài học được giữ riêng theo ID; lựa chọn cấp được lưu theo ngôn ngữ và tài khoản.

## Dùng trong app

1. Trang chủ hoặc Học tập: chọn Khóa học / cấp độ.
2. Chọn bài và học; các bài ở cấp hiện tại mở tuần tự theo kết quả.
3. Bấm Luyện nghe · nói · viết để luyện các câu của cấp đang chọn.

- Nghe: bấm Nghe mẫu hoặc Nghe chậm, nhập câu đã nghe và đối chiếu.
- Nói: nghe mẫu, bấm Bắt đầu nói, cấp quyền micro, đọc câu và dừng nhận diện.
  Kết quả là văn bản từ bộ nhận diện của thiết bị, không phải chấm âm vị/thanh điệu.
- Viết: nhập câu dịch hoặc diễn đạt khác; đối chiếu mẫu hoặc bấm Gemini góp ý.
  Gemini nhận văn bản bạn gửi và cấp độ hiện tại, góp ý bằng tiếng Việt.
  Đây là nhập văn bản bằng bàn phím, chưa phải nhận diện chữ viết tay.

Các lượt luyện kỹ năng chưa cộng XP, chưa lưu lịch sử câu trả lời hoặc bản ghi âm.
App không tự tải bản ghi âm lên Firebase. Dịch vụ nhận diện của hệ điều hành
có thể cần mạng; thiết bị xử lý theo cấu hình dịch vụ giọng nói của bạn.
Gemini góp ý dùng cùng hạn mức miễn phí đã cấu hình, có thể hết quota.

## Bổ sung nội dung bằng Admin

Cá nhân → Quản lý bài học → AI tạo bản nháp → chọn ngôn ngữ và cấp độ,
nhập chủ đề cụ thể (ví dụ HSK 4: 与其…不如…), tạo nháp, xem trước và duyệt.
Tự soạn cũng có ô cấp độ. App và Firestore Rules chấp nhận đầy đủ các cấp trên;
gia sư hội thoại dùng cấp đang chọn. Bài nâng cao không xuất hiện lẫn ở cấp đầu.
Không chạy tự động hàng loạt hoặc tự xuất bản để tránh vượt quota và nội dung chưa duyệt.

## Chạy thử, không build APK

```powershell
cd D:\app\lingogo
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Sau khi thêm plugin, dừng app cũ bằng q rồi chạy lại; hot reload không nạp plugin native.
Nếu Windows báo symlink support, bật Windows Settings → For developers → Developer Mode,
rồi chạy lại flutter pub get. Không cần chạy flutter build apk.

Android cần cài engine chuyển văn bản thành giọng nói và dữ liệu giọng Anh/Trung/Nhật/Hàn.
Trong Settings tìm Text-to-speech / Chuyển văn bản thành giọng nói để tải giọng.
Cho phép quyền micro trong App info → Permissions; ứng dụng chỉ hỏi khi bạn bắt đầu nói.
Giả lập cần bật microphone input và có dịch vụ nhận diện; nên kiểm tra micro trên điện thoại thật.
iOS đã khai báo lý do dùng micro và nhận diện lời nói, nhưng chưa kiểm thử trên thiết bị iOS.
Nghe/nói phụ thuộc hỗ trợ ngôn ngữ của thiết bị; app thông báo nếu không có giọng/dịch vụ.

## Kiểm thử

```powershell
flutter analyze
flutter test
firebase.cmd emulators:exec --only firestore --project demo-lingogo "npm.cmd --prefix functions run test:rules"
```

Kiểm thử tự động xác nhận đủ cấp, lưu lựa chọn/tiến độ theo tài khoản, gửi bài viết đúng cấp
và quyền ghi nội dung nâng cao. API Gemini, TTS và micro thật cần kiểm tra trên thiết bị;
test tự động không tiêu thụ quota Gemini.

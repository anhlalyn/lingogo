# Quản lý bài học trên Firebase Spark

Ứng dụng hiện dùng Gemini qua Firebase AI Logic và Firestore transaction trực tiếp.
Đọc AI_SETUP.md để bật AI Logic và App Check. Không dùng Cloud Functions, OpenAI hay Secret Manager.
Các hướng dẫn nâng Blaze, đặt API secrets và deploy Functions của phiên bản trước không còn áp dụng.

## Người quản trị

UID akcpQx1zDdgVSgTRm4z1Cygdfjg2 đã được cấp Custom Claim admin.
Đăng xuất/đăng nhập lại, vào Cá nhân → Quản lý bài học.

- Tự soạn: thêm từ vựng và câu hỏi, lưu nháp, xem trước, xác nhận xuất bản.
- AI: chọn ngôn ngữ/chủ đề, Gemini tạo bản nháp, đọc/sửa rồi xuất bản.
- Bài ngắn 1–5 từ, 1–4 câu; AI tạo đúng 5 từ và 4 dạng câu hỏi.
- Chỉ bài published xuất hiện ở tài khoản người học.
- Bài xuất bản không sửa tại chỗ; tạo bản sao mới nếu muốn thay nội dung.
- Lưu trữ giữ lại dữ liệu và điểm đã có, không xóa cứng.
- Admin hiển thị cả 75 bài có sẵn và các bài trên Firestore, với tổng quan 23 cấp độ.
- Lọc ngôn ngữ, cấp độ, trạng thái hoặc tìm tên bài; bấm một cấp trong tổng quan để lọc nhanh.
- Bài có sẵn được gắn nhãn riêng, có thể xem và tạo bản sao thành bản nháp để chỉnh sửa.
  Bài gốc trong app vẫn được giữ nguyên; xuất bản/lưu trữ áp dụng cho bài trên Firestore.

## Ghi dữ liệu

App dùng transaction: đọc revision hiện tại, kiểm tra trạng thái, ghi bài và bản ghi
adminAuditLogs/{lessonId}_r{revision} trong cùng transaction. Rules từ chối thiếu nhật ký,
revision cũ, giả actor, sửa bài published, xóa log hoặc quyền không phải Admin.
Client kiểm tra đầy đủ từng trường và đáp án; Rules kiểm tra quyền, kiểu dữ liệu, số lượng từ/câu,
trạng thái và nhật ký trước khi chấp nhận ghi. App đối chiếu đáp án; Admin phải duyệt đúng kiến thức.

## Cập nhật Rules và kiểm thử

```powershell
cd D:\app\lingogo
flutter analyze
flutter test
firebase.cmd emulators:exec --only firestore --project demo-lingogo "npm.cmd --prefix functions run test:rules"
firebase.cmd deploy --only firestore:rules --project lingogo-f526e
```

Không build APK, không deploy Functions để dùng bản này.
Giữ Spark và không liên kết billing để dùng free tier. Gemini/Firestore đều có hạn mức miễn phí.

## Cấp quyền tài khoản khác (chỉ môi trường chủ dự án đáng tin cậy)

Công cụ cũ vẫn có thể dùng phiên Firebase CLI đã đăng nhập để cấp/thu hồi Custom Claim:

```powershell
cd D:\app\lingogo\functions
$env:NODE_PATH=(npm.cmd root -g).Trim()
node scripts/set-admin.js lingogo-f526e USER_UID grant --firebase-cli
```

Thay USER_UID bằng UID thật và grant bằng revoke nếu thu hồi quyền.
Không tự cấp Admin từ giao diện app hay trường role do client gửi.
Backend cũ trong functions/index.js không được cấu hình deploy và không được app gọi.

# Build file iOS bằng GitHub Actions

Workflow có sẵn: `.github/workflows/ios-unsigned.yml`.
Repository: https://github.com/anhlalyn/lingogo
File tạo ra: `LingoGo-unsigned.ipa` dành cho iPhone thật, không phải iOS Simulator.
Không cần cung cấp tài khoản Apple, chứng chỉ hoặc mật khẩu để build file chưa ký này.
IPA chưa ký cần được ký lại trước khi iPhone cho phép cài/chạy; tải file bằng Safari
không tự cài được app. Có thể dùng công cụ hỗ trợ ký/cài bằng Apple Account của bạn
sau khi tải file về; đây là bước riêng với build.

## Chuẩn bị mã trên GitHub

Đưa mã dự án LingoGo lên một repository GitHub của bạn, gồm các file nguồn và
`pubspec.lock`, thư mục `ios`, `assets`, `lib`, `test`, `.github`.
Không cần tải `build`, `.dart_tool`, `functions/node_modules` hoặc file log.

Workflow phải nằm ở **gốc repository** tại `.github/workflows/ios-unsigned.yml`.

- Nếu repository chứa thẳng `pubspec.yaml`, giữ cấu trúc dự án hiện tại.
- Nếu repository chứa thư mục `lingogo/pubspec.yaml`, đưa workflow ra
  `.github/workflows/ios-unsigned.yml` ở ngoài thư mục `lingogo`.
  Workflow tự tìm đúng thư mục dự án trong hai trường hợp này.

## Chạy build và tải file

1. Mở repository trên GitHub → tab Actions.
2. Chọn **Build iOS unsigned IPA** bên trái.
3. Bấm **Run workflow**, chọn nhánh chứa mã mới rồi xác nhận chạy.
4. Chờ lượt chạy hoàn tất màu xanh.
5. Mở lượt chạy → phần **Artifacts** → tải **LingoGo-iOS-unsigned**.
6. Giải nén file tải về để lấy `LingoGo-unsigned.ipa`.

Artifact được giữ 7 ngày. Workflow chỉ chạy khi bấm thủ công, không tự build mỗi lần push.
GitHub Actions có hạn mức sử dụng tùy loại repository và tài khoản; kiểm tra trang
Billing & licensing/Actions usage trước khi chạy nếu bạn cần tránh phí phát sinh.

## Cấu hình đã chuẩn bị

- Flutter 3.41.6 / Dart 3.11.4, cùng phiên bản Flutter hiện dùng trên máy Windows.
- Máy macOS 15 của GitHub, build release bằng `flutter build ios --release --no-codesign`.
- Đóng gói `Payload/Runner.app` thành IPA, tạo checksum SHA-256 và tải lên artifact.
- Bundle ID: `com.example.lingogo`.
- Firebase iOS đã đăng ký trong dự án `lingogo-f526e` và thêm vào `firebase_options.dart`.
- `GoogleService-Info.plist` được đưa vào tài nguyên Runner.
- iOS tối thiểu 15.0 để phù hợp Firebase SDK hiện tại; CocoaPods đã cấu hình.
- Firebase CocoaPods ghim 12.19.0 vì FirebaseAppCheck không có bản 12.19.3.
- Các mô tả quyền micro và nhận diện lời nói đã có trong Info.plist.

Build chưa ký không có chữ ký hay entitlement App Attest. Nếu ký/cài bằng công cụ
cá nhân, đăng nhập và bài học vẫn cần kiểm tra thực tế; Gemini còn cần App Check hợp lệ
cho ứng dụng iOS. Cấu hình token App Check của Android không dùng chung cho iOS.
Không coi việc build thành công là đã kiểm thử nghe/nói hoặc AI trên iPhone.

## Nếu workflow thất bại

Mở bước màu đỏ trong Actions và gửi phần thông báo lỗi để sửa đúng bước.
Không chạy lệnh build iOS trên Windows: Xcode chỉ có trên macOS.
Đã build thành công trên GitHub Actions và qua 38 kiểm thử Flutter:
https://github.com/anhlalyn/lingogo/actions/runs/43849622270
Chưa ký/cài và chưa kiểm thử thực tế trên iPhone. Các lượt build mới sẽ nằm trong tab Actions.

Tài liệu:
- https://docs.flutter.dev/deployment/ios
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-running-a-workflow
- https://firebase.google.com/docs/flutter/setup

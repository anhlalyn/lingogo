# Công cụ và backend cũ

App hiện dùng Firebase AI Logic + Gemini và Firestore transaction trên Spark.
Không còn gọi các Cloud Functions trong index.js. firebase.json đã bỏ cấu hình
triển khai Functions. Không deploy backend cũ để chạy phiên bản hiện tại.

- scripts/set-admin.js: công cụ cấp Custom Claim, chỉ chạy bởi chủ dự án.
- test/rules.integration.js: kiểm thử Rules trên Firestore Emulator.
- index.js và các mô-đun backend còn lại: mã cũ, không thuộc luồng AI hiện tại.

Xem ../AI_SETUP.md và ../CONTENT_SETUP.md để cấu hình bản Spark.

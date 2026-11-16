import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lesson_validation.dart';

String contentErrorMessage(Object error) {
  if (error is ContentFailure) return error.message;
  if (error is QuotaExceeded) {
    return 'Gemini đã hết hạn mức miễn phí. Hãy thử lại sau.';
  }
  if (error is ServiceApiNotEnabled) {
    return 'Dịch vụ AI chưa sẵn sàng. Vui lòng liên hệ quản trị viên.';
  }
  if (error is UnsupportedUserLocation) {
    return 'Gemini hiện chưa hỗ trợ tài khoản hoặc khu vực này.';
  }
  if (error is FirebaseAIException) {
    return 'Chưa kết nối được Gemini. Hãy thử lại sau hoặc liên hệ quản trị viên.';
  }
  if (error is TimeoutException) {
    return 'Gemini phản hồi chậm. Hãy thử lại sau.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unauthenticated' => 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
      'permission-denied' =>
        'Chưa có quyền truy cập. Kiểm tra quyền Admin và Firestore Rules theo hướng dẫn.',
      'resource-exhausted' => 'Đã hết hạn mức miễn phí. Hãy thử lại sau.',
      'unavailable' ||
      'deadline-exceeded' => 'Chưa kết nối được. Kiểm tra mạng và thử lại.',
      _ => 'Chưa xử lý được yêu cầu. Kiểm tra kết nối và thử lại.',
    };
  }
  return 'Chưa xử lý được yêu cầu. Kiểm tra kết nối và thử lại.';
}

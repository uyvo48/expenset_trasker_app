import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Ném [AppException] nếu response của Dio chứa lỗi.
///
/// Dùng khi cần kiểm tra status code thủ công (ví dụ: kiểm tra 201 vs 200).
/// Trong hầu hết trường hợp, [ErrorInterceptor] đã tự handle rồi.
AppException exceptionFromDioResponse(Response response) {
  final data = response.data;
  String message = 'Có lỗi xảy ra, vui lòng thử lại';

  if (data is Map<String, dynamic> && data.containsKey('error')) {
    message = data['error'] as String;
  }

  return AppException(message, statusCode: response.statusCode);
}

/// Trích xuất error message từ [DioException].
///
/// Nếu error bên trong là [AppException], trả về message của nó.
/// Nếu không, trả về message mặc định.
AppException appExceptionFromDioError(DioException error) {
  if (error.error is AppException) {
    return error.error as AppException;
  }

  return AppException(
    'Có lỗi xảy ra, vui lòng thử lại',
    statusCode: error.response?.statusCode,
  );
}

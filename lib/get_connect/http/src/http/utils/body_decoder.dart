import 'dart:convert';

import '../../../../../get_core/get_core.dart';

import '../../http.dart';
import '../../request/request.dart';
import '../../status/http_status.dart';

/// Will return the decoded body as [T]. If the body cannot be decoded
/// and [status] is OK, an error is thrown. If [status] is not OK,
/// [Request.decoderMode] if an error while decoding should be mapped to null.
T? bodyDecoded<T>(
  Request<T> request,
  String stringBody,
  String? mimeType,
  HttpStatus status,
) {
  var decodeOnError = request.decoderMode != DecoderMode.SUCCESS_ONLY;
  var ignoreTypeMismatch = request.decoderMode == DecoderMode.TRY_ON_ERROR;

  if (status.isOk || decodeOnError) {
    return _bodyDecoded(
      request.decoder,
      stringBody,
      mimeType,
      ignoreTypeMismatch,
    );
  }
}

T? _bodyDecoded<T>(
  Decoder<T>? decoder,
  String stringBody,
  String? mimeType,
  bool ignoreTypeMismatch,
) {
  T? body;
  var bodyToDecode;

  if (mimeType != null && mimeType.contains('application/json')) {
    try {
      bodyToDecode = jsonDecode(stringBody);
    } on FormatException catch (_) {
      Get.log('Cannot decode server response to json');
      bodyToDecode = stringBody;
    }
  } else {
    bodyToDecode = stringBody;
  }

  T? cast(dynamic d) {
    if (ignoreTypeMismatch && !(d is T?)) {
      return null;
    }
    return d as T?;
  }

  try {
    if (stringBody == '') {
      body = null;
    } else if (decoder != null) {
      body = decoder(bodyToDecode);
    } else {
      body = cast(bodyToDecode);
    }
  } on Exception catch (_) {
    body = cast(stringBody);
  }

  return body;
}

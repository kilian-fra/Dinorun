import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpResponseParser {
  final http.Response? _response;

  HttpResponseParser (http.Response? response) : _response = response;

  bool parse(Function(dynamic, int) onSuccess, Function(String) onAuthError, Function(String, int) onError, Function() onUnknownError) 
  {
    if (_response == null) {
      onUnknownError();
      return false;
    } else if (_response!.statusCode >= 200 && _response!.statusCode <= 299) {
      onSuccess(json.decode(_response!.body), _response!.statusCode);
      return true;
    } else if (_response!.statusCode == 401) {
      onAuthError(json.decode(_response!.body)['message']);
      return false;
    } else {
      onError(json.decode(_response!.body)['message'], _response!.statusCode);
      return false;
    }
  }

  dynamic get bodyData => json.decode(_response!.body);
}
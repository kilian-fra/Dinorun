import 'dart:convert';
import 'package:http/http.dart' as http;

enum HttpMethod {
  GET,
  POST,
  PUT,
  DELETE,
  PATCH
}

class RESTRequest {
  //Defines the URL of the REST API (among all request the same)
  static final String _URL = 'https://dinorun-10285.edu.k8s.th-luebeck.dev/api/'; //'http://localhost:5000/api/';
  String _resource = "";

  RESTRequest(String resource) {
    _resource = resource;
  }

  Future<http.Response?> make(HttpMethod method, Map<String, String> data) async {
    final uri = Uri.parse(_URL + _resource);
    
    http.Response response;
    try {
      switch (method) {
      case HttpMethod.GET: {
        response = await http.get(uri);
        break;
      }
      case HttpMethod.POST: {
        response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
        break;
      }
      case HttpMethod.PUT: {
        response = await http.put(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
        break;
      }
      case HttpMethod.DELETE: {
        response = await http.delete(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
        break;
      }
      case HttpMethod.PATCH: {
        response = await http.patch(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
        break;
      }
      default: {
        return null;
      }
    }
    } catch (error) {
      return null;
    }

    return response;
  }

}
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://6a48e3bea033dcb98d650283.mockapi.io",
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
    ),
  );

  List<dynamic> _readNotesList(dynamic data) {
    if (data is List) {
      return data;
    }

    throw FormatException(
      'Expected /notes to return a JSON list but received ${data.runtimeType}.',
    );
  }

  Future<List<dynamic>> getNotes() async {
    final response = await dio.get("/notes");
    return _readNotesList(response.data);
  }

  Future<List<dynamic>> fetchNotes() async {
    final response = await dio.get("/notes");
    return _readNotesList(response.data);
  }

  Future<Response> createNote(Map<String, dynamic> body) {
    return dio.post("/notes", data: body);
  }

  Future<Response> updateNote(String id, Map<String, dynamic> body) {
    return dio.put("/notes/$id", data: body);
  }

  Future<Response> deleteNote(String id) {
    return dio.delete("/notes/$id");
  }
}

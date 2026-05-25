import 'dart:convert';
import 'package:http/http.dart' as http;

class USDAService {

  static const String apiKey = 'IN00UtQgjmPvALhKLhZNNIiypG5zOegbj4JXQhBy';

  static Future<Map<String, dynamic>?> searchFood(String query) async {

    final url =
        'https://api.nal.usda.gov/fdc/v1/foods/search?query=$query&api_key=$apiKey';

    try {

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data['foods'] != null &&
            data['foods'].isNotEmpty) {

          return data['foods'][0];
        }
      }

    } catch (e) {
      print(e);
    }

    return null;
  }
}
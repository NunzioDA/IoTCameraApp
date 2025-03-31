import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class WebServer {
  static String password = String.fromEnvironment("PASSWORD");
  static String serverName = String.fromEnvironment("SERVER_NAME");
  static String backend = String.fromEnvironment("BACKEND");

  static Uri geBackendUri(String phpFile, Map<String, String>? parameters)
  {
    print(String.fromEnvironment("PASSWORD"));
    Uri uri;

    uri = Uri.https(serverName,'$backend/$phpFile.php', parameters);
    
    return uri;
  }

  static Future<http.Response> getRequest(String phpFile, [Map<String, String>? parameters]) async {
      http.Response response = await http.get(geBackendUri(phpFile, parameters));
      return response;    
  }

  static Future<http.Response> postRequest(
    String phpFile, 
    {Map<String, String>? getParameters, Map<String, String>? body}
  ) async{    
    http.Response response = await http.post(geBackendUri(phpFile, getParameters ?? {}), body: body);
    return response;
  }

  static Future<bool> isImageRequestPending() async{
    return getRequest(
      "is_image_request_pending",
      {
        "password" : password
      }
    ).then(
      (response){
        return response.body.contains("True") ? true : false;
      }
    );
  }

  static void sendImage(Uint8List image) {
    postRequest(
      "save_image",
      getParameters: {
        "password" : password        
      },
      body:{
        "image": base64Encode(image)
      }
    );
  }
}
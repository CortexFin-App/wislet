import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final imageBase64 = body['image'] as String?;

  if (imageBase64 == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Image data is required.');
  }

  try {
    final client = await clientViaApplicationDefaultCredentials(
      scopes: [vision.VisionApi.cloudVisionScope],
    );
    final visionApi = vision.VisionApi(client);

    final request = vision.BatchAnnotateImagesRequest(
      requests: [
        vision.AnnotateImageRequest(
          image: vision.Image(content: imageBase64),
          features: [vision.Feature(type: 'TEXT_DETECTION')],
        ),
      ],
    );

    final response = await visionApi.images.annotate(request);
    final fullText = response.responses?.first.fullTextAnnotation?.text;

    return Response.json(body: {'text': fullText ?? ''});
  } catch (e) {
    print('Google Vision API Error: $e');
    return Response(statusCode: HttpStatus.internalServerError, body: 'Failed to process image.');
  }
}
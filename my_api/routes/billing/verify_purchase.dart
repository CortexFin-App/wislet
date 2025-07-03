import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:googleapis/androidpublisher/v3.dart' hide User;
import 'package:googleapis_auth/auth_io.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/logger.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final user = context.read<User>();
  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;

  final purchaseToken = body['purchase_token'] as String?;
  final subscriptionId = body['subscription_id'] as String?;
  final packageName = body['package_name'] as String?;

  if (purchaseToken == null || subscriptionId == null || packageName == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Missing required purchase data.',
    );
  }

  try {
    final client = await clientViaApplicationDefaultCredentials(
      scopes: [AndroidPublisherApi.androidpublisherScope],
    );
    final playApi = AndroidPublisherApi(client);

    final subscription = await playApi.purchases.subscriptions.get(
      packageName,
      subscriptionId,
      purchaseToken,
    );

    final expiryTimeMillis = int.tryParse(subscription.expiryTimeMillis ?? '0');

    if (expiryTimeMillis != null && expiryTimeMillis > 0) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimeMillis);

      if (expiryDate.isAfter(DateTime.now())) {
        await supabase
            .from('users')
            .update({'subscription_expires_at': expiryDate.toIso8601String()})
            .eq('id', user.id);

        return Response.json(
          body: {
            'status': 'success',
            'expiry_date': expiryDate.toIso8601String(),
          },
        );
      }
    }

    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Purchase verification failed or subscription is expired.',
    );
  } catch (e, stackTrace) {
    logger.severe('Error verifying purchase', e, stackTrace);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: 'Server error during purchase verification.',
    );
  }
}
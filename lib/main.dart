import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:chat_utilities_hub/amplify_outputs.dart';
import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/local_utility_repository.dart';
import 'package:chat_utilities_hub/src/models/ModelProvider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ChatUtilitiesHubApp(
      authenticationEnabled: true,
      repository: LocalUtilityRepository(preferences: preferences),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.addPlugin(
      AmplifyAPI(
        options: APIPluginOptions(modelProvider: ModelProvider.instance),
      ),
    );
    await Amplify.configure(amplifyConfig);
  } on AmplifyAlreadyConfiguredException {
    safePrint('Amplify already configured.');
  }
}

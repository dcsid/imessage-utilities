import 'package:chat_utilities_hub/src/models/utility_instance.dart';

abstract class UtilityRepository {
  List<UtilityInstance> getAll();

  UtilityInstance? findById(String id);
}

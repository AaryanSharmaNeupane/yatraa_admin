import '../main.dart';

String getToken() {
  return sharedPreferences.getString("jwt-token")!;
}

double getCurrentLatitude() {
  return sharedPreferences.getDouble("latitude")!;
}

double getCurrentLongitude() {
  return sharedPreferences.getDouble("longitude")!;
}

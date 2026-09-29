// lib/core/native_app_stub.dart
// Android en `flutter test`: daar is geen website om vandaan te komen.

Future<bool> readIsNativeAppInstalled() async => false;

String currentRoute() => '/home';

void navigateTo(String url) {}

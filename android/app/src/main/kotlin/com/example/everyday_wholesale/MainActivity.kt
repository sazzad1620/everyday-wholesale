package com.example.everyday_wholesale

import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe requires a FlutterFragmentActivity (not the default
// FlutterActivity) — its native Android SDK needs Fragment support for the
// PaymentSheet / 3D Secure flow, and fails to initialize without it.
class MainActivity : FlutterFragmentActivity()

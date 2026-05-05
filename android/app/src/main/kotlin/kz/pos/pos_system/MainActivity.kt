package kz.pos.pos_system

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by the
// `local_auth` plugin — BiometricPrompt needs a FragmentActivity host.
// Functionally identical for everything else; the Flutter engine handles
// both the same way.
class MainActivity : FlutterFragmentActivity()

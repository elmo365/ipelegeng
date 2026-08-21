package bw.co.ipelege

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity, not FlutterActivity.
 *
 * local_auth shows AndroidX BiometricPrompt, which is a Fragment and therefore
 * needs a FragmentActivity to attach to. On a plain FlutterActivity the prompt
 * does not fail loudly — it throws `no_fragment_activity` at the moment the
 * user taps unlock, which is the worst possible place to find out.
 *
 * Nothing else in the app depends on the base class, so this is safe to keep
 * even if local_auth is ever removed.
 */
class MainActivity : FlutterFragmentActivity()

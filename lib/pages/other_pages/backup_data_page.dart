import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v2.dart';
import 'package:habitt/firebase_options.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:provider/provider.dart';

class BackupDataPage extends StatelessWidget {
  const BackupDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 48),
              Text(
                "Backup Data",
                style: TextStyle(
                  fontSize: 38,
                  color: tp.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Keep your data safe by backing it up to Google Drive.",
                style: TextStyle(fontSize: 16, color: tp.secondaryTextColor),
              ),
              const SizedBox(height: 32),
              Text(
                "You are currently not connected to your Google account.",
                style: TextStyle(fontSize: 16, color: tp.secondaryTextColor),
              ),
              DefaultButton(
                onPressed: () async {
                  try {
                    final googleSignIn = GoogleSignIn(
                      scopes: [DriveApi.driveFileScope],
                      // Needed on iOS so GIDSignIn has a client ID.
                      clientId: DefaultFirebaseOptions.ios.iosClientId,
                      serverClientId:
                          "752709751941-vt92fpp7ge9gs8cs4rrnlvrkk84aekmc.apps.googleusercontent.com",
                    );

                    final user = await googleSignIn.signIn();
                    if (user == null) return; // user cancelled

                    final auth = await user.authentication;
                    final credential = GoogleAuthProvider.credential(
                      accessToken: auth.accessToken,
                      idToken: auth.idToken,
                    );

                    await FirebaseAuth.instance.signInWithCredential(
                      credential,
                    );
                  } catch (e, st) {
                    debugPrint('Google sign-in failed: $e\n$st');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Google sign-in failed. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                },
                label: "Connect to Google",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

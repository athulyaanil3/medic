import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medi_background.dart';
import '../widgets/ui_kit.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final email =
        AuthService().getCurrentUser()?.email ??
            'Not signed in';

    return Scaffold(

      extendBodyBehindAppBar: true,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),

          onPressed: () =>
              Navigator.pop(context),
        ),

        title: const Text('Settings'),
      ),

      body: MediBackground(

        child: ListView(

          padding: EdgeInsets.only(
            top:
            MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                8,
            left: 20,
            right: 20,
            bottom: 24,
          ),

          children: [

            const PageHeader(
              title: 'Your account',
              subtitle:
              'Manage your account information.',
            ),

            // ACCOUNT CARD
            GlassCard(

              child: Row(
                children: [

                  const IconBadge(
                    icon: Icons.person_rounded,
                    size: 48,
                  ),

                  const SizedBox(width: 16),

                  Expanded(

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        const Text(
                          'Signed in as',

                          style: TextStyle(
                            color: AppTheme.inkMuted,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          email,

                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // LOGOUT BUTTON
            DecoratedBox(

              decoration: BoxDecoration(
                gradient:
                AppTheme.coralGradient,

                borderRadius:
                BorderRadius.circular(18),

                boxShadow: [
                  AppTheme.softShadow(0.15),
                ],
              ),

              child: Material(
                color: Colors.transparent,

                borderRadius:
                BorderRadius.circular(18),

                child: InkWell(

                  borderRadius:
                  BorderRadius.circular(18),

                  onTap: () async {

                    await AuthService().logout();

                    if (context.mounted) {

                      Navigator.of(context)
                          .pushAndRemoveUntil(

                        MaterialPageRoute<void>(
                          builder: (_) =>
                          const LoginScreen(),
                        ),

                            (_) => false,
                      );
                    }
                  },

                  child: const Padding(

                    padding:
                    EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    child: Row(

                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),

                        SizedBox(width: 10),

                        Text(

                          'Sign out',

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
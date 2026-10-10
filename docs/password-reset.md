# Password reset

The app uses an email code: select Forgot Password, enter your email on the dedicated screen, select Send code, enter the emailed code, then enter and confirm a new password. There is no need to open an email link.

In Supabase project `bjfuexqvlqwsysexmljw`, open Authentication → Email Templates → Reset password. Replace the body with `supabase/templates/password_recovery.html` and save. Keep `{{ .Token }}` in the body; Supabase replaces it with the recovery code. This template has not yet been published from this workspace because the current authenticated account cannot access the project.

The app verifies the code with `OtpType.recovery`. The existing authentication listener receives `AuthChangeEvent.passwordRecovery` and opens the existing reset-password screen. Expired codes can be replaced with Send a new code.

Build and run the updated app, request a fresh reset email, enter its code, set a password, then verify sign-in with the new password. A real email/device check is still required after publishing the template.

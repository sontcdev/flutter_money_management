# Password reset

The app uses an email code: select Forgot Password, enter your email on the dedicated screen, select Send code, enter the emailed code, then enter and confirm a new password. There is no need to open an email link.

In Supabase project `bjfuexqvlqwsysexmljw`, open Authentication → Email Templates → Reset password. Replace the body with `supabase/templates/password_recovery.html` and save. Keep `{{ .Token }}` in the body; Supabase replaces it with the recovery code. Publishing the hosted template remains pending production approval and a live email check.

`resetPasswordForEmail` asks Supabase Auth to generate the OTP, persist its hash in `auth.users.recovery_token` with `recovery_sent_at`, and send the recovery email. `verifyOTP(email, token, type: recovery)` checks the submitted code against this stored token server-side, including expiry, and consumes the token on success. The app receives a recovery session before it can update the password. The linked database's recovery columns were verified on 2026-10-10; no extra OTP table or client database access is required.

Never store plaintext OTPs in public tables or compare codes in Flutter. Supabase Auth owns token generation, persistence, verification, expiry, and rate limits.

The app verifies the code with `OtpType.recovery`. The existing authentication listener receives `AuthChangeEvent.passwordRecovery` and opens the existing reset-password screen. Expired codes can be replaced with Send a new code.

Build and run the updated app, request a fresh reset email, enter its code, set a password, then verify sign-in with the new password. A real email/device check is still required after publishing the template.

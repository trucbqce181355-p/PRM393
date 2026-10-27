# Supabase Google OAuth setup (Windows first)

See [auth_backend_setup.md](auth_backend_setup.md) for email registration, OTP,
backend sessions, MongoDB identities and the current run instructions.

## App configuration

Create the ignored `supabase.env.json` from `supabase.env.example.json`, configure
the Supabase project URL/publishable key and the Auth backend URL, then run
`run.bat` or the Windows VS Code launch configuration.

SMTP credentials belong only in `auth_backend/.env`; never put a server secret,
SMTP password or Google OAuth client secret in the Flutter configuration.

## Google provider

1. Enable Google in Supabase Authentication → Providers. Enter the Google OAuth
   Web client ID and client secret in the Supabase Dashboard.
2. Add the Supabase callback URI shown there to the Google OAuth client's
   authorized redirect URIs (normally `https://<project-ref>.supabase.co/auth/v1/callback`).
3. Add `com.example.traicay://login-callback` to Supabase Authentication →
   URL Configuration → Redirect URLs.
4. On Windows the system browser returns through the custom URL scheme registered
   by the runner. Android uses the matching activity intent filter.
5. Configure the same Supabase URL and publishable key in `auth_backend/.env`.
   The backend calls Supabase getUser to verify the access token before linking
   or creating a MongoDB profile.

Phone login is not part of the current business flow. A contact phone is still
collected in the personal profile. Supabase Auth handles Google identity;
Fruitopia Auth backend handles email/password, email OTP and application sessions.
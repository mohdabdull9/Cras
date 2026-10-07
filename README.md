# CTLRS • Supabase + GitHub deployment

This package is a production-oriented static frontend for the Comoros Tourism Licensing & Registration System (CTLRS), rebuilt from the supplied HTML prototype.

## Included
- `index.html` — responsive web application
- `config.example.js` — Supabase configuration template
- `supabase.sql` — database schema, RLS, Auth trigger, public license verification RPC and document storage bucket
- `.gitignore` — prevents local secrets from being committed
- `README.md` — deployment guide

## 1. Supabase
1. Open your existing Supabase project.
2. Go to **SQL Editor → New query**.
3. Paste all of `supabase.sql`.
4. Run it.
5. Go to **Authentication → Providers → Email** and keep Email enabled.
6. Create your first account from the CTLRS website.
7. In SQL Editor, promote that account:
   `update public.profiles set role='admin' where email='YOUR_ADMIN_EMAIL';`
8. Refresh the website.

## 2. Local configuration
Copy:
`config.example.js` → `config.js`

Put in:
- Project URL: Supabase **Project Settings → API → Project URL**
- Publishable/anon key: Supabase **Project Settings → API**

Only the public/anon key belongs in a static frontend. Never expose `service_role`.

## 3. GitHub
Create these files in your repository:
- `index.html`
- `config.js`
- `supabase.sql`
- `.gitignore`
- `README.md`

Do not commit a real secret key if your repository is public. The Supabase anon/publishable key is intended for browser use when RLS is correctly configured, but the project URL/key can still be managed as a GitHub Pages secret only if you later build through an action.

## 4. Free hosting option: GitHub Pages
1. Push the files to the repository's `main` branch.
2. GitHub → **Settings → Pages**.
3. Under Build and deployment choose **Deploy from a branch**.
4. Branch: `main`; folder: `/ (root)`.
5. Save.
6. Wait for GitHub to publish the site.
7. Open the generated `github.io` address.

## 5. Recommended alternative: Cloudflare Pages / Netlify / Vercel
Any static host can serve this project. Upload the repository and set the site root to the repository root. No Node build command is required.

## 6. First production setup
- Create one admin account.
- Create officer, inspector, director and finance accounts through Supabase Auth.
- Change their `profiles.role` values in SQL.
- Test operator registration with a separate email.
- Test an application from operator → officer → inspector → approval.
- Add payment records and issue a license.
- Test public license verification in a private browser window.

## Security notes
The original prototype used browser-local credentials and a shared JSON state. This version uses Supabase Auth for passwords and PostgreSQL Row Level Security for authorization. Do not disable RLS.

For a full production rollout, add server-side workflow functions/Edge Functions for sensitive actions such as issuing a license, generating official invoice numbers and changing high-risk roles.
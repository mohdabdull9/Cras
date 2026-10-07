# CTLRS — Comoros Tourism Licensing System

Free hosting on **GitHub Pages** (static site) + **Supabase** (shared database),
so the demo works for multiple people at the same time, from any device.

## Files in this folder
- `index.html` — the app (polished visuals, same features/logic as the original)
- `config.js` — your Supabase connection settings (fill in, see step 2)
- `supabase_schema.sql` — run once in Supabase to create the data table

---

## Step 1 — Get your Supabase credentials

1. Open your Supabase project (you said it's already created) → left sidebar **Project Settings → API**.
2. Copy two values:
   - **Project URL** (looks like `https://abcdxyz.supabase.co`)
   - **anon public** key (long string under "Project API keys")

## Step 2 — Create the database table

1. In Supabase, open **SQL Editor → New query**.
2. Paste the contents of `supabase_schema.sql` from this folder.
3. Click **Run**. You should see "Success. No rows returned."

## Step 3 — Fill in config.js

Open `config.js` and replace the placeholders:

```js
window.CTLRS_CONFIG = {
  SUPABASE_URL: "https://abcdxyz.supabase.co",   // your Project URL
  SUPABASE_ANON_KEY: "eyJhbGciOi...",              // your anon public key
  ROOM: "main"
};
```

Save the file.

## Step 4 — Push to GitHub

In your already-created repository folder:

```bash
# copy these 3 files into your repo folder, then:
git add index.html config.js supabase_schema.sql README.md
git commit -m "Deploy CTLRS with Supabase sync"
git push
```

(If you prefer the GitHub website: click **Add file → Upload files**, drag in
`index.html` and `config.js`, and commit.)

## Step 5 — Turn on GitHub Pages

1. On GitHub, open your repo → **Settings → Pages**.
2. Under "Build and deployment" → Source: **Deploy from a branch**.
3. Branch: `main` (or `master`), folder: `/ (root)`. Click **Save**.
4. Wait ~1 minute. GitHub shows your live URL at the top, e.g.:
   `https://yourusername.github.io/your-repo-name/`

Open that link — the system is now live and publicly hostable for free.

## Step 6 — Test the sync

1. Open the URL on two different browsers/devices.
2. Log in as `officer / off123` (or any demo account shown on each portal's
   sign-in screen) on each.
3. Make a change on one (e.g. verify a document) — within a few seconds the
   other screen should update automatically (polls every few seconds) or shows
   a "New data available → Refresh" banner.
4. Check the small sync badge near the clock: ☁️ Synced = Supabase is working.
   💾 Local = config.js isn't filled in or is unreachable (check values).

## Notes / safety

- The anon key is meant to be public in client code — it's fine to commit it.
  Access control comes from your Supabase **Row Level Security** policy
  (the schema file sets a permissive "demo" policy, matching the app's
  current prototype auth, which stores passwords in plain text in the
  shared record — **do not put real personal data in it** until migrating
  to proper Supabase Auth).
- To reset demo data for everyone, use the in-app "Réinitialiser la démo"
  button (Settings → Backup, or the homepage) — it works through Supabase
  too when configured.
- Each separate GitHub Pages deployment can use a different `ROOM` value
  in `config.js` to keep demo datasets independent while sharing one
  Supabase table.
- Custom domain (optional): Settings → Pages → add your domain, and add
  the DNS records GitHub shows you at your domain registrar.

That's the whole deployment — fully free (GitHub Pages hosting + Supabase
free tier database).

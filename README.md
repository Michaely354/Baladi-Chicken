# Baladi Chicken QR Menu

Arabic-first menu with 20 confirmed products, four categories, phone call links, a private owner dashboard, nullable prices, photo uploads, draft preview, atomic publication, conflict protection and recoverable removed items.

## What works now
- `dist/` contains the built Render-ready website.
- With no Supabase configuration, the public page is explicitly labeled design preview. `/admin/` offers a temporary demo whose edits are NOT saved or published.
- The 6 unpriced raw-chicken products have no public price label, zero, dash or placeholder.
- No contact form, checkout, paid AI, paid domain, or order system.

## Connect the free database (one-time)
1. Create a free Supabase project in your own account. Store your database password privately.
2. Open SQL Editor and execute `schema.sql` once in this NEW project. It creates menu tables, security rules, seeded content and an image bucket. Do not rerun it over existing production data.
3. Under Authentication settings, disable new public signups. In Authentication > Users, create the owner's email/password account privately, and copy its User UUID. The owner sets/receives the password privately; do not send it in chat.
4. Execute this in SQL Editor, replacing the placeholder:
   `insert into public.menu_owners(user_id) values ('OWNER-USER-UUID');`
5. Copy your project URL and **publishable key** (or legacy anon key). Never use the service-role/secret key in this website.
6. Supabase handles owner sessions and refresh. With an allowlist, another authenticated user cannot edit the menu even if they discover `/admin/`.

## Publish on Render (one-time)
1. Put this project's contents in your own GitHub repository (exclude `node_modules/`).
2. In Render choose New > Static Site and connect that repository. Do not choose a web-service compute plan.
3. Build command: `npm ci && npm run build`
4. Publish directory: `dist`
5. Add these Render build environment variables:
   - `SUPABASE_URL`: your project URL
   - `SUPABASE_PUBLISHABLE_KEY`: the public/publishable key
6. Deploy. `render.yaml` also supplies these settings for a Blueprint. Both `/menu/` and `/admin/` have actual generated index files; slashless paths have rewrite rules in the Blueprint.
7. In Supabase Authentication URL Configuration set Site URL to your new HTTPS Render URL. If you later add recovery emails, add only the exact recovery callback you implement; this version does not include a self-service password-recovery flow. The project administrator can manage owner access from Supabase.
8. Open `/admin/`, sign in, change one price, preview, save a draft, confirm the customer price is unchanged, then Save & publish and verify the new price in a fresh customer page. Test login and image uploads on the actual project; those cannot be end-to-end tested without your account.

## Daily use
Open the private `/admin/` link, sign in, edit prices and availability, and press حفظ ونشر. Drafts do not change the public menu. Empty prices stay blank. Removed items can be restored under الأصناف المحذوفة. Changes appear on public page load/refresh. Existing open customer pages do not update automatically.

## QR
Only generate the final QR after Render returns the stable URL. Do not print a QR for a temporary preview. Run:
`python -m pip install 'qrcode[pil]'`
`python make_qr.py https://YOUR-ACTUAL-SITE.onrender.com/menu/`
It writes `Baladi_Chicken_QR.png` and `.svg`, encoding the supplied URL unchanged. Scan-test before printing.

## Important free-plan limits
No paid service or automatic paid upgrade is required by this code. Free hosting/database quotas and inactivity policies still apply and can change. Supabase free projects may pause after inactivity. Check current official terms before launch:
- https://render.com/docs/static-sites
- https://render.com/docs/free
- https://supabase.com/pricing
Export your menu periodically from Supabase for backup. Immutable uploaded images are not automatically deleted when replaced; remove unused assets from Supabase Storage occasionally to stay within storage limits.

## Brand assets
The currently included logo is a cropped high-resolution rendering of the supplied print PDF, retaining the original rooster, flames, skewers, lettering and ribbon. Replace `dist/assets/logo.png` with the original standalone logo when supplied. No generated food imagery is included. Cairo font loads from Google Fonts with a local system-font fallback.

## Development / validation
`npm ci`
`npm run check`
`npm run build`
`node test-database.mjs`

The database test uses an isolated in-memory PostgreSQL instance with mock Supabase auth roles. It checks public read-only access, owner-only write authorization, private draft visibility, atomic publish, null prices, invalid-write rollback, concurrency conflict handling and public exclusion of hidden products. Supabase Storage/auth-network integration requires the actual project for final verification.

The database has been provisioned in Supabase. Hosting is configured for Render. Owner activation uses a private, expiring, single-use setup link supplied separately; do not commit or share that link. The browser sends the chosen email/password directly over HTTPS to the owner-setup function, which validates the token before creating the owner. No service-role key is shipped to the client.

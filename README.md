# Baladi Chicken QR menu

Live menu: https://baladi-chicken-menu.onrender.com/menu/
Owner dashboard: https://baladi-chicken-menu.onrender.com/admin/

Arabic-first customer menu, an English price editor, and persistent Supabase data. Render serves the static frontend. Free-tier usage limits apply.

## Daily use
1. Sign in to `/admin/` with the existing owner account.
2. Search in English or Arabic, or choose a category.
3. Select one product, enter its new price, and press **Save changes**.

A blank price stays blank on the customer menu. An availability switch marks an item sold out. **More options** contains name, category, description, photo, visibility and removal controls. Removed items can be restored. Add-product controls are secondary.

Each save publishes only the selected product atomically. Unrelated unpublished draft changes are preserved. Customers see changes on their next visit or refresh. The menu URL and QR code stay unchanged.

## Design
The latest supplied menu artwork supplies the logo, vivid red/cream/gold palette and bold Arabic direction. The original composite logo is displayed without redrawing it. Cairo and Manrope font weights are self-hosted in `dist/assets/fonts/fonts.css`; font licenses are included alongside it. There is no stock or generated food imagery and no contact form.

## Build
`npm ci`
`npm run check`
`npm run build`

Render: Static Site; build command `npm ci && npm run build`; publish directory `dist`.
Set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as build variables. The public client must never contain service-role/secret keys.

## Database
The live project already has its schema. Do not rerun initial setup SQL against it.
For a NEW installation, execute `schema.sql` followed by `product-update.sql`. The owner allowlist is private; only authorized owners may use the update functions. Row-level security and explicit grants restrict public clients to published reads. The image bucket permits new immutable owner uploads only.

`functions/owner-setup.ts` preserves the original one-time activation endpoint. Its private setup record/token is configured separately and must never be committed. The existing owner's login remains valid.

## Validation
`node test-database.mjs`

Tests use an isolated PostgreSQL runtime with Supabase auth-role stubs. They check public read-only access, the owner allowlist, private drafts, atomic publication, null prices, invalid-write rollback, concurrency conflicts, hidden-product exclusion and single-product saves that preserve unrelated draft edits. A transaction-and-rollback check also verified the per-product save on the live database without changing menu prices. Phone layouts and search/edit flows are reviewed in the browser.

## QR
`python -m pip install 'qrcode[pil]'`
`python make_qr.py https://baladi-chicken-menu.onrender.com/menu/`

The original QR remains valid through design or price updates. Export menu backups periodically from Supabase. Free projects may pause after inactivity; check current service limits before relying on guaranteed availability.

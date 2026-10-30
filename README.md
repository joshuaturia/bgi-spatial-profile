# Consultant spatial profile

A single-page dashboard that profiles which spatial outputs each consultant on a project produces, which specifications they set and which GIS products they depend on, and checks their timing against the GIS deliverables.

**Live page:** https://joshuaturia.github.io/bgi-spatial-profile/

The page is public. The data is not:

- **Without signing in**, the page shows placeholder data from `data/sample.json`.
- **Signed-in users on the allow-list** see the project dataset, which is stored in Supabase and never committed to this repository.

## How the security works

| Layer | What it does |
|---|---|
| Public repo | Code, layout and placeholder data only |
| `config.js` | Supabase URL and anon key. These are public by design and grant no data access on their own |
| Supabase Auth | Email sign-in links. New sign-ups are disabled; users must be invited |
| Row-level security | Every table is locked. Rows are returned only to signed-in users whose email is in `allowed_users` |
| No write access | The public API can't insert, update or delete. Data is edited in the Supabase dashboard |

Never put the Supabase **service_role** key in this repository.

## Setup

### 1. Supabase project
1. Create a project at [supabase.com](https://supabase.com).
2. In **SQL Editor**, run `supabase/schema.sql`.
3. Run your private data seed file (kept outside this repo). To test with placeholder rows, run `supabase/seed-sample.sql` instead.
4. Add each person who may see the data:
   ```sql
   insert into public.allowed_users (email, note) values ('person@example.org', 'project manager');
   ```

### 2. Authentication
1. **Authentication → Sign In / Providers**: turn off **Allow new users to sign up**. Keep **Email** enabled.
2. **Authentication → Users → Invite user**: invite each allow-listed email.
3. **Authentication → URL Configuration**: set **Site URL** to the live page URL above and add it under **Redirect URLs**.

### 3. Connect the page
Edit `config.js` with the **Project URL** and the **anon / publishable** key from **Project Settings → API Keys**, then commit.

### 4. GitHub Pages
**Settings → Pages → Build and deployment**: Source **Deploy from a branch**, branch `main`, folder `/ (root)`.

## Editing the data
Use the Supabase **Table Editor**:

- `spatial_elements`: one row per spatial element. `direction` is `in` (data comes to GIS), `spec` (sets a specification) or `out` (GIS supplies it). `feeds` lists the GIS deliverables it feeds, e.g. `{D2,D3}`.
- `consultants`, `themes`, `gis_deliverables`: lookups. Months count from January of `base_year`.
- `dashboard_settings`: page text (`meta`), the GIS lane (`gis`) and the implications cards (`plan`), stored as JSON.

## Files
```
index.html              the dashboard
config.js               Supabase connection (public values only)
data/sample.json        placeholder dataset
supabase/schema.sql     tables and row-level security
supabase/seed-sample.sql  placeholder rows for testing
```

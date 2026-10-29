# Jami Vhora – Video Portfolio (Next.js + Supabase)

## Status
Done: database schema, RLS, storage policies, secure video-URL parser.
Still to build: Next.js app (public pages, /admin UI, server actions), tests, deployment.

## Supabase setup
1. Create a project at supabase.com.
2. Authentication > Providers > Email: **disable "Allow new users to sign up"** (no public registration).
3. SQL Editor: paste and run `supabase/migrations/001_init.sql`. This creates tables, RLS policies and the `thumbnails` bucket (5 MB, JPG/PNG/WebP, public read, admin-only write).
4. Authentication > Users > **Add user** (your email + password, auto-confirm).
5. SQL Editor, make yourself the first admin:
   `insert into public.admins (user_id) select id from auth.users where email = 'jamivhora043@gmail.com';`
6. Copy URL + anon key (Project Settings > API) into `.env.local` using `.env.example`.

## GitHub and Vercel
Push to a new GitHub repo, import it in Vercel, add the same three env vars, deploy.
Later updates: `git push` redeploys automatically.

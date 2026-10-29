create extension if not exists pgcrypto;

create table public.admins (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  description text check (char_length(description) <= 300),
  display_order int not null default 0,
  is_visible boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  description text check (char_length(description) <= 500),
  client_name text check (char_length(client_name) <= 80),
  category_id uuid not null references public.categories(id) on delete restrict,
  video_url text not null,
  video_provider text not null check (video_provider in ('youtube','youtube_short','vimeo','mp4')),
  thumbnail_url text,
  is_featured boolean not null default false,
  display_order int not null default 0,
  status text not null default 'draft' check (status in ('draft','published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index projects_category_idx on public.projects(category_id);
create index projects_public_idx on public.projects(status, display_order);

create table public.site_settings (
  id int primary key default 1 check (id = 1),
  portfolio_title text not null default 'Jami Vhora',
  hero_title text not null default 'Visual Stories. Crafted Frame by Frame.',
  hero_subtitle text not null default 'Video Editor & Cinematographer creating engaging reels, YouTube videos, and visual content for brands.',
  display_name text not null default 'Jami Vhora',
  instagram_url text default 'https://instagram.com/_explorewithjami_',
  contact_email text default 'jamivhora043@gmail.com',
  whatsapp_number text default '+917284870201',
  footer_text text default '© Jami Vhora',
  updated_at timestamptz not null default now()
);
insert into public.site_settings (id) values (1);

insert into public.categories (name, slug, display_order) values ('YouTube','youtube',1),('Reels','reels',2);

create function public.is_admin() returns boolean
language sql security definer stable set search_path = public as
$$ select exists (select 1 from public.admins where user_id = auth.uid()) $$;

create function public.touch_updated_at() returns trigger language plpgsql as
$$ begin new.updated_at = now(); return new; end $$;
create trigger t_cat before update on public.categories for each row execute function public.touch_updated_at();
create trigger t_proj before update on public.projects for each row execute function public.touch_updated_at();
create trigger t_set before update on public.site_settings for each row execute function public.touch_updated_at();

alter table public.admins enable row level security;
alter table public.categories enable row level security;
alter table public.projects enable row level security;
alter table public.site_settings enable row level security;

-- admins table: no policies = no client access (only service role / SQL editor)
create policy "public reads visible categories" on public.categories for select using (is_visible or public.is_admin());
create policy "admin writes categories" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "public reads published projects" on public.projects for select using (status = 'published' or public.is_admin());
create policy "admin writes projects" on public.projects for all using (public.is_admin()) with check (public.is_admin());
create policy "public reads settings" on public.site_settings for select using (true);
create policy "admin updates settings" on public.site_settings for update using (public.is_admin()) with check (public.is_admin());

-- thumbnails bucket: public read, admin-only write, 5 MB, images only
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('thumbnails','thumbnails',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy "public reads thumbnails" on storage.objects for select using (bucket_id = 'thumbnails');
create policy "admin writes thumbnails" on storage.objects for insert with check (bucket_id='thumbnails' and public.is_admin());
create policy "admin updates thumbnails" on storage.objects for update using (bucket_id='thumbnails' and public.is_admin());
create policy "admin deletes thumbnails" on storage.objects for delete using (bucket_id='thumbnails' and public.is_admin());

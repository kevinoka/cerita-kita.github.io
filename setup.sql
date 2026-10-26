-- =========================================================
-- Cerita Kita: setup database Supabase
-- Jalankan sekali di Supabase > SQL Editor > New query > Run
-- GANTI email di baris paling bawah dengan email akun kamu.
-- =========================================================

-- Daftar admin (yang boleh mengubah isi)
create table if not exists public.admins (email text primary key);

create table if not exists public.settings (
  id int primary key default 1 check (id = 1),
  name_a text, name_b text,
  met date, dating date, wed date,
  updated_at timestamptz default now()
);

create table if not exists public.milestones (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('kenalan','pacaran','nikah','anak','lain')),
  date date not null,
  title text not null,
  story text default '',
  photo_path text,
  created_at timestamptz default now()
);

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  album text not null check (album in ('nikah','sekarang')),
  date date,
  caption text default '',
  path text not null,
  created_at timestamptz default now()
);

-- Cek apakah user yang sedang login adalah admin
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where email = lower(auth.jwt() ->> 'email'));
$$;
grant execute on function public.is_admin() to authenticated;

-- Row Level Security: semua akun yang login boleh LIHAT, hanya admin boleh UBAH
alter table public.admins     enable row level security;  -- tanpa policy = tidak bisa dibaca dari aplikasi
alter table public.settings   enable row level security;
alter table public.milestones enable row level security;
alter table public.photos     enable row level security;

do $$
declare t text;
begin
  foreach t in array array['settings','milestones','photos'] loop
    execute format('drop policy if exists "baca" on public.%I', t);
    execute format('drop policy if exists "admin tambah" on public.%I', t);
    execute format('drop policy if exists "admin ubah" on public.%I', t);
    execute format('drop policy if exists "admin hapus" on public.%I', t);
    execute format('create policy "baca" on public.%I for select to authenticated using (true)', t);
    execute format('create policy "admin tambah" on public.%I for insert to authenticated with check (public.is_admin())', t);
    execute format('create policy "admin ubah" on public.%I for update to authenticated using (public.is_admin()) with check (public.is_admin())', t);
    execute format('create policy "admin hapus" on public.%I for delete to authenticated using (public.is_admin())', t);
  end loop;
end $$;

-- Tempat foto (privat, hanya bisa dibuka akun yang login)
insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do update set public = false;

drop policy if exists "cerita baca foto"  on storage.objects;
drop policy if exists "cerita unggah foto" on storage.objects;
drop policy if exists "cerita ubah foto"  on storage.objects;
drop policy if exists "cerita hapus foto" on storage.objects;
create policy "cerita baca foto"  on storage.objects for select to authenticated using (bucket_id = 'photos');
create policy "cerita unggah foto" on storage.objects for insert to authenticated with check (bucket_id = 'photos' and public.is_admin());
create policy "cerita ubah foto"  on storage.objects for update to authenticated using (bucket_id = 'photos' and public.is_admin());
create policy "cerita hapus foto" on storage.objects for delete to authenticated using (bucket_id = 'photos' and public.is_admin());

-- >>> GANTI dengan email akun kamu (admin) <<<
insert into public.admins (email) values (lower('email-kamu@contoh.com'))
on conflict do nothing;

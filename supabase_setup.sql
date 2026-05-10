-- ============================================================
-- SHARKSPEAK v3 — Supabase Setup Completo
-- Rode no Supabase > SQL Editor > New Query > Run
-- ============================================================

create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- ============================================================
-- TABELAS
-- ============================================================

create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  name text,
  role text not null default 'assembler' check (role in ('programmer','assembler','admin')),
  avatar_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  title text not null default 'Nova Missão',
  description text,
  steps jsonb not null default '[]'::jsonb,
  color text not null default '#A77BFF',
  zero_x integer not null default 0,
  zero_y integer not null default 0,
  is_active boolean default true,
  created_by uuid references public.profiles(id) on delete set null,
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_id uuid,
  target_type text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- Atualiza banco antigo sem perder dados
alter table public.missions add column if not exists color text not null default '#A77BFF';
alter table public.missions add column if not exists zero_x integer not null default 0;
alter table public.missions add column if not exists zero_y integer not null default 0;
alter table public.missions add column if not exists description text;
alter table public.missions add column if not exists is_active boolean default true;
alter table public.missions add column if not exists created_by uuid references public.profiles(id) on delete set null;
alter table public.missions add column if not exists updated_by uuid references public.profiles(id) on delete set null;
alter table public.missions add column if not exists created_at timestamptz default now();
alter table public.missions add column if not exists updated_at timestamptz default now();

-- ============================================================
-- RLS
-- ============================================================

alter table public.profiles enable row level security;
alter table public.missions enable row level security;
alter table public.activity_logs enable row level security;

drop policy if exists "profiles_select" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_update_admin" on public.profiles;
drop policy if exists "missions_select" on public.missions;
drop policy if exists "missions_insert" on public.missions;
drop policy if exists "missions_update" on public.missions;
drop policy if exists "missions_delete" on public.missions;
drop policy if exists "logs_select_admin" on public.activity_logs;
drop policy if exists "logs_insert" on public.activity_logs;

create policy "profiles_select"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "profiles_update_admin"
  on public.profiles for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

create policy "missions_select"
  on public.missions for select
  using (auth.role() = 'authenticated');

create policy "missions_insert"
  on public.missions for insert
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('programmer','admin')));

create policy "missions_update"
  on public.missions for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('programmer','admin')))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('programmer','admin')));

create policy "missions_delete"
  on public.missions for delete
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('programmer','admin')));

create policy "logs_select_admin"
  on public.activity_logs for select
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

create policy "logs_insert"
  on public.activity_logs for insert
  with check (auth.role() = 'authenticated');

-- ============================================================
-- FUNÇÕES / TRIGGERS
-- ============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'assembler')
  )
  on conflict (id) do update set
    email = excluded.email,
    name = coalesce(public.profiles.name, excluded.name),
    updated_at = now();

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
  for each row execute procedure public.touch_updated_at();

drop trigger if exists missions_touch on public.missions;
create trigger missions_touch before update on public.missions
  for each row execute procedure public.touch_updated_at();

create or replace function public.set_user_role(target_email text, new_role text)
returns void as $$
begin
  if new_role not in ('admin','programmer','assembler') then
    raise exception 'Role inválida: %', new_role;
  end if;

  update public.profiles
  set role = new_role, updated_at = now()
  where email = target_email;
end;
$$ language plpgsql security definer set search_path = public;

-- ============================================================
-- COMANDOS ÚTEIS
-- ============================================================
-- Promover você para admin depois de criar a conta pelo site:
-- select public.set_user_role('tomboly.academico@gmail.com', 'admin');

-- Ver usuários:
-- select id, email, name, role, created_at from public.profiles order by created_at desc;

-- Ver missões:
-- select id, title, color, zero_x, zero_y, jsonb_array_length(steps) as etapas, updated_at
-- from public.missions order by updated_at desc;

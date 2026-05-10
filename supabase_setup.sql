-- ============================================================
-- SHARKSPEAK v2 — Supabase Setup Completo
-- Cole tudo no SQL Editor e clique em Run
-- ============================================================

-- 1. Extensões necessárias
create extension if not exists "uuid-ossp";

-- 2. Tabela de perfis
create table if not exists public.profiles (
  id          uuid references auth.users on delete cascade primary key,
  email       text not null,
  name        text,
  role        text not null default 'assembler'
                check (role in ('programmer', 'assembler', 'admin')),
  avatar_url  text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- 3. Tabela de missões
create table if not exists public.missions (
  id          uuid primary key default gen_random_uuid(),
  title       text not null default 'Nova Missão',
  description text,
  steps       jsonb not null default '[]',
  color       text default '#A77BFF',
  is_active   boolean default true,
  created_by  uuid references public.profiles(id) on delete set null,
  updated_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- 4. Tabela de logs de atividade
create table if not exists public.activity_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles(id) on delete set null,
  action      text not null,
  target_id   uuid,
  target_type text,
  metadata    jsonb default '{}',
  created_at  timestamptz default now()
);

-- ============================================================
-- 5. Row Level Security
-- ============================================================
alter table public.profiles     enable row level security;
alter table public.missions      enable row level security;
alter table public.activity_logs enable row level security;

-- Limpar políticas antigas se existirem
drop policy if exists "profiles_select"        on public.profiles;
drop policy if exists "profiles_update_own"    on public.profiles;
drop policy if exists "missions_select"        on public.missions;
drop policy if exists "missions_insert"        on public.missions;
drop policy if exists "missions_update"        on public.missions;
drop policy if exists "missions_delete"        on public.missions;
drop policy if exists "logs_select_admin"      on public.activity_logs;
drop policy if exists "logs_insert"            on public.activity_logs;

-- Profiles: todos autenticados leem, cada um edita o próprio
create policy "profiles_select"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

-- Missions: todos leem
create policy "missions_select"
  on public.missions for select
  using (auth.role() = 'authenticated');

-- Missions: só programmer e admin criam/editam/deletam
create policy "missions_insert"
  on public.missions for insert
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('programmer', 'admin')
    )
  );

create policy "missions_update"
  on public.missions for update
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('programmer', 'admin')
    )
  );

create policy "missions_delete"
  on public.missions for delete
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('programmer', 'admin')
    )
  );

-- Logs: admin lê tudo, todos podem inserir
create policy "logs_select_admin"
  on public.activity_logs for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "logs_insert"
  on public.activity_logs for insert
  with check (auth.role() = 'authenticated');

-- ============================================================
-- 6. Funções e Triggers
-- ============================================================

-- Trigger: criar perfil automaticamente ao cadastrar
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
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger: atualizar updated_at
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch
  before update on public.profiles
  for each row execute procedure public.touch_updated_at();

drop trigger if exists missions_touch on public.missions;
create trigger missions_touch
  before update on public.missions
  for each row execute procedure public.touch_updated_at();

-- ============================================================
-- 7. Função pública para promover usuário (só admin chama)
-- ============================================================
create or replace function public.set_user_role(target_email text, new_role text)
returns void as $$
begin
  if new_role not in ('admin', 'programmer', 'assembler') then
    raise exception 'Role inválida: %', new_role;
  end if;
  update public.profiles set role = new_role where email = target_email;
end;
$$ language plpgsql security definer;

-- ============================================================
-- COMANDOS ÚTEIS (rode no SQL Editor conforme precisar):
-- ============================================================
-- Promover para admin:
--   select public.set_user_role('email@exemplo.com', 'admin');
--
-- Promover para programmer:
--   select public.set_user_role('email@exemplo.com', 'programmer');
--
-- Ver todos os usuários:
--   select id, email, name, role, created_at from public.profiles order by created_at;
--
-- Ver logs de atividade:
--   select l.*, p.name from public.activity_logs l
--   join public.profiles p on p.id = l.user_id
--   order by l.created_at desc limit 50;
-- ============================================================

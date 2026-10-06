create table if not exists public.binders (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  description text not null default '',
  page_count int not null default 1 check (page_count > 0),
  slots_per_page int not null default 9 check (slots_per_page > 0),
  category text not null default '',
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),

  unique (user_id, name)
);

create table if not exists public.cards (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  set_name text not null default '',
  card_number text not null default '',
  rarity text not null default '',
  type text not null default 'colorless',
  supertype text not null default 'pokemon',
  subtype text,
  quantity_owned int not null default 1 check (quantity_owned >= 0),
  condition text not null default 'NM',
  binder_name text not null default 'Unassigned',
  page int not null default 0 check (page >= 0),
  estimated_value numeric not null default 0 check (estimated_value >= 0),
  notes text not null default '',
  image_asset_path text,
  date_added timestamptz not null default now()
);

create table if not exists public.decks (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  format text not null default 'standard',
  target_size int not null default 60 check (target_size > 0),
  description text not null default '',
  is_pinned boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.deck_cards (
  deck_id text not null references public.decks (id) on delete cascade,

  card_id text not null references public.cards (id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  primary key (deck_id, card_id)
);

create table if not exists public.wishlist_entries (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  set_name text not null default '',
  card_number text not null default '',
  rarity text not null default '',
  condition text not null default 'NM',
  quantity int not null default 1 check (quantity > 0),
  notes text not null default '',
  kind text not null default 'wishlist',
  priority text not null default 'medium',
  estimated_value numeric not null default 0 check (estimated_value >= 0),
  asking_for text not null default '',
  source_card_id text,
  image_asset_path text,
  date_added timestamptz not null default now()
);

create table if not exists public.trainer_profiles (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  title text not null default 'Gym Leader',
  bio text,
  favorite_card_id text,
  favorite_binder_id text,
  favorite_deck_id text
);

create index if not exists cards_user_added_idx on public.cards (user_id, date_added, id);
create index if not exists cards_user_binder_idx on public.cards (user_id, binder_name);
create index if not exists binders_user_created_idx on public.binders (user_id, created_at, id);
create index if not exists decks_user_created_idx on public.decks (user_id, created_at, id);
create index if not exists deck_cards_card_id_idx on public.deck_cards (card_id);
create index if not exists wishlist_entries_user_added_idx
  on public.wishlist_entries (user_id, date_added, id);
drop index if exists public.cards_user_id_idx;
drop index if exists public.cards_binder_name_idx;
drop index if exists public.binders_user_id_idx;
drop index if exists public.decks_user_id_idx;
drop index if exists public.wishlist_entries_user_id_idx;

alter table public.binders enable row level security;
alter table public.cards enable row level security;
alter table public.decks enable row level security;
alter table public.deck_cards enable row level security;
alter table public.wishlist_entries enable row level security;
alter table public.trainer_profiles enable row level security;

drop policy if exists "Owner can manage binders" on public.binders;
create policy "Owner can manage binders" on public.binders
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Owner can manage cards" on public.cards;
create policy "Owner can manage cards" on public.cards
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Owner can manage decks" on public.decks;
create policy "Owner can manage decks" on public.decks
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Owner can manage deck_cards" on public.deck_cards;
create policy "Owner can manage deck_cards" on public.deck_cards
  for all to authenticated
  using (
    (select auth.uid()) = (select user_id from public.decks where id = deck_id)
  )
  with check (
    (select auth.uid()) = (select user_id from public.decks where id = deck_id)
    and (select auth.uid()) = (select user_id from public.cards where id = card_id)
  );

drop policy if exists "Owner can manage wishlist_entries" on public.wishlist_entries;
create policy "Owner can manage wishlist_entries" on public.wishlist_entries
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Owner can manage trainer_profiles" on public.trainer_profiles;
create policy "Owner can manage trainer_profiles" on public.trainer_profiles
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.trainer_profiles (user_id, name)
  values (
    new.id,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'trainer_name'), ''), 'Trainer')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table if not exists public.card_sets (
  id text primary key,
  name text not null,
  series text not null default '',

  printed_total int,
  total int,
  release_date date,
  logo_url text,
  symbol_url text
);

create table if not exists public.card_catalog (
  id text primary key,
  set_id text not null references public.card_sets (id) on delete cascade,

  number text not null,
  name text not null,
  supertype text not null default 'pokemon',
  subtype text,
  type text not null default 'colorless',

  rarity text not null default 'Other/Additional Rarities',
  rarity_raw text,
  image_small text,
  image_large text,

  market_price_usd numeric check (market_price_usd >= 0),
  price_updated_at timestamptz
);

create index if not exists card_catalog_set_name_idx on public.card_catalog (set_id, name, id);
drop index if exists public.card_catalog_set_id_idx;
create index if not exists card_catalog_name_idx on public.card_catalog (name);

create extension if not exists pg_trgm with schema extensions;
create index if not exists card_catalog_name_trgm_idx
  on public.card_catalog using gin (name extensions.gin_trgm_ops);

alter table public.card_sets enable row level security;
alter table public.card_catalog enable row level security;

drop policy if exists "Signed-in users can read card_sets" on public.card_sets;
create policy "Signed-in users can read card_sets" on public.card_sets
  for select to authenticated
  using (true);

drop policy if exists "Signed-in users can read card_catalog" on public.card_catalog;
create policy "Signed-in users can read card_catalog" on public.card_catalog
  for select to authenticated
  using (true);

alter table public.cards
  add column if not exists catalog_id text
  references public.card_catalog (id) on delete set null;
create index if not exists cards_catalog_id_idx on public.cards (catalog_id);

alter table public.card_catalog
  add column if not exists prices jsonb;

alter table public.cards
  add column if not exists finish text;

alter table public.wishlist_entries
  add column if not exists catalog_id text;
alter table public.wishlist_entries
  add column if not exists finish text;

alter table public.trainer_profiles
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Owner can read own avatar" on storage.objects;
create policy "Owner can read own avatar" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Owner can upload own avatar" on storage.objects;
create policy "Owner can upload own avatar" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Owner can replace own avatar" on storage.objects;
create policy "Owner can replace own avatar" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Owner can delete own avatar" on storage.objects;
create policy "Owner can delete own avatar" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

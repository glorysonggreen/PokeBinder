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

delete from public.wishlist_entries w
where w.source_card_id is not null
  and not exists (select 1 from public.cards c where c.id = w.source_card_id);

update public.trainer_profiles p
set favorite_card_id = null
where p.favorite_card_id is not null
  and not exists (select 1 from public.cards c where c.id = p.favorite_card_id);

update public.trainer_profiles p
set favorite_binder_id = null
where p.favorite_binder_id is not null
  and not exists (select 1 from public.binders b where b.id = p.favorite_binder_id);

update public.trainer_profiles p
set favorite_deck_id = null
where p.favorite_deck_id is not null
  and not exists (select 1 from public.decks d where d.id = p.favorite_deck_id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'wishlist_entries_source_card_id_fkey'
  ) then
    alter table public.wishlist_entries
      add constraint wishlist_entries_source_card_id_fkey
      foreign key (source_card_id) references public.cards (id) on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trainer_profiles_favorite_card_id_fkey'
  ) then
    alter table public.trainer_profiles
      add constraint trainer_profiles_favorite_card_id_fkey
      foreign key (favorite_card_id) references public.cards (id) on delete set null;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trainer_profiles_favorite_binder_id_fkey'
  ) then
    alter table public.trainer_profiles
      add constraint trainer_profiles_favorite_binder_id_fkey
      foreign key (favorite_binder_id) references public.binders (id) on delete set null;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trainer_profiles_favorite_deck_id_fkey'
  ) then
    alter table public.trainer_profiles
      add constraint trainer_profiles_favorite_deck_id_fkey
      foreign key (favorite_deck_id) references public.decks (id) on delete set null;
  end if;
end
$$;

create index if not exists wishlist_entries_source_card_idx
  on public.wishlist_entries (source_card_id);
create index if not exists wishlist_entries_user_kind_idx
  on public.wishlist_entries (user_id, kind);

do $$
begin
  create unique index if not exists binders_user_name_lower_idx
    on public.binders (user_id, lower(name));
exception
  when unique_violation then
    raise notice 'Two binders share a name apart from capitalization. Rename one, then run this script again.';
end
$$;

create or replace function public.sync_cards_on_binder_rename()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.name is distinct from old.name then
    update public.cards
    set binder_name = new.name
    where user_id = new.user_id and binder_name = old.name;
  end if;
  return new;
end;
$$;

create or replace function public.unassign_cards_on_binder_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update public.cards
  set binder_name = 'Unassigned', page = 0
  where user_id = old.user_id and binder_name = old.name;
  return old;
end;
$$;

revoke execute on function public.sync_cards_on_binder_rename() from public, anon, authenticated;
revoke execute on function public.unassign_cards_on_binder_delete() from public, anon, authenticated;

drop trigger if exists binders_rename_cards on public.binders;
create trigger binders_rename_cards
  after update of name on public.binders
  for each row execute function public.sync_cards_on_binder_rename();

drop trigger if exists binders_unassign_cards on public.binders;
create trigger binders_unassign_cards
  after delete on public.binders
  for each row execute function public.unassign_cards_on_binder_delete();

-- ---------------------------------------------------------------------------
-- Length limits
--
-- The app already stops people typing past these numbers (see
-- lib/config/field_limits.dart). These constraints repeat the same limits in the
-- database, so they still apply if someone skips the app and calls the API
-- directly. Keep the two lists in sync.
--
-- The constraints are added NOT VALID: new inserts and updates are checked, but
-- rows that already exist are not scanned, so this script can be re-run on a
-- database that has older, longer data. A row that is already over a limit must
-- be shortened the next time it is edited. To check everything that was saved
-- earlier, run:  alter table public.<table> validate constraint <name>;
-- ---------------------------------------------------------------------------

do $$
declare
  r record;
  cname text;
begin
  -- Free text and short app-controlled text: at most max_len characters.
  for r in
    select * from (values
      ('binders',           'name',            40),
      ('binders',           'category',        30),
      ('binders',           'description',    300),
      ('cards',             'name',            80),
      ('cards',             'set_name',        80),
      ('cards',             'card_number',     20),
      ('cards',             'notes',          500),
      ('cards',             'binder_name',     40),
      ('cards',             'rarity',          60),
      ('cards',             'type',            60),
      ('cards',             'supertype',       60),
      ('cards',             'subtype',         60),
      ('cards',             'condition',       10),
      ('decks',             'name',            40),
      ('decks',             'description',    300),
      ('decks',             'format',          30),
      ('wishlist_entries',  'name',            80),
      ('wishlist_entries',  'set_name',        80),
      ('wishlist_entries',  'card_number',     20),
      ('wishlist_entries',  'rarity',          60),
      ('wishlist_entries',  'condition',       10),
      ('wishlist_entries',  'notes',          500),
      ('wishlist_entries',  'asking_for',     200),
      ('wishlist_entries',  'kind',            20),
      ('wishlist_entries',  'priority',        20),
      ('trainer_profiles',  'name',            30),
      ('trainer_profiles',  'title',           40),
      ('trainer_profiles',  'bio',            160)
    ) as t(tbl, col, max_len)
  loop
    cname := r.tbl || '_' || r.col || '_length_check';
    if not exists (
      select 1 from pg_constraint
      where conname = cname
        and conrelid = format('public.%I', r.tbl)::regclass
    ) then
      execute format(
        'alter table public.%I add constraint %I check (char_length(%I) <= %s) not valid',
        r.tbl, cname, r.col, r.max_len
      );
    end if;
  end loop;

  -- Numbers typed into the app: an upper bound as well as the existing minimum.
  for r in
    select * from (values
      ('binders',          'page_count',      999),
      ('cards',            'quantity_owned',  99999),
      ('cards',            'page',            999),
      ('cards',            'estimated_value', 999999999.99),
      ('wishlist_entries', 'quantity',        99999),
      ('wishlist_entries', 'estimated_value', 999999999.99)
    ) as t(tbl, col, max_val)
  loop
    cname := r.tbl || '_' || r.col || '_max_check';
    if not exists (
      select 1 from pg_constraint
      where conname = cname
        and conrelid = format('public.%I', r.tbl)::regclass
    ) then
      execute format(
        'alter table public.%I add constraint %I check (%I <= %s) not valid',
        r.tbl, cname, r.col, r.max_val
      );
    end if;
  end loop;
end
$$;

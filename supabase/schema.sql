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
  -- A card finds its binder by matching `binder_name` against this `name`
  -- (see BinderData.pages), so two binders sharing a name for one user
  -- would silently merge their cards. This constraint is what actually
  -- prevents that, since nothing in the Flutter layer checks for it.
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

-- A deck's card list (DeckData.cards). Kept in its own table since it's a
-- one-to-many list, not a scalar column on decks.
create table if not exists public.deck_cards (
  deck_id text not null references public.decks (id) on delete cascade,
  -- Previously had no reference to `cards` at all, so deleting a card left
  -- its deck_cards rows behind pointing at a ghost id.
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

-- One row per user: TrainerProfileData. user_id is the primary key rather
-- than a plain column, since there's exactly one profile per account.
create table if not exists public.trainer_profiles (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  title text not null default 'Gym Leader',
  bio text,
  favorite_card_id text,
  favorite_binder_id text,
  favorite_deck_id text
);

-- Postgres doesn't index foreign keys automatically. Every `loadAll` filters
-- by the RLS-checked `user_id`, and BinderData.pages/cardCount filter cards
-- by `binder_name`, so both are worth an index once a collection grows past
-- a couple hundred rows.
create index if not exists cards_user_id_idx on public.cards (user_id);
create index if not exists cards_binder_name_idx on public.cards (binder_name);
create index if not exists binders_user_id_idx on public.binders (user_id);
create index if not exists decks_user_id_idx on public.decks (user_id);
create index if not exists deck_cards_card_id_idx on public.deck_cards (card_id);
create index if not exists wishlist_entries_user_id_idx
  on public.wishlist_entries (user_id);

-- Row Level Security: every table is only ever readable/writable by its
-- owning user.
--
-- Policies are written `(select auth.uid())` rather than bare `auth.uid()`:
-- Postgres then evaluates it once per query instead of once per row, which
-- matters on `cards` once a collection is large (Supabase's linter flags the
-- bare form as `auth_rls_initplan`). They are also limited `to authenticated`
-- so the anon role never even evaluates them.
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

-- deck_cards has no user_id of its own, so ownership is checked through
-- the parent deck. The with-check also confirms card_id belongs to the
-- same user — the foreign key on card_id only proves the card exists
-- *somewhere*, not that it's yours, and FK checks run with privileges
-- that bypass RLS, so without this a user could put someone else's card
-- id into their own deck.
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

-- Create the trainer profile as soon as the account exists.
--
-- The app can only create it from the client when there is a session. With
-- email confirmation on, sign-up returns *no* session, so the profile used to
-- be created at the first log in instead, using whatever name the screen
-- happened to have. Doing it here, from the name saved with the account
-- (`trainer_name`, see AuthService.signUp), makes it independent of that.
-- `on conflict do nothing` keeps it harmless if the client creates it first.
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

-- Only the trigger should ever run this, never an API caller.
revoke execute on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Card catalog
--
-- Reference data for every printed card the app lets people pick from, so a
-- card's name, set, number, rarity, artwork and price come from one accurate
-- source instead of being typed in. It is shared by all accounts: anyone
-- signed in can read it, and nobody can write to it through the API. It is
-- filled from the SQL editor (see tools/import_catalog.mjs and
-- SUPABASE_SETUP.md), which runs with full privileges.
-- ---------------------------------------------------------------------------
create table if not exists public.card_sets (
  id text primary key,
  name text not null,
  series text not null default '',
  -- `printed_total` is the number after the slash on the card (4/102);
  -- `total` also counts secret rares past that number.
  printed_total int,
  total int,
  release_date date,
  logo_url text,
  symbol_url text
);

create table if not exists public.card_catalog (
  id text primary key,
  set_id text not null references public.card_sets (id) on delete cascade,
  -- As printed, so it is text: "4", "SWSH001", "TG01".
  number text not null,
  name text not null,
  supertype text not null default 'pokemon',
  subtype text,
  type text not null default 'colorless',
  -- One of the app's rarity tiers (kRarityOptions); the source's own wording
  -- is kept in rarity_raw.
  rarity text not null default 'Other/Additional Rarities',
  rarity_raw text,
  image_small text,
  image_large text,
  -- A suggestion only: the person's own copy keeps its own value. The app
  -- converts this to pesos (lib/config/pricing.dart).
  market_price_usd numeric check (market_price_usd >= 0),
  price_updated_at timestamptz
);

create index if not exists card_catalog_set_id_idx on public.card_catalog (set_id);
create index if not exists card_catalog_name_idx on public.card_catalog (name);

-- Makes "name contains ..." searches fast now that the catalog can hold every
-- card in the API (about 20,000). Safe to run again.
create extension if not exists pg_trgm with schema extensions;
create index if not exists card_catalog_name_trgm_idx
  on public.card_catalog using gin (name extensions.gin_trgm_ops);

alter table public.card_sets enable row level security;
alter table public.card_catalog enable row level security;

-- Read-only for signed-in users. There are deliberately no insert / update /
-- delete policies, so the API can never change the catalog.
drop policy if exists "Signed-in users can read card_sets" on public.card_sets;
create policy "Signed-in users can read card_sets" on public.card_sets
  for select to authenticated
  using (true);

drop policy if exists "Signed-in users can read card_catalog" on public.card_catalog;
create policy "Signed-in users can read card_catalog" on public.card_catalog
  for select to authenticated
  using (true);

-- A card in someone's collection remembers which catalog card it was picked
-- from (null for a card typed in by hand). If the catalog row is ever removed
-- the card stays; it just loses the link.
alter table public.cards
  add column if not exists catalog_id text
  references public.card_catalog (id) on delete set null;
create index if not exists cards_catalog_id_idx on public.cards (catalog_id);

-- Prices for each printing of a catalog card (normal, holofoil, reverse holo,
-- 1st edition ...) as {"holofoil": 5.4, "reverseHolofoil": 2.1}, in US dollars.
-- market_price_usd stays as the single default price.
alter table public.card_catalog
  add column if not exists prices jsonb;

-- Which printing the person owns ("holofoil", "reverseHolofoil" ...). Null for
-- cards added before this existed or typed in by hand.
alter table public.cards
  add column if not exists finish text;

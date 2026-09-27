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
alter table public.binders enable row level security;
alter table public.cards enable row level security;
alter table public.decks enable row level security;
alter table public.deck_cards enable row level security;
alter table public.wishlist_entries enable row level security;
alter table public.trainer_profiles enable row level security;

drop policy if exists "Owner can manage binders" on public.binders;
create policy "Owner can manage binders" on public.binders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Owner can manage cards" on public.cards;
create policy "Owner can manage cards" on public.cards
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Owner can manage decks" on public.decks;
create policy "Owner can manage decks" on public.decks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- deck_cards has no user_id of its own, so ownership is checked through
-- the parent deck. The with-check also confirms card_id belongs to the
-- same user — the foreign key on card_id only proves the card exists
-- *somewhere*, not that it's yours, and FK checks run with privileges
-- that bypass RLS, so without this a user could put someone else's card
-- id into their own deck.
drop policy if exists "Owner can manage deck_cards" on public.deck_cards;
create policy "Owner can manage deck_cards" on public.deck_cards
  for all
  using (auth.uid() = (select user_id from public.decks where id = deck_id))
  with check (
    auth.uid() = (select user_id from public.decks where id = deck_id)
    and auth.uid() = (select user_id from public.cards where id = card_id)
  );

drop policy if exists "Owner can manage wishlist_entries" on public.wishlist_entries;
create policy "Owner can manage wishlist_entries" on public.wishlist_entries
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Owner can manage trainer_profiles" on public.trainer_profiles;
create policy "Owner can manage trainer_profiles" on public.trainer_profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

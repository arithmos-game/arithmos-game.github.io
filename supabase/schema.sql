create table if not exists public.scores (
  id          uuid primary key,
  owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  game        text not null default 'arithmos',
  level       text not null check (level in ('A', 'B', 'C', 'D')),
  name        text not null check (char_length(name) between 1 and 16),
  ms          integer not null check (ms between 1000 and 3600000),
  achieved_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

-- Upgrading from the shared public board: add the owner column, then drop the old rows,
-- which belong to no account and so could never be shown to anyone.
alter table public.scores add column if not exists owner uuid default auth.uid() references auth.users (id) on delete cascade;
delete from public.scores where owner is null;
alter table public.scores alter column owner set not null;

drop index if exists public.scores_board_idx;
create index if not exists scores_owner_board_idx on public.scores (owner, game, level, ms, achieved_at);

alter table public.scores enable row level security;

-- Each account (one per family) sees and adds only its own scores. There is no public board.
drop policy if exists "Anyone can read scores" on public.scores;
drop policy if exists "Anyone can add scores" on public.scores;

drop policy if exists "Accounts read own scores" on public.scores;
create policy "Accounts read own scores" on public.scores
  for select to authenticated using (owner = (select auth.uid()));

drop policy if exists "Accounts add own scores" on public.scores;
create policy "Accounts add own scores" on public.scores
  for insert to authenticated with check (owner = (select auth.uid()));

revoke all on public.scores from anon;
grant select, insert on public.scores to authenticated;

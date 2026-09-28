create table if not exists public.scores (
  id          uuid primary key,
  game        text not null default 'arithmos',
  level       text not null check (level in ('A', 'B', 'C', 'D')),
  name        text not null check (char_length(name) between 1 and 16),
  ms          integer not null check (ms between 1000 and 3600000),
  achieved_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create index if not exists scores_board_idx on public.scores (game, level, ms, achieved_at);

alter table public.scores enable row level security;

drop policy if exists "Anyone can read scores" on public.scores;
create policy "Anyone can read scores" on public.scores
  for select to anon, authenticated using (true);

drop policy if exists "Anyone can add scores" on public.scores;
create policy "Anyone can add scores" on public.scores
  for insert to anon, authenticated with check (true);

grant select, insert on public.scores to anon, authenticated;

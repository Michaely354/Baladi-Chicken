create table public.menu_offers (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 1 and 100),
  details text not null default '' check (char_length(details) <= 180),
  price text not null default '' check (char_length(price) <= 30),
  created_at timestamptz not null default now()
);
alter table public.menu_offers enable row level security;
revoke all on public.menu_offers from public, anon, authenticated;
grant select on public.menu_offers to anon, authenticated;
grant insert, update, delete on public.menu_offers to authenticated;
create policy "Public reads offers" on public.menu_offers for select to anon, authenticated using (true);
create policy "Owner adds offers" on public.menu_offers for insert to authenticated with check ((select public.is_menu_owner()));
create policy "Owner edits offers" on public.menu_offers for update to authenticated using ((select public.is_menu_owner())) with check ((select public.is_menu_owner()));
create policy "Owner removes offers" on public.menu_offers for delete to authenticated using ((select public.is_menu_owner()));

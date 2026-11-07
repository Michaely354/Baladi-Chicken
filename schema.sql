-- Run once in the Supabase SQL editor on a NEW project.
create table public.menu_owners (user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.menu_owners enable row level security;
revoke all on public.menu_owners from public,anon,authenticated;
create function public.is_menu_owner() returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.menu_owners where user_id=(select auth.uid()));
$$;
revoke all on function public.is_menu_owner() from public,anon,authenticated;
grant execute on function public.is_menu_owner() to authenticated;
create table public.menu_public (id integer primary key check(id=1),content jsonb not null,updated_at timestamptz not null default now());
create table public.menu_drafts (id integer primary key check(id=1),content jsonb not null,revision integer not null default 1,updated_at timestamptz not null default now());
alter table public.menu_public enable row level security;
alter table public.menu_drafts enable row level security;
revoke all on public.menu_public, public.menu_drafts from anon,authenticated;
grant select on public.menu_public to anon,authenticated;
grant select on public.menu_drafts to authenticated;
create policy "Anyone reads published menu" on public.menu_public for select to anon,authenticated using (true);
create policy "Only owner reads drafts" on public.menu_drafts for select to authenticated using ((select public.is_menu_owner()));
-- No direct table writes. Function validates and publishes the document atomically.
create function public.save_menu(new_content jsonb,expected_revision integer,publish_now boolean default false)
returns integer language plpgsql security definer set search_path = '' as $$
declare current_revision integer; p jsonb; c jsonb;
begin
 if not public.is_menu_owner() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 select revision into current_revision from public.menu_drafts where id=1 for update;
 if expected_revision is distinct from current_revision then raise exception 'CONFLICT'; end if;
 if new_content is null or jsonb_typeof(new_content) <> 'object' then raise exception 'Invalid menu'; end if;
 if jsonb_typeof(new_content->'categories') is distinct from 'array' or jsonb_typeof(new_content->'products') is distinct from 'array' then raise exception 'Invalid arrays'; end if;
 if jsonb_array_length(new_content->'categories') not between 1 and 20 or jsonb_array_length(new_content->'products') > 500 then raise exception 'Too many entries'; end if;
 for c in select value from jsonb_array_elements(new_content->'categories') loop
  if (coalesce(c->>'id','') !~ '^[A-Za-z0-9-]{1,100}$') or coalesce(length(trim(c->>'name')),0) not between 1 and 120 then raise exception 'Invalid category'; end if;
 end loop;
 if (select count(*) from jsonb_array_elements(new_content->'categories')) <> (select count(distinct value->>'id') from jsonb_array_elements(new_content->'categories')) then raise exception 'Duplicate categories'; end if;
 for p in select value from jsonb_array_elements(new_content->'products') loop
  if (coalesce(p->>'id','') !~ '^[A-Za-z0-9-]{1,100}$') or coalesce(length(trim(p->>'name')),0) not between 1 and 120 or coalesce(length(p->>'description'),0)>500 then raise exception 'Invalid product'; end if;
  if not exists(select 1 from jsonb_array_elements(new_content->'categories') cc where cc->>'id'=p->>'category') then raise exception 'Unknown category'; end if;
  if jsonb_typeof(p->'available') is distinct from 'boolean' or jsonb_typeof(p->'visible') is distinct from 'boolean' then raise exception 'Invalid availability'; end if;
  if p->>'price' is not null then
   if jsonb_typeof(p->'price') <> 'number' then raise exception 'Invalid price'; end if;
   if (p->>'price')::numeric <= 0 or (p->>'price')::numeric > 1000000000 or coalesce(p->>'currency','') not in ('LBP','USD') then raise exception 'Invalid price or currency'; end if;
  elsif p->>'currency' is not null then raise exception 'Unpriced products need null currency';
  end if;
  if p->>'image' is not null and (length(p->>'image')>2048 or p->>'image' !~ '^https://') then raise exception 'Invalid image'; end if;
 end loop;
 if (select count(*) from jsonb_array_elements(new_content->'products')) <> (select count(distinct value->>'id') from jsonb_array_elements(new_content->'products')) then raise exception 'Duplicate products'; end if;
 update public.menu_drafts set content=new_content,revision=revision+1,updated_at=now() where id=1;
 if publish_now then
  -- Invisible products are excluded entirely from public data.
  update public.menu_public set content=jsonb_set(new_content,'{products}',coalesce((select jsonb_agg(value) from jsonb_array_elements(new_content->'products') where (value->>'visible')::boolean and not coalesce((value->>'deleted')::boolean,false)),'[]'::jsonb)),updated_at=now() where id=1;
 end if;
 return current_revision+1;
end;
$$;
revoke all on function public.save_menu(jsonb,integer,boolean) from public,anon,authenticated;
grant execute on function public.save_menu(jsonb,integer,boolean) to authenticated;

insert into public.menu_drafts (id,content) values (1,$menu${
  "categories": [
    {
      "id": "1",
      "name": "مشاوي عالفحم"
    },
    {
      "id": "2",
      "name": "الصفيحة"
    },
    {
      "id": "3",
      "name": "مشاوي وفروج"
    },
    {
      "id": "4",
      "name": "دجاج ني"
    }
  ],
  "products": [
    {
      "id": "1",
      "category": "1",
      "name": "لحم شقف",
      "description": "",
      "price": 450000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "2",
      "category": "1",
      "name": "كفتة",
      "description": "",
      "price": 400000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "3",
      "category": "1",
      "name": "مقانق",
      "description": "",
      "price": 400000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "4",
      "category": "1",
      "name": "سجق",
      "description": "",
      "price": 400000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "5",
      "category": "1",
      "name": "كباب دجاج",
      "description": "",
      "price": 300000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "6",
      "category": "1",
      "name": "دجاج مشوي",
      "description": "",
      "price": 350000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "7",
      "category": "1",
      "name": "طاووق",
      "description": "",
      "price": 350000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "8",
      "category": "1",
      "name": "سودة دجاج",
      "description": "",
      "price": 300000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "9",
      "category": "2",
      "name": "صفيحة لحمة",
      "description": "",
      "price": 150000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "10",
      "category": "2",
      "name": "صفيحة دجاج",
      "description": "",
      "price": 100000,
      "currency": "LBP",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "11",
      "category": "3",
      "name": "كيلو شقف غنم",
      "description": "",
      "price": 30,
      "currency": "USD",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "12",
      "category": "3",
      "name": "كيلو كفتة غنم",
      "description": "",
      "price": 25,
      "currency": "USD",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "13",
      "category": "3",
      "name": "كيلو كباب دجاج",
      "description": "",
      "price": 15,
      "currency": "USD",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "14",
      "category": "3",
      "name": "فروج مشوي",
      "description": "",
      "price": 15,
      "currency": "USD",
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "15",
      "category": "4",
      "name": "فروج كامل",
      "description": "",
      "price": null,
      "currency": null,
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "16",
      "category": "4",
      "name": "سفاين مسحب",
      "description": "",
      "price": null,
      "currency": null,
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "17",
      "category": "4",
      "name": "سفاين بعضم",
      "description": "",
      "price": null,
      "currency": null,
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "18",
      "category": "4",
      "name": "جوانح",
      "description": "",
      "price": null,
      "currency": null,
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "19",
      "category": "4",
      "name": "فخاد",
      "description": "",
      "price": null,
      "currency": null,
      "available": true,
      "visible": true,
      "image": null
    },
    {
      "id": "20",
      "category": "4",
      "name": "سودة",
      "description": "",
      "price": null,
      "currency": null,
      "available": true,
      "visible": true,
      "image": null
    }
  ]
}$menu$::jsonb);
insert into public.menu_public(id,content) select id,content from public.menu_drafts;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('menu-images','menu-images',true,3145728,array['image/jpeg','image/png','image/webp']);
create policy "Public reads menu images" on storage.objects for select to anon,authenticated using(bucket_id='menu-images');
create policy "Only owner uploads images" on storage.objects for insert to authenticated with check(bucket_id='menu-images' and (select public.is_menu_owner()));
-- Uploaded image paths are immutable so replacing an image never serves a stale cached version.
-- In Supabase Auth, disable public signup. Create the owner privately in Auth > Users.
-- Then run this with the actual owner's UUID:
-- insert into public.menu_owners(user_id) values ('OWNER-USER-UUID');

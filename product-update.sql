-- Publish one product without publishing unrelated pending edits.
create or replace function public.update_menu_product(new_product jsonb,expected_revision integer)
returns integer language plpgsql security definer set search_path='' as $$
declare draft_content jsonb; published_content jsonb; next_revision integer; idx integer; pub_idx integer; product_id text;
begin
 if not public.is_menu_owner() then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 select content into draft_content from public.menu_drafts where id=1 for update;
 product_id:=new_product->>'id';
 select ordinality::integer-1 into idx from jsonb_array_elements(draft_content->'products') with ordinality where value->>'id'=product_id;
 if idx is null then draft_content:=jsonb_set(draft_content,'{products}',(draft_content->'products')||jsonb_build_array(new_product));
 else draft_content:=jsonb_set(draft_content,array['products',idx::text],new_product); end if;
 next_revision:=public.save_menu(draft_content,expected_revision,false);
 select content into published_content from public.menu_public where id=1 for update;
 select ordinality::integer-1 into pub_idx from jsonb_array_elements(published_content->'products') with ordinality where value->>'id'=product_id;
 if not (new_product->>'visible')::boolean or coalesce((new_product->>'deleted')::boolean,false) then
  if pub_idx is not null then published_content:=jsonb_set(published_content,'{products}',(published_content->'products')-pub_idx); end if;
 elsif pub_idx is null then published_content:=jsonb_set(published_content,'{products}',(published_content->'products')||jsonb_build_array(new_product));
 else published_content:=jsonb_set(published_content,array['products',pub_idx::text],new_product); end if;
 update public.menu_public set content=published_content,updated_at=now() where id=1;
 return next_revision;
end;
$$;
revoke all on function public.update_menu_product(jsonb,integer) from public,anon,authenticated;
grant execute on function public.update_menu_product(jsonb,integer) to authenticated;

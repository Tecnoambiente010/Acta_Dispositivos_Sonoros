-- Ejecutar una vez en un proyecto Supabase nuevo o dedicado.
begin;
create table public.equipo_sonoro (
  usuario uuid primary key references auth.users(id) on delete cascade,
  supervisor boolean not null default false
);
create table public.rango_sonoro (
  id integer primary key check (id=1),
  ultimo integer not null check (ultimo>=10075)
);
insert into public.rango_sonoro values (1,10075);
create table public.actas_sonoras (
  folio integer primary key check (folio>=10001),
  fecha date not null,
  estacion text not null,
  emision text unique not null,
  pdf text not null check (length(pdf)>0)
);
alter table public.equipo_sonoro enable row level security;
alter table public.rango_sonoro enable row level security;
alter table public.actas_sonoras enable row level security;
revoke all on public.equipo_sonoro, public.rango_sonoro, public.actas_sonoras from public, anon, authenticated;
grant select on public.equipo_sonoro, public.rango_sonoro, public.actas_sonoras to authenticated;
grant insert on public.actas_sonoras to authenticated;
create policy mi_cuenta on public.equipo_sonoro for select to authenticated using(usuario=(select auth.uid()));
create policy consultar_rango on public.rango_sonoro for select to authenticated using(exists(select 1 from public.equipo_sonoro));
create policy consultar_actas on public.actas_sonoras for select to authenticated using(exists(select 1 from public.equipo_sonoro));
create policy emitir_actas on public.actas_sonoras for insert to authenticated with check (
  folio <= (select ultimo from public.rango_sonoro where id=1)
);
create function public.ampliar_sonoros(nuevo integer) returns void
language plpgsql security definer set search_path='' as $$
begin
  if not exists(select 1 from public.equipo_sonoro where usuario=auth.uid() and supervisor)
    then raise exception 'Se requiere supervisor'; end if;
  update public.rango_sonoro set ultimo=nuevo where id=1 and ultimo<nuevo;
  if not found then raise exception 'El nuevo límite debe ser mayor'; end if;
end; $$;
revoke all on function public.ampliar_sonoros(integer) from public, anon;
grant execute on function public.ampliar_sonoros(integer) to authenticated;
commit;

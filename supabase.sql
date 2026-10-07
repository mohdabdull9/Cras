-- CTLRS production-oriented Supabase schema
-- Run this in Supabase Dashboard -> SQL Editor.
-- Do NOT put service_role keys in the frontend.

create extension if not exists pgcrypto;

create type public.user_role as enum ('admin','officer','inspector','director','finance','operator');
create type public.application_status as enum ('submitted','verification','inspection','approval','payment','approved','rejected','cancelled');
create type public.payment_status as enum ('pending','submitted','paid','rejected');
create type public.license_status as enum ('valid','expired','suspended','revoked');

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone text,
  role public.user_role not null default 'operator',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  reference_no text not null unique,
  operator_id uuid not null references public.profiles(id) on delete restrict,
  operator_name text not null,
  activity text not null,
  island text,
  location text,
  notes text,
  status public.application_status not null default 'submitted',
  assigned_inspector uuid references public.profiles(id) on delete set null,
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  document_type text not null,
  file_path text not null,
  file_name text not null,
  verification_status text not null default 'pending',
  uploaded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.inspections (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  inspector_id uuid references public.profiles(id) on delete set null,
  scheduled_for timestamptz,
  findings text,
  recommendation text,
  status text not null default 'scheduled',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  invoice_no text not null unique,
  amount numeric(14,2) not null check (amount >= 0),
  currency text not null default 'KMF',
  status public.payment_status not null default 'pending',
  payment_ref text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.licenses (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  license_no text not null unique,
  operator_name text not null,
  activity text,
  location text,
  status public.license_status not null default 'valid',
  issued_at date not null default current_date,
  expires_at date,
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  published boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists applications_operator_idx on public.applications(operator_id);
create index if not exists applications_status_idx on public.applications(status);
create index if not exists applications_inspector_idx on public.applications(assigned_inspector);
create index if not exists documents_application_idx on public.documents(application_id);
create index if not exists payments_application_idx on public.payments(application_id);
create index if not exists licenses_license_no_idx on public.licenses(license_no);
create index if not exists licenses_status_idx on public.licenses(status);

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.active and p.role in ('admin','officer','inspector','director','finance')); $$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.profiles p where p.id=auth.uid() and p.active and p.role='admin'); $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id,full_name,email,phone,role)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),new.email,new.raw_user_meta_data->>'phone','operator')
  on conflict(id) do update set email=excluded.email, full_name=excluded.full_name, phone=excluded.phone;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.applications enable row level security;
alter table public.documents enable row level security;
alter table public.inspections enable row level security;
alter table public.payments enable row level security;
alter table public.licenses enable row level security;
alter table public.announcements enable row level security;
alter table public.audit_logs enable row level security;

-- Profiles
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles for select using (id=auth.uid() or public.is_staff());
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update using (public.is_admin()) with check (public.is_admin());

-- Applications
drop policy if exists applications_operator_select on public.applications;
create policy applications_operator_select on public.applications for select using (operator_id=auth.uid() or public.is_staff());
drop policy if exists applications_operator_insert on public.applications;
create policy applications_operator_insert on public.applications for insert with check (operator_id=auth.uid());
drop policy if exists applications_staff_update on public.applications;
create policy applications_staff_update on public.applications for update using (public.is_staff()) with check (public.is_staff());

-- Documents
drop policy if exists documents_select on public.documents;
create policy documents_select on public.documents for select using (
  exists(select 1 from public.applications a where a.id=application_id and (a.operator_id=auth.uid() or public.is_staff()))
);
drop policy if exists documents_operator_insert on public.documents;
create policy documents_operator_insert on public.documents for insert with check (
  uploaded_by=auth.uid() and exists(select 1 from public.applications a where a.id=application_id and a.operator_id=auth.uid())
);
drop policy if exists documents_staff_update on public.documents;
create policy documents_staff_update on public.documents for update using (public.is_staff()) with check (public.is_staff());

-- Inspections
drop policy if exists inspections_staff on public.inspections;
create policy inspections_staff on public.inspections for all using (public.is_staff()) with check (public.is_staff());
drop policy if exists inspections_operator_select on public.inspections;
create policy inspections_operator_select on public.inspections for select using (
  exists(select 1 from public.applications a where a.id=application_id and a.operator_id=auth.uid())
);

-- Payments
drop policy if exists payments_select on public.payments;
create policy payments_select on public.payments for select using (
  public.is_staff() or exists(select 1 from public.applications a where a.id=application_id and a.operator_id=auth.uid())
);
drop policy if exists payments_staff_write on public.payments;
create policy payments_staff_write on public.payments for all using (public.is_staff()) with check (public.is_staff());

-- Licenses: staff can manage; public verification is handled through a safe RPC below.
drop policy if exists licenses_staff on public.licenses;
create policy licenses_staff on public.licenses for all using (public.is_staff()) with check (public.is_staff());
drop policy if exists licenses_owner_select on public.licenses;
create policy licenses_owner_select on public.licenses for select using (
  exists(select 1 from public.applications a where a.id=application_id and a.operator_id=auth.uid())
);

create or replace function public.verify_license(p_license_no text)
returns table (
  license_no text, status public.license_status, issued_at date, expires_at date,
  activity text, location text, operator_name text
)
language sql stable security definer set search_path=public
as $$
  select l.license_no,l.status,l.issued_at,l.expires_at,l.activity,l.location,l.operator_name
  from public.licenses l where upper(l.license_no)=upper(p_license_no) limit 1;
$$;
grant execute on function public.verify_license(text) to anon, authenticated;

-- Announcements: public may read published items.
drop policy if exists announcements_public_read on public.announcements;
create policy announcements_public_read on public.announcements for select using (published=true or public.is_staff());
drop policy if exists announcements_staff_write on public.announcements;
create policy announcements_staff_write on public.announcements for all using (public.is_staff()) with check (public.is_staff());

drop policy if exists audit_staff_read on public.audit_logs;
create policy audit_staff_read on public.audit_logs for select using (public.is_staff());
drop policy if exists audit_insert on public.audit_logs;
create policy audit_insert on public.audit_logs for insert with check (actor_id=auth.uid());

-- Storage bucket for application documents.
insert into storage.buckets(id,name,public) values('ctlrs-documents','ctlrs-documents',false)
on conflict(id) do nothing;

drop policy if exists ctlrs_documents_read on storage.objects;
create policy ctlrs_documents_read on storage.objects for select using (
  bucket_id='ctlrs-documents' and (auth.uid() is not null)
);
drop policy if exists ctlrs_documents_insert on storage.objects;
create policy ctlrs_documents_insert on storage.objects for insert with check (
  bucket_id='ctlrs-documents' and auth.uid() is not null
);

-- IMPORTANT: after creating your first account, promote it to administrator:
-- update public.profiles set role='admin' where email='YOUR_ADMIN_EMAIL';

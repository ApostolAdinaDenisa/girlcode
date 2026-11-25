create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists unaccent with schema extensions;

create table if not exists public.posts (
    id uuid primary key default gen_random_uuid(),
    author text not null check (char_length(author) between 1 and 60),
    category text not null check (category in (
        'Machiaj & Skincare',
        'Idei de Cadouri',
        'Fashion & Outfit',
        'Relații & Sfaturi',
        'Lifestyle & Productivitate'
    )),
    title text not null check (char_length(title) between 5 and 140),
    body text not null check (char_length(body) between 1 and 3000),
    photo_path text check (
        photo_path is null or photo_path ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    ),
    status text not null default 'pending' check (status in ('pending', 'published', 'rejected')),
    like_count integer not null default 0 check (like_count >= 0),
    created_at timestamptz not null default now()
);

create table if not exists public.comments (
    id uuid primary key default gen_random_uuid(),
    post_id uuid not null references public.posts(id) on delete cascade,
    author text not null check (char_length(author) between 1 and 60),
    body text not null check (char_length(body) between 1 and 1000),
    status text not null default 'pending' check (status in ('pending', 'published', 'rejected')),
    created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
    post_id uuid not null references public.posts(id) on delete cascade,
    visitor_id uuid not null,
    created_at timestamptz not null default now(),
    primary key (post_id, visitor_id)
);

create or replace function public.contains_blocked_language(input_text text)
returns boolean
language sql
immutable
set search_path = public, extensions, pg_temp
as $$
    select extensions.unaccent(lower(coalesce(input_text, ''))) ~
        '(^|[^[:alnum:]])(bou(le)?|caca|cacat(uri)?|cretin(a|i)?|curv(a|e)?|fut(u|ut)?|handicap(at|ata)?|idiot(a|i|e)?|jeg(os|osi)?|muie|nesimtit(a|i)?|pizda|prost(a|e|i)?|ratat(a|i)?|tampit(a|i)?)([^[:alnum:]]|$)';
$$;

create or replace function public.submit_post(
    p_author text,
    p_category text,
    p_title text,
    p_body text,
    p_photo_path text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    new_post_id uuid;
begin
    if char_length(trim(coalesce(p_author, ''))) not between 1 and 60
        or char_length(trim(coalesce(p_title, ''))) not between 5 and 140
        or char_length(trim(coalesce(p_body, ''))) not between 1 and 3000 then
        raise exception 'Textul nu respectă limitele permise.' using errcode = '22023';
    end if;

    if p_photo_path is not null and p_photo_path !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$' then
        raise exception 'Fotografia nu este validă.' using errcode = '22023';
    end if;

    if public.contains_blocked_language(concat_ws(' ', p_author, p_title, p_body)) then
        raise exception 'Textul conține un cuvânt jignitor.' using errcode = '22023';
    end if;

    insert into public.posts (author, category, title, body, photo_path)
    values (trim(p_author), p_category, trim(p_title), trim(p_body), p_photo_path)
    returning id into new_post_id;

    return new_post_id;
end;
$$;

create or replace function public.submit_comment(
    p_post_id uuid,
    p_author text,
    p_body text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    new_comment_id uuid;
begin
    if char_length(trim(coalesce(p_author, ''))) not between 1 and 60
        or char_length(trim(coalesce(p_body, ''))) not between 1 and 1000 then
        raise exception 'Comentariul nu respectă limitele permise.' using errcode = '22023';
    end if;

    if public.contains_blocked_language(concat_ws(' ', p_author, p_body)) then
        raise exception 'Textul conține un cuvânt jignitor.' using errcode = '22023';
    end if;

    if not exists (
        select 1 from public.posts where id = p_post_id and status = 'published'
    ) then
        raise exception 'Discuția nu este disponibilă.' using errcode = '22023';
    end if;

    insert into public.comments (post_id, author, body)
    values (p_post_id, trim(p_author), trim(p_body))
    returning id into new_comment_id;

    return new_comment_id;
end;
$$;

create or replace function public.toggle_post_like(p_post_id uuid, p_visitor_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    is_liked boolean;
    new_like_count integer;
begin
    if not exists (
        select 1 from public.posts where id = p_post_id and status = 'published'
    ) then
        raise exception 'Discuția nu este disponibilă.' using errcode = '22023';
    end if;

    delete from public.post_likes where post_id = p_post_id and visitor_id = p_visitor_id;
    if found then
        is_liked := false;
    else
        insert into public.post_likes (post_id, visitor_id) values (p_post_id, p_visitor_id)
        on conflict do nothing;
        is_liked := found;
    end if;

    select count(*)::integer into new_like_count
    from public.post_likes where post_id = p_post_id;

    update public.posts set like_count = new_like_count where id = p_post_id;

    return jsonb_build_object('liked', is_liked, 'like_count', new_like_count);
end;
$$;

alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.post_likes enable row level security;

drop policy if exists posts_read_published on public.posts;
create policy posts_read_published on public.posts
    for select to anon, authenticated using (status = 'published');

drop policy if exists comments_read_published on public.comments;
create policy comments_read_published on public.comments
    for select to anon, authenticated using (
        status = 'published' and exists (
            select 1 from public.posts
            where posts.id = comments.post_id and posts.status = 'published'
        )
    );

revoke all on public.posts, public.comments, public.post_likes from public, anon, authenticated;
grant select on public.posts, public.comments to anon, authenticated;
revoke all on function public.contains_blocked_language(text) from public, anon, authenticated;
revoke all on function public.submit_post(text, text, text, text, text) from public, anon, authenticated;
revoke all on function public.submit_comment(uuid, text, text) from public, anon, authenticated;
revoke all on function public.toggle_post_like(uuid, uuid) from public, anon, authenticated;
grant execute on function public.submit_post(text, text, text, text, text) to anon, authenticated;
grant execute on function public.submit_comment(uuid, text, text) to anon, authenticated;
grant execute on function public.toggle_post_like(uuid, uuid) to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('community-photos', 'community-photos', true, 8388608, array['image/jpeg'])
on conflict (id) do update set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists community_photos_read on storage.objects;
create policy community_photos_read on storage.objects
    for select to anon, authenticated using (bucket_id = 'community-photos');

drop policy if exists community_photos_upload on storage.objects;
create policy community_photos_upload on storage.objects
    for insert to anon, authenticated with check (
        bucket_id = 'community-photos'
        and name ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.jpg$'
    );

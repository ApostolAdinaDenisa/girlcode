alter table public.posts
    alter column status set default 'published';

alter table public.comments
    alter column status set default 'published';

update public.posts
set status = 'published'
where status = 'pending';

update public.comments
set status = 'published'
where status = 'pending';

alter table public.posts
    alter column status set default 'published';

alter table public.comments
    alter column status set default 'published';

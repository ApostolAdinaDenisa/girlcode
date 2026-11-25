begin;

alter table public.posts
    drop constraint if exists posts_category_check;

alter table public.posts
    add constraint posts_category_check check (category in (
        'Machiaj & Skincare',
        'Idei de Cadouri',
        'Fashion & Outfit',
        'Relații & Sfaturi',
        'Lifestyle & Productivitate',
        'Vacanțe'
    ));

commit;

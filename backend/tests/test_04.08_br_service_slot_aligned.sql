set search_path to public;

-- (BR-08) Les heures de début et de fin d'un service doivent être alignées sur les créneaux du restaurant.

-- region start_time_not_aligned
begin;
do
$test$
    begin
        raise notice 'TEST(services): impossible d''insérer un service avec une heure de début non alignée';
        perform should_fail($$
            insert into services (restaurant, day_of_week, start_time, end_time)
            values (1, 6, '12:10', '14:00');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region end_time_not_aligned
begin;
do
$test$
    begin
        raise notice 'TEST(services): impossible d''insérer un service avec une heure de fin non alignée';
        perform should_fail($$
            insert into services (restaurant, day_of_week, start_time, end_time)
            values (1, 6, '12:00', '14:20');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region update_to_non_aligned
begin;
do
$test$
    begin
        raise notice 'TEST(services): impossible de modifier un service pour avoir une heure non alignée';
        perform should_fail($$
            update services set start_time = '12:05' where id = 1;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_aligned_30min_slots
begin;
do
$test$
    begin
        raise notice 'TEST(services): insertion valide d''un service aligné sur des créneaux de 30 minutes (restaurant 1)';
        insert into services (restaurant, day_of_week, start_time, end_time)
        values (1, 6, '12:00', '14:00');
    end;
$test$;
rollback;
-- endregion

-- region insert_aligned_15min_slots
begin;
do
$test$
    begin
        raise notice 'TEST(services): insertion valide d''un service aligné sur des créneaux de 15 minutes (restaurant 4)';
        insert into services (restaurant, day_of_week, start_time, end_time)
        values (4, 1, '15:00', '17:00');
    end;
$test$;
rollback;
-- endregion

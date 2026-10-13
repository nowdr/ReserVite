set search_path to public;

-- (BR-07) Pour un même jour de la semaine, les services d'un restaurant ne peuvent pas se chevaucher.

-- region insert_overlapping_service
begin;
do
$test$
    begin
        raise notice 'TEST(services): impossible d''insérer un service qui chevauche un service existant';
        perform should_fail($$
            insert into services (restaurant, day_of_week, start_time, end_time)
            values (1, 1, '13:00', '15:00');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region update_to_overlapping_service
begin;
do
$test$
    begin
        raise notice 'TEST(services): impossible de modifier un service pour qu''il chevauche un service existant';
        perform should_fail($$
            update services set start_time = '13:00' where id = 2;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_service_containing_existing
begin;
do
$test$
    begin
        raise notice 'TEST(services): impossible d''insérer un service qui englobe un service existant';
        perform should_fail($$
            insert into services (restaurant, day_of_week, start_time, end_time)
            values (1, 1, '11:00', '15:00');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_non_overlapping_service
begin;
do
$test$
    begin
        raise notice 'TEST(services): insertion valide d''un service qui ne chevauche pas les services existants';
        insert into services (restaurant, day_of_week, start_time, end_time)
        values (1, 1, '15:00', '18:00');
    end;
$test$;
rollback;
-- endregion

-- region insert_different_day_same_times
begin;
do
$test$
    begin
        raise notice 'TEST(services): insertion valide d''un service avec les mêmes heures mais un jour différent';
        insert into services (restaurant, day_of_week, start_time, end_time)
        values (1, 6, '12:00', '14:00');
    end;
$test$;
rollback;
-- endregion

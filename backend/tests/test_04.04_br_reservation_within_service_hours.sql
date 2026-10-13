set search_path to public;

-- (BR-04) L'heure d'une réservation confirmée, terminée ou en attente doit être comprise
-- entre l'heure de début et l'heure de fin d'un service pour le même jour de la semaine.

-- region insert_outside_service_hours
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): impossible d''insérer une réservation en dehors des heures de service';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 2, '2026-04-17 23:30:00', 2, 'pending');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_on_day_without_service
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): impossible d''insérer une réservation un jour sans service';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 3, '2026-04-20 19:00:00', 2, 'pending');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_before_service_start
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): impossible d''insérer une réservation avant le début du service';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 1, '2026-04-20 11:00:00', 2, 'pending');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_between_services
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): impossible d''insérer une réservation entre deux services';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 1, '2026-04-20 16:00:00', 2, 'pending');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region update_datetime_outside_service_hours
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): impossible de modifier le datetime d''une réservation en dehors des heures de service';
        perform should_fail($$
            update reservations set datetime = '2026-04-17 23:30:00' where id = 1;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_cancelled_outside_service_hours
begin;
do
$test$
    declare
        v_id int;
    begin
        raise notice 'TEST(BR-04): une réservation annulée peut être déplacée en dehors des heures de service';

        -- Insert valide selon BR-09 (status initial pending)
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (3, 2, '2026-04-17 20:00:00', 2, 'pending')
        returning id into v_id;

        -- BR-04 n'impose pas de contrainte d'heures pour status cancelled
        update reservations
        set status = 'cancelled',
            datetime = '2026-04-17 23:30:00'
        where id = v_id;
    end;
$test$;
rollback;
-- endregion

-- region insert_within_service_hours
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): insertion valide d''une réservation dans les heures de service';
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (3, 2, '2026-04-17 20:00:00', 2, 'pending');
    end;
$test$;
rollback;
-- endregion

-- region insert_at_service_start_time
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): insertion valide d''une réservation à l''heure exacte de début du service';
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (4, 1, '2026-04-20 12:00:00', 2, 'pending');
    end;
$test$;
rollback;
-- endregion

-- region insert_at_service_end_time
begin;
do
$test$
    begin
        raise notice 'TEST(BR-04): insertion valide d''une réservation à l''heure exacte de fin du service';
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (3, 1, '2026-04-20 22:00:00', 2, 'pending');
    end;
$test$;
rollback;
-- endregion

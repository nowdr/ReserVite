set search_path to public;

-- (BR-06) Une table ne peut pas faire l'objet de deux réservations terminées ou confirmées
-- pour une même date et un même service.

-- region confirm_conflicting_table_same_service
begin;
do
$test$
    declare
        v_first_reservation_id int;
        v_conflicting_reservation_id int;
    begin
        raise notice 'TEST(BR-06): impossible de confirmer une réservation qui réutilise une table déjà confirmée sur le même service';

        -- Première réservation sur table 1, 2026-04-17 à 19:30 (service soir 19:00-23:00 du vendredi)
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (3, 1, '2026-04-17 19:30:00', 2, 'pending')
        returning id into v_first_reservation_id;

        insert into reservation_tables (reservation, "table")
        values (v_first_reservation_id, 1);

        update reservations set status = 'confirmed' where id = v_first_reservation_id;

        -- Deuxième réservation sur la même table, même date, même service
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (4, 1, '2026-04-17 20:00:00', 2, 'pending')
        returning id into v_conflicting_reservation_id;

        insert into reservation_tables (reservation, "table")
        values (v_conflicting_reservation_id, 1);

        perform should_fail(
                format('update reservations set status = ''confirmed'' where id = %s;', v_conflicting_reservation_id),
                'raise_exception'
        );
    end;
$test$;
rollback;
-- endregion

-- region confirm_same_table_other_service_allowed
begin;
do
$test$
    declare
        v_allowed_reservation_id int;
    begin
        raise notice 'TEST(BR-06): la même table peut être confirmée sur deux services différents le même jour';

        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (4, 1, '2026-04-20 12:30:00', 2, 'pending')
        returning id into v_allowed_reservation_id;

        insert into reservation_tables (reservation, "table")
        values (v_allowed_reservation_id, 1);

        update reservations
        set status = 'confirmed'
        where id = v_allowed_reservation_id;
    end;
$test$;
rollback;
-- endregion

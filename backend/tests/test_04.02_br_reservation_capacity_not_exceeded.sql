set search_path to public;

-- (BR-02) Le nombre de convives d'une réservation confirmée ou terminée ne peut pas dépasser
-- la capacité totale des tables associées à la réservation.
-- Ceci implique qu'une réservation confirmée ou terminée doit avoir au moins une table réservée
-- appartenant au restaurant de la réservation.

-- region confirm_without_tables
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): impossible de confirmer une réservation sans tables assignées';
        perform should_fail($$
            update reservations set status = 'confirmed' where id = 2;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region confirm_exceeding_capacity
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): impossible de confirmer une réservation si les convives dépassent la capacité des tables';
        insert into reservation_tables (reservation, "table") values (5, 4);
        perform should_fail($$
            update reservations set status = 'confirmed', number_of_guests = 5 where id = 5;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region complete_within_capacity
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): compléter une réservation confirmée dont les convives ne dépassent pas la capacité';
        update reservations set status = 'completed' where id = 7;
    end;
$test$;
rollback;
-- endregion

-- region pending_no_restriction
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): une réservation pending peut avoir plus de convives que la capacité';
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (3, 1, '2024-12-10 19:00:00', 100, 'pending');
    end;
$test$;
rollback;
-- endregion

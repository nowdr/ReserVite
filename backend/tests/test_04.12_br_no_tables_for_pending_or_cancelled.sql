set search_path to public;

-- (BR-12) Une réservation en attente ou annulée ne peut être associée à aucune table.

-- region pending_reservation_cannot_have_table
begin;
do
$test$
    begin
        raise notice 'TEST(BR-12): impossible d''associer une table à une réservation pending';
        perform should_fail($$
            insert into reservation_tables (reservation, "table")
            values (2, 4);
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region cancelled_reservation_cannot_have_table
begin;
do
$test$
    begin
        raise notice 'TEST(BR-12): impossible d''associer une table à une réservation cancelled';
        perform should_fail($$
            insert into reservation_tables (reservation, "table")
            values (8, 4);
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region cancelling_reservation_with_tables_fails
begin;
do
$test$
    begin
        raise notice 'TEST(BR-12): impossible de passer une réservation en cancelled tant qu''elle a des tables';
        perform should_fail($$
            update reservations set status = 'cancelled' where id = 1;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion


-- region confirmed_reservation_can_have_table
begin;
do
$test$
    begin
        raise notice 'TEST(BR-12): une réservation confirmed peut être associée à des tables';
        insert into reservation_tables (reservation, "table")
        values (11, 4);
    end;
$test$;
rollback;
-- endregion


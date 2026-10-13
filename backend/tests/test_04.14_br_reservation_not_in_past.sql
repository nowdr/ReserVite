set search_path to public;

-- (BR-14) Une réservation ne peut pas être créée dans le passé (ne doit être vérifié qu'au moment de la création).

-- region insert_in_past_fails
begin;
do
$test$
    begin
        raise notice 'TEST(BR-14): impossible de creer une reservation dans le passe';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 2, '2024-11-15 20:00:00', 2, 'pending');
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region insert_in_future_allowed
begin;
do
$test$
    begin
        raise notice 'TEST(BR-14): insertion valide d''une reservation dans le futur';
        insert into reservations (client, restaurant, datetime, number_of_guests, status)
        values (3, 2, '2024-12-10 19:00:00', 2, 'pending');
    end;
$test$;
rollback;
-- endregion

-- region update_to_past_allowed
begin;
do
$test$
    begin
        raise notice 'TEST(BR-14): la verification ne s''applique pas lors d''une mise a jour';
        update reservations
        set datetime = '2024-11-15 20:00:00'
        where id = 2;
    end;
$test$;
rollback;
-- endregion


set search_path to public;

-- (BR-13) Un client ne peut pas avoir deux réservations en attente, confirmées ou terminées pour une même date et un même service.

begin;
do
$test$
    begin
        raise notice 'TEST(BR-13): insertion réservation doublon';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 1, '2024-11-15 19:00:00', 2, 'pending');
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(BR-13): màj réservation doublon';
        perform should_fail($$
            update reservations set datetime = '2024-11-21 19:30:00' where id = 4;
        $$, 'raise_exception');
    end
$test$;
rollback;
set search_path to public;

-- (BR-01) Une réservation doit être associée à un utilisateur ayant le rôle de client.

begin;
do
$test$
    begin
        raise notice 'TEST(BR-01): insertion avec un rôle incorrect';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (1, 1, '2024-11-15 19:00:00', 2, 'pending');
        $$, 'raise_exception');
    end
$test$;
rollback;
set search_path to public;

-- (BR-05) Au moment de sa création ou de sa modification, l'heure d'une réservation doit correspondre à un créneau de réservation (slot) pour le restaurant.
-- Un créneau de réservation doit toujours correspondre à une heure exacte (sans minutes) augmentée d'un multiple de la durée du créneau de réservation.

begin;
do
$test$
    begin
        raise notice 'TEST(BR-05): insertion avec une heure en dehors des intervalles de réservation';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (4, 1, '2024-11-16 19:15:00', 4, 'pending');
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(BR-05): màj avec une heure en dehors des intervalles de réservation';
        perform should_fail($$
            update reservations set datetime = '2024-11-15 19:15:00' where id = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;
set search_path to public;

-- (BR-09) Une nouvelle réservation doit avoir le status pending. Une réservation existante ne peut pas revenir "en arrière" dans son cycle de vie. Les transitions autorisées sont :
-- pending -> confirmed
-- pending -> cancelled
-- confirmed -> completed
-- confirmed -> cancelled
-- La transition confirmed -> pending est autorisée dans certains cas (voir règles temporelles).
-- Aucune transition depuis completed ou cancelled n'est autorisée.

begin;
do
$test$
    begin
        raise notice 'TEST(BR-09): insertion avec statut de réservation incorrect';
        perform should_fail($$
            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (3, 1, '2024-11-15 19:00:00', 2, 'confirmed');
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(BR-09): màj avec statut de réservation incorrect';
        perform should_fail($$
            update reservations set status = 'completed' where id = 2;
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(BR-09): màj réservation confirmée avec date incorrecte';
        perform should_fail($$
            update reservations set status = 'pending' where id = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;
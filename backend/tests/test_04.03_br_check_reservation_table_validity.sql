set search_path to public;

-- (BR-03) Les tables associées à une réservation doivent appartenir au restaurant de la réservation.

begin;
do
$test$
    begin
        raise notice 'TEST(BR-03): insertion avec une table dans un restaurant différent';
        perform should_fail($$
            insert into reservation_tables (reservation, "table")
            values (1, 4);
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(BR-03): màj avec une table dans un restaurant différent';
        perform should_fail($$
            update reservation_tables set "table" = 4 where reservation = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;
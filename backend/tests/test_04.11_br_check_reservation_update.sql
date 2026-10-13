set search_path to public;

-- (BR-11) Une réservation terminée ou annulée ne peut pas être modifiée.

begin;
do
$test$
    begin
        raise notice 'TEST(BR-11): màj réservation terminée';
        perform should_fail($$
            update reservations set special_requests = 'modification interdite' where id = 12;
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(BR-11): màj réservation annulée';
        perform should_fail($$
            update reservations set number_of_guests = 5 where id = 8;
        $$, 'raise_exception');
    end
$test$;
rollback;
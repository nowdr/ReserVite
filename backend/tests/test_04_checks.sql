set search_path to public;

-- region Users

-- region full_name_length
begin;
do
$test$
    begin
        raise notice 'TEST(users): nom trop court';
        perform should_fail($$
            update users set full_name = 'ab' where id = 1;
        $$, 'check_violation');
    end
$test$;
rollback;
-- endregion

-- region password_complexity
begin;
do
$test$
    begin
        raise notice 'TEST(users): mot de passe incomplet';
        perform should_fail($$
            update users set password = 'Password1' where id = 1;
        $$, 'check_violation');
    end
$test$;
rollback;
-- endregion

-- region user_role_change
begin;
do
$test$
    begin
        raise notice 'TEST(users): modification rôle';
        perform should_fail($$
            update users set role = 'client' where id = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;
-- endregion

-- endregion

-- region Restaurants

-- region name_min_length
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): longueur nom minimum de 5';
        perform should_fail($$
            update restaurants set name = 'abc' where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region address_min_length
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): longueur adresse minimum de 5';
        perform should_fail($$
            update restaurants set address = 'abc' where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region city_min_length
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): longueur ville minimum de 3';
        perform should_fail($$
            update restaurants set city = 'ab' where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region phone_format
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): format numéro de téléphone belge valide';
        perform should_fail($$
            update restaurants set phone = '12345' where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region description_min_length
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): longueur description minimum de 10';
        perform should_fail($$
            update restaurants set description = 'abc' where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region rating_range
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): note comprise entre 0.0 et 5.0';
        perform should_fail($$
            update restaurants set rating = 5.1 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region price_range
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): fourchette de prix comprise entre 1 et 4';
        perform should_fail($$
            update restaurants set price_range = 5 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region slot_duration
begin;
do
$test$
    begin
        raise notice 'TEST(restaurants): durée de créneau doit être 10, 15, 20, 30 ou 60';
        perform should_fail($$
            update restaurants set slot_duration = 25 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- endregion

-- region Reservations

-- region positive_number_of_guests
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): nombre de convives nul';
        perform should_fail($$
            update reservations set number_of_guests = 0 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region special_requests_length
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): requête spéciale vide';
        perform should_fail($$
            update reservations set special_requests = '' where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region validate_reservation_update
begin;
do
$test$
    begin
        raise notice 'TEST(reservations): màj restaurant';
        perform should_fail($$
            update reservations set restaurant = '2' where id = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;

begin;
do
$test$
    begin
        raise notice 'TEST(reservations): màj client';
        perform should_fail($$
            update reservations set client = '1' where id = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;
-- endregion

-- endregion

-- region Tables

-- region positive_table_number
begin;
do
$test$
    begin
        raise notice 'TEST(tables): numéro de table nul';
        perform should_fail($$
            update tables set table_number = 0 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region positive_capacity
begin;
do
$test$
    begin
        raise notice 'TEST(tables): capacité nulle';
        perform should_fail($$
            update tables set capacity = 0 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region table_update
begin;
do
$test$
    begin
        raise notice 'TEST(tables): màj restaurant';
        perform should_fail($$
            update tables set restaurant = '2' where id = 1;
        $$, 'raise_exception');
    end
$test$;
rollback;
-- endregion

-- endregion

-- region Services

-- region valid_day_of_week
begin;
do
$test$
    begin
        raise notice 'TEST(services): jour de le semaine entre 1 et 7';
        perform should_fail($$
            update services set day_of_week = 8 where id = 1;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region min_duration
begin;
do
$test$
    begin
        raise notice 'TEST(services): heure du fin de service i heure plus loin que début de service';
        perform should_fail($$
            update services set end_time = start_time;
        $$, 'check_violation');
    end;
$test$;
rollback;
-- endregion

-- region service_update
begin;
do
$test$
    begin
        raise notice 'TEST(services): le restaurant d''un service ne peut pas être modifié';
        perform should_fail($$
            update services set restaurant = restaurant + 1 where id = 1;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- endregion
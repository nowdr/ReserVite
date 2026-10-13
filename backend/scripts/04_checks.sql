set search_path to public;

-- region Users

-- region full_name_length
alter table users
drop constraint if exists check_full_name_length;

alter table users
add constraint check_full_name_length
check (length(trim(full_name)) >= 3);
-- endregion

-- region password_complexity
alter table users
drop constraint if exists check_password_complexity;

alter table users
add constraint check_password_complexity
check (regexp_like(password, '^(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])(?=.*[,;.:!?/$%&@#]).{8,}$'));
-- endregion

-- region user_role_change
create or replace function function_user_role_change() returns trigger as
$$
begin
    if new.role != old.role then
        raise exception 'Le rôle d''un utilisateur ne peut pas être modifié.';
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_user_role_change on users;
create trigger trigger_user_role_change
    before update of role
    on users
    for each row
    execute function function_user_role_change();
-- endregion

-- endregion

-- region Restaurants

-- region name_min_length
alter table restaurants
drop constraint if exists check_name_min_length;

alter table restaurants
    add constraint check_name_min_length
        check (length(trim(name)) >= 5);
-- endregion

-- region address_min_length
alter table restaurants
drop constraint if exists check_address_min_length;

alter table restaurants
    add constraint check_address_min_length
        check (length(trim(address)) >= 5);
-- endregion

-- region city_min_length
alter table restaurants
drop constraint if exists check_city_min_length;

alter table restaurants
    add constraint check_city_min_length
        check (length(trim(city)) >= 3);
-- endregion

-- region phone_format
alter table restaurants
drop constraint if exists check_phone_format;

alter table restaurants
    add constraint check_phone_format
        check (regexp_like(phone, '^(\+32 ?|0)([1-9]( ?\d){7}|4( ?\d){8})$'));
-- endregion

-- region description_min_length
alter table restaurants
drop constraint if exists check_description_min_length;

alter table restaurants
    add constraint check_description_min_length
        check (description is null or length(trim(description)) >= 10);
-- endregion

-- region rating_range
alter table restaurants
drop constraint if exists check_rating_range;

alter table restaurants
    add constraint check_rating_range
        check (rating is null or (rating >= 0 and rating <= 5));
-- endregion

-- region price_range
alter table restaurants
drop constraint if exists check_price_range;

alter table restaurants
    add constraint check_price_range
        check (price_range is null or (price_range >= 1 and price_range <= 4));
-- endregion

-- region slot_duration
alter table restaurants
drop constraint if exists check_slot_duration;

alter table restaurants
    add constraint check_slot_duration
        check (slot_duration in (10, 15, 20, 30, 60));
-- endregion

-- endregion

-- region Reservations

-- region positive_number_of_guests
alter table reservations
    drop constraint if exists check_positive_number_of_guests;

alter table reservations
    add constraint check_positive_number_of_guests
        check (number_of_guests > 0);
-- endregion

-- region special_requests_length
alter table reservations
drop constraint if exists check_special_requests_length;

alter table reservations
    add constraint check_special_requests_length
        check (special_requests is null or length(trim(special_requests)) >= 10);
-- endregion

-- region validate_reservation_update
create or replace function function_validate_reservation_update() returns trigger as
$$
    begin
        if new.restaurant != old.restaurant or new.client != old.client then
            raise exception 'Le restaurant et le client associés à une réservation ne peuvent pas être modifiés.';
        end if;
        return new;
    end;
$$ language plpgsql security definer;

drop trigger if exists trigger_validate_reservation_update on reservations;
create trigger trigger_validate_reservation_update
    before update of restaurant, client
    on reservations
    for each row
    execute function function_validate_reservation_update();
-- endregion

-- endregion

-- region Tables

-- region positive_table_number
alter table tables
    drop constraint if exists check_positive_table_number;

alter table tables
    add constraint check_positive_table_number
        check (table_number > 0);
-- endregion

-- region positive_capacity
alter table tables
    drop constraint if exists check_positive_capacity;

alter table tables
    add constraint check_positive_capacity
        check (capacity > 0);
-- endregion

-- region table_update
create or replace function function_table_update() returns trigger as
$$
begin
    if new.restaurant != old.restaurant then
        raise exception 'Le restaurant associé à une table ne peut pas être modifié.';
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_table_update on tables;
create trigger trigger_table_update
    before update of restaurant
    on tables
    for each row
execute function function_table_update();
-- endregion

-- endregion

-- region Services

-- region valid_day_of_week
alter table services
    drop constraint if exists check_valid_day_of_week;

alter table services
    add constraint check_valid_day_of_week
        check (day_of_week >= 1 and day_of_week <= 7);
-- endregion valid_day_of_week

-- region min_duration
alter table services
    drop constraint if exists check_min_duration;

alter table services
    add constraint check_min_duration
        check (end_time - start_time >= interval '1 hour');
-- endregion

-- region service_update
create or replace function function_service_update() returns trigger as
$$
begin
    if new.restaurant != old.restaurant then
        raise exception 'Le restaurant associé à un service ne peut pas être modifié.';
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_service_update on services;
create or replace trigger trigger_service_update
    before update of restaurant
    on services
    for each row
execute function function_service_update();
-- endregion

-- endregion

-- region Reservation_tables

-- region reservation_tables_immutable
create or replace function function_reservation_tables_immutable() returns trigger as
$$
begin
    if new.reservation != old.reservation or new."table" != old."table" then
        raise exception 'Une association réservation-table ne peut pas être modifiée.';
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_reservation_tables_immutable on reservation_tables;
create trigger trigger_reservation_tables_immutable
    before update
    on reservation_tables
    for each row
execute function function_reservation_tables_immutable();
-- endregion

-- endregion

-- region Restaurant_managers

-- region restaurant_managers_immutable
create or replace function function_restaurant_managers_immutable() returns trigger as
$$
begin
    if new.restaurant != old.restaurant or new.manager != old.manager then
        raise exception 'Une association restaurant-manager ne peut pas être modifiée.';
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trigger_restaurant_managers_immutable on restaurant_managers;
create trigger trigger_restaurant_managers_immutable
    before update
    on restaurant_managers
    for each row
execute function function_restaurant_managers_immutable();
-- endregion

-- endregion
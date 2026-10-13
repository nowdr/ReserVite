set search_path to public;

-- (BR-13) Un client ne peut pas avoir deux réservations en attente, confirmées ou terminées pour une même date et un même service.
--
-- tables : reservations, services
--
-- événements :
--     reservations :
--         insert : oui pour vérifier qu'aucune autre réservation similaire n'existe
--         update : oui car peut changer client, datetime, status ou restaurant
--         delete : non
--
--     services :
--         insert : non car ne peut pas dupliquer des réservations existantes
--         update : non, modifier un service après réservations existantes est un cas non géré
--         delete : non car sans service il n'y a pas de doublon possible

create or replace function function_reservation_duplicates() returns trigger as
$$
    declare
        v_date date;
        v_new_service_id int;
    begin
        v_date := new.datetime::date;
        v_new_service_id := function_service_id(new.restaurant, new.datetime);
        if exists(select * from reservations where id != new.id
                                               and client = new.client
                                               and status in ('pending', 'confirmed', 'completed')
                                               and datetime::date = v_date
                                               and function_service_id(restaurant, datetime) = v_new_service_id) then
            raise exception 'Le client a déjà une réservation similaire.';
        end if;
        return new;
    end;
$$ language plpgsql security definer;

create or replace trigger trigger_reservation_duplicates
    before insert or update
    on reservations
    for each row
    execute function function_reservation_duplicates();

create or replace function function_service_id(_restaurant int, datetime timestamp) returns int as
$$
declare v_time time;
begin
    v_time := datetime::time;
    return (select id from services where restaurant = _restaurant
                                      and day_of_week = extract(isodow from datetime)
                                      and v_time >= start_time
                                      and v_time <= end_time);
end;
$$ language plpgsql security definer;


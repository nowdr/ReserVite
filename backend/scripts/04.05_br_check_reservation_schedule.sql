set search_path to public;

-- (BR-05) Au moment de sa création ou de sa modification, l'heure d'une réservation doit correspondre à un créneau de réservation (slot) pour le restaurant.
-- Un créneau de réservation doit toujours correspondre à une heure exacte (sans minutes) augmentée d'un multiple de la durée du créneau de réservation.
--
-- tables : reservations, restaurants
--
-- événements :
--     reservations :
--         insert : oui pour vérifier que l'heure est alignée sur un slot
--         update : oui si datetime change
--         delete : non
--
--     restaurants : slot_duration
--         insert : non car aucune réservation existante
--         update : oui car changer slot_duration peut désaligner les réservations existantes
--         delete : non car les réservations sont supprimées en cascade

create or replace function function_validate_reservation_schedule() returns trigger as
$$
    begin
        if (select mod(extract(minute from new.datetime), slot_duration)::integer
            from restaurants where id = new.restaurant) != 0 then
            raise exception 'L''heure choisie ne correspond pas aux intervalles de réservation.';
        end if;
        return new;
    end;
$$ language plpgsql security definer;

create or replace trigger trigger_validate_reservation_schedule
    before insert or update of datetime
    on reservations
    for each row
    execute function function_validate_reservation_schedule();
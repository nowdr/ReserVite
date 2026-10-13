set search_path to public;

-- (BR-08) Au moment de leur création ou de leur modification,
-- les heures de début et de fin d'un service doivent être alignées sur les créneaux de réservation pour le restaurant.
--
-- tables : services, restaurants
--
-- événements :
--     services :
--         insert : oui pour vérifier l'alignement sur les slots
--         update : oui si start_time ou end_time change
--         delete : non
--
--     restaurants : slot_duration
--         insert : non car aucun service existant
--         update : oui car changer slot_duration peut désaligner les services existants
--         delete : non car les services sont supprimés en cascade

create or replace function function_service_slot_aligned() returns trigger as
$$
declare
    v_slot_duration int;
begin
    select slot_duration into v_slot_duration
    from restaurants
    where id = new.restaurant;

    if extract(minute from new.start_time) % v_slot_duration != 0
    or extract(minute from new.end_time) % v_slot_duration != 0 then
        raise exception 'Les heures de début et de fin d''un service doivent être alignées sur les créneaux de réservation';
    end if;

    return new;
end;
$$ language plpgsql security definer;

create or replace trigger trigger_service_slot_aligned
before insert or update of start_time, end_time
on services
for each row
execute function function_service_slot_aligned();

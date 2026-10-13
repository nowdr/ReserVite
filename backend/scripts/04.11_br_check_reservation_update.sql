set search_path to public;

-- (BR-11) Une réservation terminée ou annulée ne peut pas être modifiée.
--
-- tables : reservations
--
-- événements :
--     reservations :
--         insert : non car la règle s'applique aux réservations existantes
--         update : oui pour bloquer la modification si l'ancien status était completed ou cancelled
--         delete : non, hors du périmètre de la règle

create or replace function function_reservation_update() returns trigger as
$$
    begin
        if old.status in ('cancelled', 'completed') then
            raise exception 'Les réservations cancelled et completed ne peuvent pas être modifiées.';
        end if;
        return new;
    end;
$$ language plpgsql security definer;

create or replace trigger trigger_reservation_update
    before update
    on reservations
    for each row
    execute function function_reservation_update();

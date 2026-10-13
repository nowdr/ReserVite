set search_path to public;

-- (BR-14) Une réservation ne peut pas être créée dans le passé (ne doit être vérifié qu'au moment de la création).
--
-- tables : reservations, system_time
--
-- événements :
--     reservations :
--         insert : oui pour vérifier que datetime n'est pas dans le passé
--         update : non car la règle ne s'applique qu'à la création
--         delete : non
--
--     system_time : simulated_time
--         insert : non, table mono-ligne
--         update : non car la règle ne s'applique qu'à la création (les réservations passées ne sont pas réévaluées)
--         delete : non, table mono-ligne

create or replace function function_reservation_not_in_past() returns trigger as
$$
declare
    v_now timestamp;
begin
    select simulated_time into v_now from system_time limit 1;
    if v_now is null or new.datetime < v_now then
        raise exception 'Une réservation ne peut pas être créée dans le passé.';
    end if;

    return new;
end;
$$ language plpgsql security definer;

create or replace trigger trigger_reservation_not_in_past
before insert
on reservations
for each row
execute function function_reservation_not_in_past();


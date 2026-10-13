set search_path to public;

-- (BR-02) Le nombre de convives d'une réservation confirmée ou terminée ne peut pas dépasser la capacité totale des tables associées à la réservation.
-- Ceci implique qu'une réservation confirmée ou terminée doit avoir au moins une table réservée appartenant au restaurant de la réservation.
--
-- 	tables : reservations, reservations_tables, tables
--
-- 	événements :
-- 		reservations :
--          insert : oui si la réservation est directement confirmée ou complétée
--          update : oui car cela peut changer le statut ou le nombre de convives
-- 			delete : non car les tables associées sont supprimées en cascade
--
-- 		reservations_tables :
-- 			insert : non car l'ajout d'une table augmente la capacité
-- 			update : non car on ne peut pas modifier cette table
--          delete : oui au cas où on supprime une table d'une réservation confirmée ou complétée
--
--     tables :
--          insert : non car la capacité d'une nouvelle table n'affecte pas les réservations existantes
--          update : oui car cela peut réduire la capacité totale
-- 			delete : oui car la suppression d'une table réduit la capacité totale

create or replace function function_reservation_capacity() returns trigger as
$$
begin
    if exists(select r.id, r.number_of_guests, coalesce(sum(t.capacity), 0)
            from reservations r
                left join reservation_tables rt on rt.reservation = r.id
                left join tables t on t.id = rt."table"
            where r.status in ('confirmed'::status_type, 'completed'::status_type)
            group by r.id, r.number_of_guests
            having r.number_of_guests > coalesce(sum(t.capacity), 0)) then
        raise exception 'Le nombre de convives dépasse la capacité totale.';
    end if;
    return null;
end;
$$ language plpgsql security definer;

create trigger trigger_validate_reservation_capacity
    after insert or update of number_of_guests, status
    on reservations
    for each row
execute function function_reservation_capacity();

create constraint trigger trigger_validate_reservation_tables_capacity
    after delete
    on reservation_tables
    deferrable initially deferred
    for each row
execute function function_reservation_capacity();

create trigger trigger_validate_tables_capacity_update
    after update of capacity
    on tables
    for each row
execute function function_reservation_capacity();

create trigger trigger_validate_tables_capacity_delete
    after delete
    on tables
    for each row
execute function function_reservation_capacity();

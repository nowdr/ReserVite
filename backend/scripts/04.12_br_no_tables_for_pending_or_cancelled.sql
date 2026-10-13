set search_path to public;

-- (BR-12) Une réservation en attente ou annulée ne peut être associée à aucune table.
--
-- tables : reservations, reservation_tables
--
-- événements :
--     reservations : status
--         insert : non car une nouvelle réservation n'a pas encore de tables associées
--         update : oui si status passe à pending ou cancelled alors que des tables sont associées
--         delete : non car les associations sont supprimées en cascade
--
--     reservation_tables :
--         insert : oui pour vérifier que la réservation n'est ni pending ni cancelled
--         update : oui si on change la réservation associée
--         delete : non car libérer une table ne crée pas d'incohérence

create or replace function function_reservation_no_tables_on_reservation_tables() returns trigger as
$$
begin
    if exists (
        select 1
        from reservations r
                 join reservation_tables rt on rt.reservation = r.id
        where r.id = new.reservation
          and r.status in ('pending', 'cancelled')
    ) then
        raise exception 'Une réservation pending ou cancelled ne peut être associée à aucune table.';
    end if;

    return new;
end;
$$ language plpgsql security definer;

create or replace function function_reservation_no_tables_on_reservations() returns trigger as
$$
begin
    if new.status in ('pending', 'cancelled') and exists (
        select 1
        from reservation_tables rt
        where rt.reservation = new.id
    ) then
        raise exception 'Une réservation pending ou cancelled ne peut être associée à aucune table.';
    end if;

    return new;
end;
$$ language plpgsql security definer;

create constraint trigger check_reservation_no_tables_on_reservation_tables
    after insert or update
    on reservation_tables
    deferrable initially deferred
    for each row
    execute function function_reservation_no_tables_on_reservation_tables();

create constraint trigger check_reservation_no_tables_on_reservations
    after update of status
    on reservations
    deferrable initially deferred
    for each row
    execute function function_reservation_no_tables_on_reservations();



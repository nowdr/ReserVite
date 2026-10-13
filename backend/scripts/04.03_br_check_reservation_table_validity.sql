set search_path to public;

-- (BR-03) Les tables associées à une réservation doivent appartenir au restaurant de la réservation.
--
-- tables : reservations, reservation_tables, tables
--
-- événements :
--     reservations : restaurant
--         insert : non car aucune table n'est encore associée à la réservation
--         update : non car le restaurant d'une réservation n'est pas modifiable
--         delete : non car les associations sont supprimées en cascade
--
--     reservation_tables :
--         insert : oui pour vérifier que la table appartient au restaurant de la réservation
--         update : oui car on peut changer la table ou la réservation associée
--         delete : non car libérer une table ne crée pas d'incohérence
--
--     tables : restaurant
--         insert : non car aucune réservation ne référence encore cette table
--         update : non car le restaurant d'une table n'est pas modifiable
--         delete : non car les associations sont supprimées en cascade

create or replace function function_reservation_table_validity() returns trigger as
$$
    begin
        if exists (select * from tables, reservations where tables.id = new.table
                                                        and reservations.id = new.reservation
                                                        and tables.restaurant != reservations.restaurant) then
            raise exception 'La table assignée à une réservation doit appartenir au même restaurant.';
        end if;
        return new;
    end;
$$ language plpgsql security definer;

create constraint trigger check_reservation_table_validity
    after insert or update
    on reservation_tables
    deferrable initially deferred
    for each row
    execute function function_reservation_table_validity();

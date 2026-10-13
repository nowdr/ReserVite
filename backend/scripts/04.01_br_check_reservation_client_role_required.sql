set search_path to public;

-- (BR-01) Une réservation doit être associée à un utilisateur ayant le rôle de client.
--
-- 	tables : reservations, users
--
-- 	événements :
-- 		reservations :
-- 		    insert : oui pour vérifier si l'utilisateur associé est un client
-- 			update : non car on ne peut pas modifier le client d'une réservation
--          delete : non car la réservation n'existe plus
--
-- 		users :
-- 		    insert : non car aucune réservation n'est liée à ce nouvel utilisateur
--          update : non car on ne peut pas modifier le rôle d'un utilisateur
-- 		    delete : non car les réservations associées sont supprimées en cascade

create or replace function function_reservation_client_role() returns trigger as
$$
    begin
        if (select role from users where id = new.client) != 'client' then
            raise exception 'Les réservations ne peuvent être créées que par des utilisateurs ayant le rôle client.';
        end if;
        return new;
    end;
$$ language plpgsql security definer;

create or replace trigger trigger_reservation_client_role
    before insert
    on reservations
    for each row
    execute function function_reservation_client_role();

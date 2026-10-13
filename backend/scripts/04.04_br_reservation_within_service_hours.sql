set search_path to public;

-- (BR-04) L'heure d'une réservation confirmée, terminée ou en attente doit être comprise
-- entre l'heure de début et l'heure de fin d'un service pour le même jour de la semaine.
--
-- tables : reservations, services
--
-- événements :
--     reservations :
--         insert : oui pour vérifier l'heure si le statut est pending, confirmed ou completed
--         update : oui car cela peut changer datetime ou status
--         delete : non
--
--     services :
--         insert : non car ne peut que rendre des réservations valides
--         update : oui car réduire les horaires peut invalider une réservation existante
--         delete : oui car peut laisser des réservations sans service correspondant

create or replace function function_reservation_within_service_hours() returns trigger as
$$
begin
    if new.status in ('pending', 'confirmed', 'completed') then
        if not exists(
            select 1 from services s
            where s.restaurant = new.restaurant
              and s.day_of_week = extract(isodow from new.datetime)
              and new.datetime::time between s.start_time and s.end_time
        ) then
            raise exception 'L''heure d''une réservation confirmée, terminée ou en attente doit être comprise
                        entre l''heure de début et l''heure de fin d''un service pour le même jour de la semaine.';
        end if;
    end if;
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger trigger_reservation_within_service_hours
before insert or update of datetime, status
on reservations
for each row
execute function function_reservation_within_service_hours();

create or replace function function_services_cover_reservations() returns trigger as
$$
begin
    if exists (
        select 1
        from reservations r
        where r.status in ('pending', 'confirmed', 'completed')
          and not exists (
              select 1 from services s
              where s.restaurant = r.restaurant
                and s.day_of_week = extract(isodow from r.datetime)
                and r.datetime::time between s.start_time and s.end_time
          )
    ) then
        raise exception 'Modifier ou supprimer ce service laisse des réservations en dehors des horaires de service.';
    end if;
    return null;
end;
$$ language plpgsql security definer;

create constraint trigger trigger_services_cover_reservations_update
    after update of start_time, end_time, day_of_week
    on services
    deferrable initially deferred
    for each row
execute function function_services_cover_reservations();

create constraint trigger trigger_services_cover_reservations_delete
    after delete
    on services
    deferrable initially deferred
    for each row
execute function function_services_cover_reservations();

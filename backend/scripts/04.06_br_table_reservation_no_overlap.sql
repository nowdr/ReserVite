set search_path to public;

-- (BR-06) Une table ne peut pas faire l'objet de deux réservations terminées ou confirmées
-- pour une même date et un même service.
--
-- tables : reservations, reservation_tables, services
--
-- événements :
--     reservations :
--         insert : non car une nouvelle réservation est toujours pending
--         update : oui si status passe à confirmed/completed ou si datetime change
--         delete : non
--
--     reservation_tables :
--         insert : oui pour vérifier qu'aucune autre réservation confirmée/terminée n'occupe la table
--         update : oui si on change la table ou la réservation
--         delete : non car libérer une table ne crée pas de conflit
--
--     services :
--         insert : non car ne peut que séparer des réservations existantes
--         update : non, modifier un service après réservations existantes est un cas non géré
--         delete : non car sans service il n'y a pas de conflit possible

create or replace function function_table_conflict_exists(
    _reservation_id int,
    _table_id int
) returns boolean as
$$
begin
    return exists (
        select 1
        from reservations r_new
                 join reservation_tables rt_new on rt_new.reservation = r_new.id
                 join reservation_tables rt_other on rt_other.table = rt_new.table
                 join reservations r_other on r_other.id = rt_other.reservation
        where r_new.id = _reservation_id
          and rt_new.table = _table_id
          and r_new.status in ('confirmed', 'completed')
          and rt_other.reservation != r_new.id
          and r_other.status in ('confirmed', 'completed')
          and r_other.restaurant = r_new.restaurant
          and r_other.datetime::date = r_new.datetime::date
          and exists (
            select 1
            from services s
            where s.restaurant = r_new.restaurant
              and s.day_of_week = extract(isodow from r_new.datetime)
              and r_new.datetime::time between s.start_time and s.end_time
              and r_other.datetime::time between s.start_time and s.end_time
        )
    );
end;
$$ language plpgsql security definer;

create or replace function function_table_reservation_no_overlap_from_table() returns trigger as
$$
begin
    if function_table_conflict_exists(new.reservation, new.table) then
        raise exception 'Une table ne peut pas être assignée à deux réservations confirmées ou terminées pour une même date et un même service.';
    end if;

    return new;
end;
$$ language plpgsql security definer;

create constraint trigger check_table_reservation_no_overlap_from_table
    after insert or update
    on reservation_tables
    deferrable initially deferred
    for each row
execute function function_table_reservation_no_overlap_from_table();

create or replace function function_table_reservation_no_overlap_from_reservation() returns trigger as
$$
begin
    if new.status in ('confirmed', 'completed') and exists (
        select 1
        from reservation_tables rt
        where rt.reservation = new.id
          and function_table_conflict_exists(new.id, rt.table)
    ) then
        raise exception 'Une table ne peut pas être assignée à deux réservations confirmées ou terminées pour une même date et un même service.';
    end if;

    return new;
end;
$$ language plpgsql security definer;

create or replace trigger trigger_table_reservation_no_overlap_from_reservation
before update of status, datetime
on reservations
for each row
execute function function_table_reservation_no_overlap_from_reservation();


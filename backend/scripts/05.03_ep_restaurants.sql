set search_path to public;

create or replace function get_client_restaurants(search_filter text, limit_count int) returns setof json as
$$
    begin
        perform auth.check_logged();

        if (auth.role() != 'client') then
            raise exception 'Accès refusé : rôle incorrect.';
        end if;

        return query
            select json_build_object(
                           'id', id,
                           'name', name,
                           'city', city,
                           'rating', rating,
                           'price_range', price_range,
                           'last_reservation', (
                               select datetime
                               from reservations
                               where client = auth.id() and restaurant = r.id
                               order by datetime desc
                               limit 1
                               ),
                           'pending_reservations', (
                               select count(*)
                               from reservations
                               where status = 'pending' and client = auth.id() and restaurant = r.id
                               )
                   )
            from restaurants r
            where search_filter = ''
               or lower(concat(name, ' ', address, ' ', city, ' ', description)) like concat('%', lower(search_filter), '%')
            order by (
                select max(datetime)
                from reservations
                where client = auth.id() and restaurant = r.id
            ) desc nulls last
            limit limit_count + 1;
    end;
$$ language plpgsql security definer;

grant execute on function get_client_restaurants(search_filter text, limit_count int) to authenticated;

create or replace function get_client_restaurant(restaurant_id int) returns json as
$$
    declare
        result json;
    begin
        perform auth.check_logged();

        if (auth.role() != 'client') then
            raise exception 'Accès refusé : rôle incorrect.';
        end if;

        select json_build_object(
                       'id', id,
                       'name', name,
                       'address', address,
                       'city', city,
                       'description', description,
                       'rating', rating,
                       'price_range', price_range,
                       'services', (
                           select json_agg(
                                          json_build_object(
                                                  'id', id,
                                                  'day_of_week', day_of_week,
                                                  'start_time', start_time,
                                                  'end_time', end_time
                                          )
                                  )
                           from services s
                           where restaurant = r.id
                       )
               )
        into result
        from restaurants r
        where id = restaurant_id;

        return result;
    end;
$$ language plpgsql security definer;

grant execute on function get_client_restaurant(restaurant_id int) to authenticated;

create or replace function get_manager_restaurants() returns setof json as
$$
    begin
        perform auth.check_logged();

        if (auth.role() != 'manager') then
            raise exception 'Accès refusé : rôle incorrect.';
        end if;

        return query
            select json_build_object(
                           'id', id,
                           'name', name,
                           'city', city,
                           'rating', rating,
                           'price_range', price_range,
                           'last_reservation', (
                               select datetime
                               from reservations
                               where restaurant = r.id
                               order by datetime desc
                               limit 1
                               ),
                           'pending_reservations', (
                               select count(*)
                               from reservations
                               where status = 'pending' and restaurant = r.id
                               )
                   )
            from restaurants r
            where id in (
                select restaurant
                from restaurant_managers
                where manager = auth.id()
            )
            order by (
                select max(datetime)
                from reservations
                where restaurant = r.id
            ) desc nulls last;
    end;
$$ language plpgsql security definer;

grant execute on function get_manager_restaurants() to manager;

drop function if exists get_available_slots(int, date);

create or replace function get_available_slots(
    _restaurant_id int,
    _date date,
    _exclude_reservation int default null
) returns setof json as
$$
begin
    perform auth.check_logged();

    if (auth.role() not in ('client', 'manager')) then
        raise exception 'Accès refusé : rôle incorrect.';
    elseif (auth.role() = 'manager' and auth.id() not in (select manager from restaurant_managers where restaurant = _restaurant_id)) then
        raise exception 'Accès refusé : action non autorisée.';
    end if;

    return query
        with service_windows as (
            -- Plages horaires du restaurant ce jour, sans celles où le client
            -- a déjà une réservation (BR-13 : une seule réservation par service).
            select s.id as service_id, s.start_time, s.end_time, r.slot_duration
            from services s
                     join restaurants r on r.id = s.restaurant
            where s.restaurant = _restaurant_id
              and s.day_of_week = extract(isodow from _date)
              and s.id not in (
                  select function_service_id(restaurant, datetime)
                  from reservations
                  where client = auth.id()
                    and restaurant = _restaurant_id
                    and datetime::date = _date
                    and status in ('pending', 'confirmed', 'completed')
                    and (_exclude_reservation is null or id != _exclude_reservation)
              )
        ),
             all_slots as (
                 -- Tous les créneaux possibles dans ces plages horaires
                 -- (un créneau doit pouvoir finir avant la fin du service)
                 select sw.service_id,
                        generate_series(
                                '2000-01-01'::timestamp + sw.start_time,
                                '2000-01-01'::timestamp + sw.end_time - (sw.slot_duration || ' minutes')::interval,
                                (sw.slot_duration || ' minutes')::interval
                        )::time as slot_time
                 from service_windows sw
             ),
             booked_slots as (
                 -- Les créneaux déjà réservés (hors annulations), en excluant la réservation éditée
                 select datetime::time as slot_time
                 from reservations
                 where restaurant = _restaurant_id
                   and datetime::date = _date
                   and status != 'cancelled'
                   and (_exclude_reservation is null or id != _exclude_reservation)
             ),
             restaurant_capacity as (
                 -- Capacité totale du restaurant (somme des capacités de toutes ses tables)
                 select coalesce(sum(t.capacity), 0) as total
                 from tables t
                 where t.restaurant = _restaurant_id
             ),
             remaining_per_service as (
                 -- Capacité restante = capacité totale - convives déjà réservés (non annulés)
                 -- dans la même plage horaire de service ce jour, en excluant la réservation éditée.
                 select sw.service_id,
                        greatest(
                            (select total from restaurant_capacity)
                            - coalesce((
                                  select sum(res.number_of_guests)
                                  from reservations res
                                  where res.restaurant = _restaurant_id
                                    and res.datetime::date = _date
                                    and res.status != 'cancelled'
                                    and res.datetime::time between sw.start_time and sw.end_time
                                    and (_exclude_reservation is null or res.id != _exclude_reservation)
                              ), 0),
                            0
                        ) as remaining
                 from service_windows sw
             )
        select json_build_object(
                       'time', to_char(s.slot_time, 'HH24:MI'),
                       'remaining_capacity', rps.remaining
               )
        from all_slots s
                 join remaining_per_service rps on rps.service_id = s.service_id
        where s.slot_time not in (select slot_time from booked_slots)
        order by s.slot_time;
end;
$$ language plpgsql security definer;

grant execute on function get_available_slots(int, date, int) to authenticated;

set search_path to public;

create or replace function get_restaurant_tables_availibility(restaurant_id int, reservation_id int) returns setof json as
$$
    declare
        v_datetime timestamp;
    begin
        perform auth.check_logged();

        if (auth.role() != 'manager') then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif auth.id() not in (
            select manager
            from restaurant_managers
            where restaurant = restaurant_id
        ) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        select datetime into v_datetime
        from reservations
        where id = reservation_id;

        return query
            select json_build_object(
                           'id', t.id,
                           'table_number', t.table_number,
                           'capacity', t.capacity,
                           'is_available', (
                               select not exists(
                                   select 1
                                   from reservation_tables rt
                                       join reservations r on rt.reservation = r.id
                                   where rt."table" = t.id
                                     and r.id != reservation_id
                                     and r.status = 'confirmed'
                                     and r.datetime::date = v_datetime::date
                                     and exists(
                                         select 1
                                         from services s
                                         where s.restaurant = restaurant_id
                                           and s.day_of_week = extract(isodow from v_datetime)
                                           and v_datetime::time between s.start_time and s.end_time
                                           and r.datetime::time between s.start_time and s.end_time
                                   )
                               )
                           )
                   )
            from tables t
            where t.restaurant = restaurant_id;
    end;
$$ language plpgsql security definer;

grant execute on function get_restaurant_tables_availibility(restaurant_id int, reservation_id int) to authenticated;
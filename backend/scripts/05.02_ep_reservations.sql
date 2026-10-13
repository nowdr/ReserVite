set search_path to public;

create or replace function get_client_reservations() returns setof json as
$$
    begin
        perform auth.check_logged();

        if (auth.role() != 'client') then
            raise exception 'Accès refusé : rôle incorrect.';
        end if;

        return query
            select json_build_object(
                   'id', id,
                    'restaurant', (
                        select json_build_object(
                                       'id', r.id,
                                       'name', r.name,
                                       'city', r.city
                               )
                        from restaurants r
                        where r.id = restaurant
                       ),
                   'datetime', datetime,
                   'number_of_guests', number_of_guests,
                   'status', status
                   )
            from reservations
            where client = auth.id()
            order by datetime desc, id;
    end;
$$ language plpgsql security definer;
grant execute on function get_client_reservations() to authenticated;

create or replace function get_client_reservation(reservation_id int) returns  json as
$$
    declare
        result json;
    begin
        perform auth.check_logged();

        if (auth.role() != 'client') then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif (auth.id() != (select client from reservations where id = reservation_id)) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        select json_build_object(
                       'id', id,
                       'restaurant', (
                            select json_build_object(
                                          'id', r.id,
                                          'name', r.name,
                                          'address', address,
                                          'city', r.city,
                                          'phone', phone
                                  )
                           from restaurants r
                           where r.id = restaurant
                       ),
                       'datetime', datetime,
                       'number_of_guests', number_of_guests,
                       'status', status,
                       'special_requests', special_requests
               )
        into result
        from reservations
        where id = reservation_id;

        return result;
    end;
$$ language plpgsql security definer;

grant execute on function get_client_reservation(reservation_id int) to authenticated;

create or replace function cancel_reservation(_id int) returns void as
$$
    begin
        perform auth.check_logged();

        if (auth.role() not in ('client', 'manager')) then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif auth.id() not in (
            select client
            from reservations
            where id = _id
            union
            select manager
            from restaurant_managers
            where restaurant = (select restaurant from reservations where id = _id)
        ) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        delete from reservation_tables where reservation = _id;
        update reservations set status = 'cancelled' where id = _id;
    end;
$$ language plpgsql security definer;

grant execute on function cancel_reservation(_id int) to authenticated;

create or replace function complete_reservation(_id int) returns void as
$$
    begin
        perform auth.check_logged();

        if (auth.role() != 'manager') then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif auth.id() not in (
            select manager
            from restaurant_managers
            where restaurant = (select restaurant from reservations where id = _id)
        ) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        update reservations set status = 'completed' where id = _id;
    end;
$$ language plpgsql security definer;

grant execute on function complete_reservation(_id int) to authenticated;

create or replace function save_reservation(
    _restaurant_id int,
    _datetime timestamp,
    _number_of_guests int,
    _special_requests text default null,
    _reservation_id int default null
) returns int as
$$
declare
    saved_id int;
begin
    perform auth.check_logged();

    if (auth.role() != 'client') then
        raise exception 'Accès refusé : rôle incorrect.';
    end if;

    if _reservation_id is null then
        insert into reservations (client, restaurant, datetime, number_of_guests, special_requests)
        values (auth.id(), _restaurant_id, _datetime, _number_of_guests, _special_requests)
        returning id into saved_id;
    else
        update reservations
        set restaurant = _restaurant_id, --TODO: éviter de renvoyer l'id du restaurant comme on ne peut pas le changer ?
            datetime = _datetime,
            number_of_guests = _number_of_guests,
            special_requests = _special_requests,
            status = 'pending'
        where id = _reservation_id and client = auth.id()
        returning id into saved_id;
    end if;

    return saved_id;
end;
$$ language plpgsql security definer;

grant execute on function save_reservation(int, timestamp, int, text, int) to authenticated;

create or replace function confirm_reservation(reservation_id int, selected_tables int[]) returns void as
$$
    declare
        selected_table int;
    begin
        perform auth.check_logged();

        if (auth.role() != 'manager') then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif auth.id() not in (
            select manager
            from restaurant_managers
            where restaurant = (select restaurant from reservations where id = reservation_id)
        ) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        foreach selected_table in array selected_tables loop
            insert into reservation_tables (reservation, "table")
            values (reservation_id, selected_table);
        end loop;

        update reservations
        set status = 'confirmed'
        where id = reservation_id;
    end;
$$ language plpgsql security definer;

grant execute on function confirm_reservation(reservation_id int, selected_tables int[]) to authenticated;

create or replace function get_manager_reservations(restaurant_id int) returns setof json as
$$
    begin
        perform auth.check_logged();

        if (auth.role() != 'manager') then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif auth.id() not in (
            select rm.manager
            from restaurant_managers rm
            where rm.restaurant = restaurant_id
        ) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        return query
            select json_build_object(
                           'id', r.id,
                           'client', (
                                select json_build_object(
                                       'id', u.id,
                                       'full_name', u.full_name
                                       )
                                from users u
                                where u.id = r.client
                                ),
                           'restaurant', (
                               select json_build_object(
                                      'id', res.id,
                                      'name', res.name
                                      )
                               from restaurants res
                               where res.id = r.restaurant
                               ),
                           'datetime', datetime,
                           'number_of_guests', number_of_guests,
                           'status', status
                   )
            from reservations r
            where r.restaurant = restaurant_id
            order by datetime desc;
    end;
$$ language plpgsql security definer;

grant execute on function get_manager_reservations(restaurant_id int) to authenticated;

create or replace function get_manager_reservation(reservation_id int) returns json as
$$
    declare
        result json;
    begin
        perform auth.check_logged();

        if (auth.role() != 'manager') then
            raise exception 'Accès refusé : rôle incorrect.';
        elseif auth.id() not in (
            select rm.manager
            from restaurant_managers rm
            join reservations r on rm.restaurant = r.restaurant
            where r.id = reservation_id
        ) then
            raise exception 'Accès refusé : action non autorisée.';
        end if;

        select json_build_object(
                       'id', r.id,
                       'client', (
                           select json_build_object(
                                          'id', u.id,
                                          'full_name', u.full_name,
                                          'email', u.email,
                                          'phone', u.phone
                                  )
                           from users u
                           where u.id = r.client
                       ),
                       'restaurant', (
                           select json_build_object(
                                          'id', res.id,
                                          'name', res.name
                                  )
                           from restaurants res
                           where res.id = r.restaurant
                       ),
                       'datetime', r.datetime,
                       'number_of_guests', r.number_of_guests,
                       'status', r.status,
                       'tables', (
                           select json_agg(
                                          json_build_object(
                                                  'id', t.id,
                                                  'table_number', t.table_number,
                                                  'capacity', t.capacity
                                          )
                                  )
                           from tables t
                               join reservation_tables rt on rt.table = t.id
                           where rt.reservation = r.id
                       )
               )
        into result
        from reservations r
        where r.id = reservation_id;

        return result;
    end;
$$ language plpgsql security definer;

grant execute on function get_manager_reservation(reservation_id int) to authenticated;
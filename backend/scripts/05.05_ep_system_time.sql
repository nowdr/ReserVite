set search_path to public;

create or replace function get_system_time() returns setof json as
$$
    begin
        return query
            select json_build_object('simulated_time', simulated_time)
            from system_time
            limit 1;
    end;
$$ language plpgsql security definer;

grant execute on function get_system_time() to anon;

create or replace function save_system_time(_simulated_time timestamp) returns setof json as
$$
    begin
        update system_time
        set simulated_time = _simulated_time;

        return query
            select json_build_object('simulated_time', simulated_time)
            from system_time
            limit 1;
    end;
$$ language plpgsql security definer;

grant execute on function save_system_time(timestamp) to anon;

create or replace function clear_system_time() returns void as
$$
    begin
        update system_time set simulated_time = null;
    end;
$$ language plpgsql security definer;

grant execute on function clear_system_time() to anon;

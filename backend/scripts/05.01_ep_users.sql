set search_path to public;

create or replace function check_full_name_available(_full_name text) returns boolean as
$$
begin
    return not exists(select 1 from users where lower(full_name) = lower(_full_name));
end;
$$ language plpgsql security definer;

grant execute on function check_full_name_available to anon;

create or replace function check_email_available(_email text) returns boolean as
$$
begin
    return not exists(select 1 from users where lower(email) = lower(_email));
end;
$$ language plpgsql security definer;

grant execute on function check_email_available to anon;

create or replace function signup(_email text, _password text, _full_name text, _phone text) returns void as
$$
    begin
        if not (check_full_name_available(_full_name) and check_email_available(_email)) then
            raise exception 'Échec inscription';
        end if;
        insert into users (email, password, full_name, phone) values (_email, _password, _full_name, _phone);
    end;
$$ language plpgsql security definer;

grant execute on function signup to anon;

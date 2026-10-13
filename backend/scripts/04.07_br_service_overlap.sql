set search_path to public;

-- (BR-07) Pour un même jour de la semaine, les services d'un restaurant ne peuvent pas se chevaucher.
--
-- tables : services
--
-- événements :
--     services :
--         insert : oui pour vérifier qu'aucun service existant ne chevauche
--         update : oui si day_of_week, start_time ou end_time change
--         delete : non car la suppression ne peut pas créer de chevauchement

create or replace function function_service_no_overlap() returns trigger as
$$
begin
if exists (
        select 1 from services
        where restaurant = new.restaurant
          and day_of_week = new.day_of_week
          and id != new.id
          and (new.start_time, new.end_time) overlaps (start_time, end_time)
    ) then
        raise exception 'Les services d''un restaurant ne peuvent pas se chevaucher pour un même jour';
    end if;
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger trigger_service_no_overlap
before insert or update of day_of_week, start_time, end_time
on services
for each row
execute function function_service_no_overlap();

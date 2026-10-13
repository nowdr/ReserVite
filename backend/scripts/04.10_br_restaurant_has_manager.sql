set search_path to public;

-- (BR-10) Un restaurant doit avoir au moins un manager.
--
-- tables : restaurants, restaurant_managers
--
-- événements :
--     restaurants :
--         insert : oui en théorie car un nouveau restaurant doit déjà avoir un manager (à vérifier en deferred)
--         update : non car ne change pas la liste des managers
--         delete : non car les restaurant_managers sont supprimés en cascade
--
--     restaurant_managers :
--         insert : non car ajouter un manager ne peut pas violer la règle
--         update : oui si on change le restaurant d'un manager, mais cas non géré actuellement
--         delete : oui car peut laisser un restaurant sans manager

create or replace function function_restaurant_has_manager() returns trigger as
$$
begin
    if (select count(*) from restaurant_managers where restaurant = old.restaurant) = 1 then
        raise exception 'Un restaurant doit avoir au moins un manager.';
    end if;
    return old;
end;
$$ language plpgsql security definer;

create or replace trigger trigger_restaurant_has_manager
before delete
on restaurant_managers
for each row
execute function function_restaurant_has_manager();

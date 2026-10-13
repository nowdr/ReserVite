set search_path to public;

-- (BR-10) Un restaurant doit avoir au moins un manager.

-- region delete_sole_manager
begin;
do
$test$
    begin
        raise notice 'TEST(restaurant_managers): le dernier manager d''un restaurant ne peut pas être supprimé';
        perform should_fail($$
            delete from restaurant_managers where restaurant = 3 and manager = 2;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region delete_sole_manager_other_restaurant
begin;
do
$test$
    begin
        raise notice 'TEST(restaurant_managers): le dernier manager d''un autre restaurant ne peut pas être supprimé';
        perform should_fail($$
            delete from restaurant_managers where restaurant = 6 and manager = 5;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

-- region delete_all_managers
begin;
do
$test$
    begin
        raise notice 'TEST(restaurant_managers): supprimer tous les managers d''un restaurant est impossible';
        perform should_fail($$
            delete from restaurant_managers where restaurant = 1;
        $$, 'raise_exception');
    end;
$test$;
rollback;
-- endregion

set search_path to public;

-- (BR-09) Une nouvelle réservation doit avoir le status pending. Une réservation existante ne peut pas revenir "en arrière" dans son cycle de vie. Les transitions autorisées sont :
-- pending -> confirmed
-- pending -> cancelled
-- confirmed -> completed
-- confirmed -> cancelled
-- La transition confirmed -> pending est autorisée dans certains cas (voir règles temporelles).
-- Aucune transition depuis completed ou cancelled n'est autorisée.
--
-- tables : reservations
--
-- événements :
--     reservations : status
--         insert : oui pour vérifier que le statut initial est pending
--         update : oui pour vérifier que la transition est autorisée
--         delete : non

create or replace function function_reservation_status() returns trigger as
$$
    begin
        if tg_op = 'INSERT' then
            if new.status <> 'pending' then
                raise exception 'Une nouvelle réservation doit avoir le statut pending.';
            end if;
            return new;
        end if;

        -- UPDATE
        if new.status = old.status then
            return new;
        end if;

        case old.status
            when 'pending' then
                if new.status not in ('confirmed', 'cancelled') then
                    raise exception 'Une réservation pending ne peut passer qu''à confirmed ou cancelled.';
                end if;
            when 'confirmed' then
                if new.status = 'pending' then
                    if new.datetime <= (select simulated_time from system_time) then
                        raise exception 'La date d''une réservation ne peut pas être dans le passé.';
                    end if;
                elseif new.status not in ('completed', 'cancelled') then
                    raise exception 'Une réservation confirmed ne peut passer qu''à pending (sous condition), completed ou cancelled.';
                end if;
            when 'completed', 'cancelled' then
                raise exception 'Les réservations cancelled et completed ne peuvent pas être modifiées.';
            else
                raise exception 'Statut de réservation inconnu.';
        end case;

        return new;
    end;
$$ language plpgsql security definer;

create or replace trigger trigger_reservation_status
    before insert or update of status
    on reservations
    for each row
    execute function function_reservation_status();

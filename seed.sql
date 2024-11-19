create table reservations.events
(
    event_id   serial
        primary key,
    event_name varchar(255) not null,
    event_date timestamp    not null
);

alter table reservations.events
    owner to postgres;

create table if not exists reservations.tickets
(
    seat_id      serial
        primary key,
    event_id     integer     not null
        constraint fk_event
            references reservations.events,
    sector       varchar(50) not null,
    row          integer     not null,
    seat         integer     not null,
    is_available boolean   default true,
    last_changed timestamp default CURRENT_TIMESTAMP,
    constraint unique_event_seat
        unique (event_id, sector, row, seat)
);

alter table reservations.tickets
    owner to postgres;

create index if not exists event_sector_idx
    on reservations.tickets (event_id, sector);

create index if not exists seat_id_last_changed_is_available_idx
    on reservations.tickets (seat_id, last_changed, is_available);

DO
$$
    DECLARE
        event_id  INTEGER     :=  2; -- Replace with your actual event_id or loop for different events
        sector    VARCHAR(50) := 'A'; -- Replace with desired sector if needed
        row_num   INTEGER;
        seat_num  INTEGER;
    BEGIN
        FOR row_num IN 1..10
            LOOP
                FOR seat_num IN 1..25
                    LOOP
                        INSERT INTO reservations.tickets (event_id, sector, row, seat, is_available)
                        VALUES (event_id, sector, row_num, seat_num, TRUE);
                    END LOOP;
            END LOOP;
    END
$$;

update reservations.tickets set is_available = true, last_changed = now() where event_id = 3;

CREATE OR REPLACE FUNCTION reservations.reserve_seats2(p_seat_data jsonb)
    RETURNS integer
    LANGUAGE plpgsql
AS $function$
DECLARE
    locked_rows INTEGER;
BEGIN
    -- Lock the rows for update and count them
    WITH locked_seats AS (
        SELECT t.seat_id
        FROM reservations.tickets t
        WHERE (t.seat_id, t.last_changed) IN (
            SELECT (s->>'seat_id')::INTEGER, (s->>'last_changed')::TIMESTAMP
            FROM jsonb_array_elements(p_seat_data) AS s
        )
          AND t.is_available = TRUE
            FOR UPDATE
    )
    SELECT COUNT(*) INTO locked_rows FROM locked_seats;

    -- Check if all seats are available
    IF locked_rows = jsonb_array_length(p_seat_data) THEN
        -- Reserve the seats
        UPDATE reservations.tickets
        SET is_available = FALSE, last_changed = NOW()
        WHERE (seat_id, last_changed) IN (
            SELECT (s->>'seat_id')::INTEGER, (s->>'last_changed')::TIMESTAMP
            FROM jsonb_array_elements(p_seat_data) AS s
        )
          AND is_available = TRUE;

        RETURN 0; -- Success
    ELSE
        RETURN -1; -- Some seats are already reserved
    END IF;
END;
$function$
;

CREATE SCHEMA IF NOT EXISTS reservations;

GRANT ALL PRIVILEGES ON SCHEMA reservations TO postgres;

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

CREATE OR REPLACE FUNCTION reservations.reserve_seats(p_seat_data jsonb)
    RETURNS integer
    LANGUAGE plpgsql
AS $function$
DECLARE
    locked_rows INTEGER;
BEGIN
    WITH locked_seats AS (
        SELECT t.seat_id
        FROM reservations.tickets t
        WHERE (t.seat_id, t.last_changed) IN (
            SELECT (s->>'seat_id')::INTEGER, (s->>'last_changed')::TIMESTAMP
            FROM jsonb_array_elements(p_seat_data) AS s
        )
          AND t.is_available = TRUE
            FOR UPDATE NOWAIT 
    )
    SELECT COUNT(*) INTO locked_rows FROM locked_seats;

    IF locked_rows = jsonb_array_length(p_seat_data) THEN
        UPDATE reservations.tickets
        SET is_available = FALSE, last_changed = NOW()
        WHERE (seat_id, last_changed) IN (
            SELECT (s->>'seat_id')::INTEGER, (s->>'last_changed')::TIMESTAMP
            FROM jsonb_array_elements(p_seat_data) AS s
        )
          AND is_available = TRUE;

        RETURN 0;
    ELSE
        RETURN -1;
    END IF;
END;
$function$
;


-- Insert events
INSERT INTO reservations.events (event_id, event_name, event_date) VALUES
    (1, 'Game 1', NOW() - INTERVAL '14 day'),
    (2, 'Game 2', NOW() - INTERVAL '7 day'),
    (3, 'Ed Sheeran 3', NOW() - INTERVAL '1 day');

-- Generate tickets
DO $$
DECLARE
    event_id  INTEGER;
    sector    VARCHAR(50);
    row_num   INTEGER;
    seat_num  INTEGER;
BEGIN
    -- Event 1, 100 seats in sector 'A'
    event_id := 1;
    sector := 'A';
    FOR row_num IN 1..10 LOOP
        FOR seat_num IN 1..10 LOOP
            INSERT INTO reservations.tickets (event_id, sector, row, seat, is_available)
            VALUES (event_id, sector, row_num, seat_num, TRUE);
        END LOOP;
    END LOOP;

    -- Event 2, 100 seats in sector 'A'
    event_id := 2;
    sector := 'A';
    FOR row_num IN 1..10 LOOP
        FOR seat_num IN 1..10 LOOP
            INSERT INTO reservations.tickets (event_id, sector, row, seat, is_available)
            VALUES (event_id, sector, row_num, seat_num, TRUE);
        END LOOP;
    END LOOP;

    -- Event 3, 15000 seats in sector 'A'
    event_id := 3;
    sector := 'A';
    FOR row_num IN 1..150 LOOP
        FOR seat_num IN 1..100 LOOP
            INSERT INTO reservations.tickets (event_id, sector, row, seat, is_available)
            VALUES (event_id, sector, row_num, seat_num, TRUE);
        END LOOP;
    END LOOP;
END $$;


--update reservations.tickets set is_available = true, last_changed = now() where event_id = 3;

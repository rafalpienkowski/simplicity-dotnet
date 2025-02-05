CREATE SCHEMA IF NOT EXISTS tickets;
GRANT ALL PRIVILEGES ON SCHEMA tickets TO postgres;

CREATE SCHEMA IF NOT EXISTS availability;
GRANT ALL PRIVILEGES ON SCHEMA availability TO postgres;

CREATE TABLE IF NOT EXISTS tickets.events
(
    event_id   SERIAL PRIMARY KEY,
    event_name VARCHAR(255) NOT NULL,
    event_date TIMESTAMP    NOT NULL
);

ALTER TABLE tickets.events
    OWNER TO postgres;

CREATE TABLE IF NOT EXISTS tickets.seats
(
    seat_id  SERIAL PRIMARY KEY,
    event_id INTEGER     NOT NULL
        CONSTRAINT fk_event
            REFERENCES tickets.events,
    sector   VARCHAR(50) NOT NULL,
    row      INTEGER     NOT NULL,
    seat     INTEGER     NOT NULL,
    CONSTRAINT unique_event_seat
        UNIQUE (event_id, sector, row, seat)
);

ALTER TABLE tickets.seats
    OWNER TO postgres;

CREATE INDEX IF NOT EXISTS event_sector_idx ON tickets.seats (event_id, sector);

CREATE TABLE IF NOT EXISTS availability.resources
(
    resource_id     SERIAL PRIMARY KEY,
    external_id     INTEGER      NOT NULL,
    external_system VARCHAR(255) NOT NULL,
    is_available    BOOLEAN   DEFAULT true,
    last_changed    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    owner           VARCHAR(255)  not null,
    CONSTRAINT unique_resource_external
        UNIQUE (external_id, external_system)
);

CREATE INDEX IF NOT EXISTS external_id_last_changed_is_available_idx
    on availability.resources (external_system, external_id, last_changed, is_available);

CREATE OR REPLACE FUNCTION availability.reserve(p_data jsonb)
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
DECLARE
    locked_rows INTEGER;
BEGIN
    WITH locked_resources AS (SELECT t.resource_id
                              FROM availability.resources t
                              WHERE (t.external_id, t.last_changed, t.external_system) IN
                                    (SELECT (s ->> 'external_id')::INTEGER, (s ->> 'last_changed')::TIMESTAMP, (s ->> 'external_system')::VARCHAR(255)
                                     FROM jsonb_array_elements(p_data) AS s)
                                AND t.is_available = TRUE
                                  FOR UPDATE NOWAIT)
    SELECT COUNT(*)
    INTO locked_rows
    FROM locked_resources;

    IF locked_rows = jsonb_array_length(p_data) THEN
        UPDATE availability.resources
        SET is_available = FALSE,
            last_changed = NOW(),
            owner = (SELECT (s ->> 'owner')::VARCHAR(255)
                     FROM jsonb_array_elements(p_data) AS s)
        WHERE (external_id, last_changed, external_system) IN
              (SELECT (s ->> 'external_id')::INTEGER, (s ->> 'last_changed')::TIMESTAMP, (s ->> 'external_system')::VARCHAR(255)
               FROM jsonb_array_elements(p_data) AS s)
          AND is_available = TRUE;

        RETURN 0;
    ELSE
        RETURN -1;
    END IF;
END;
$function$
;

CREATE VIEW tickets.available_seats AS
SELECT s.seat_id,
       s.event_id,
       s.row,
       s.seat,
       s.sector,
       r.is_available,
       r.last_changed
FROM tickets.seats s
         JOIN availability.resources r ON s.seat_id = r.external_id
WHERE r.external_system = 'tickets';


-- Insert events
INSERT INTO tickets.events (event_id, event_name, event_date)
VALUES (1, 'Game 1', NOW() - INTERVAL '14 day'),
       (2, 'Game 2', NOW() - INTERVAL '7 day'),
       (3, 'Ed Sheeran 3', NOW() - INTERVAL '1 day');

-- Generate tickets
DO
$$
    DECLARE
        event_id    INTEGER;
        sector      VARCHAR(50);
        row_num     INTEGER;
        seat_num    INTEGER;
        external_id INTEGER;
    BEGIN
        -- Event 1, 100 seats in sector 'A'
        event_id := 1;
        sector := 'A';
        FOR row_num IN 1..10
            LOOP
                FOR seat_num IN 1..10
                    LOOP
                        INSERT INTO tickets.seats (event_id, sector, row, seat)
                        VALUES (event_id, sector, row_num, seat_num)
                        RETURNING seat_id INTO external_id;

                        INSERT INTO availability.resources(external_id, is_available, last_changed, owner, external_system)
                        VALUES (external_id, TRUE, NOW(), 'tickets', 'tickets');
                    END LOOP;
            END LOOP;

        -- Event 2, 100 seats in sector 'A'
        event_id := 2;
        sector := 'A';
        FOR row_num IN 1..10
            LOOP
                FOR seat_num IN 1..10
                    LOOP
                        INSERT INTO tickets.seats (event_id, sector, row, seat)
                        VALUES (event_id, sector, row_num, seat_num)
                        RETURNING seat_id INTO external_id;

                        INSERT INTO availability.resources(external_id, is_available, last_changed, owner, external_system)
                        VALUES (external_id, TRUE, NOW(), 'tickets', 'tickets');
                    END LOOP;
            END LOOP;

        -- Event 3, 15000 seats in sector 'A'
        event_id := 3;
        sector := 'A';
        FOR row_num IN 1..150
            LOOP
                FOR seat_num IN 1..100
                    LOOP
                        INSERT INTO tickets.seats (event_id, sector, row, seat)
                        VALUES (event_id, sector, row_num, seat_num)
                        RETURNING seat_id INTO external_id;

                        INSERT INTO availability.resources(external_id, is_available, last_changed, owner, external_system)
                        VALUES (external_id, TRUE, NOW(), 'tickets', 'tickets');
                    END LOOP;
            END LOOP;
    END
$$;

-- ФИО: Федотов Александр Максимович

-- Проект 1
-- Вариант: 1
-- Условие: система описания чемпионата Формулы‑1 (календарь, гонщики, команды, результаты).

-- Проект 2
-- Вариант: 1
-- Условие: Формула‑1, задачи: 1) победители с <26 очков; 2) сумма очков по гонщикам.


-- 1. Справочник стран
CREATE TABLE countries (
    id          serial PRIMARY KEY,
    name        varchar(128) NOT NULL UNIQUE,      
    code        varchar(3) UNIQUE                  
);

-- 2. Сезоны 

CREATE TABLE seasons (
    id          serial PRIMARY KEY,
    year        integer NOT NULL UNIQUE CHECK (year >= 1950)  
);

-- 3. Этапы чемпионата 

CREATE TABLE grand_prix (
    id              serial PRIMARY KEY,
    season_id       integer NOT NULL REFERENCES seasons(id) ON DELETE RESTRICT,
    name            varchar(128) NOT NULL,     
    round_number    integer NOT NULL CHECK (round_number > 0), 
    race_date       date NOT NULL,            
    country_id      integer NOT NULL REFERENCES countries(id) ON DELETE RESTRICT,
    location        varchar(128) NOT NULL,    

    CONSTRAINT uq_season_country UNIQUE (season_id, country_id),

    CONSTRAINT uq_season_round UNIQUE (season_id, round_number)
);

-- 4. Гонщики

CREATE TABLE drivers (
    id              serial PRIMARY KEY,
    last_name       varchar(64)  NOT NULL,
    first_name      varchar(64)  NOT NULL,
    birth_date      date         NOT NULL,
    country_id      integer      NOT NULL REFERENCES countries(id) ON DELETE RESTRICT,
    wins_count      integer      NOT NULL DEFAULT 0 CHECK (wins_count >= 0)  
);

-- 5. Команды

CREATE TABLE teams (
    id                  serial PRIMARY KEY,
    name                varchar(128) NOT NULL UNIQUE,  
    engine_manufacturer varchar(128) NOT NULL,         
    country_id          integer NOT NULL REFERENCES countries(id) ON DELETE RESTRICT 
);


-- 6. Составы команд на конкретном гран‑при

CREATE TABLE team_entries (
    id                  serial PRIMARY KEY,
    team_id             integer NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    grand_prix_id       integer NOT NULL REFERENCES grand_prix(id) ON DELETE CASCADE,

    main_driver1_id     integer NOT NULL REFERENCES drivers(id) ON DELETE RESTRICT,
    car_number1         integer NOT NULL CHECK (car_number1 > 0),

    main_driver2_id     integer NOT NULL REFERENCES drivers(id) ON DELETE RESTRICT,
    car_number2         integer NOT NULL CHECK (car_number2 > 0),

    reserve_driver_id   integer REFERENCES drivers(id) ON DELETE RESTRICT,

    CONSTRAINT uq_team_gp UNIQUE (team_id, grand_prix_id),

    CONSTRAINT chk_team_entries_drivers_distinct
        CHECK (
            main_driver1_id <> main_driver2_id AND
            (reserve_driver_id IS NULL
             OR (reserve_driver_id <> main_driver1_id AND reserve_driver_id <> main_driver2_id))
        ),

    CONSTRAINT chk_team_entries_cars_distinct
        CHECK (car_number1 <> car_number2)
);

-- 7. Результаты гонок

CREATE TABLE race_results (
    id                  serial PRIMARY KEY,
    grand_prix_id       integer NOT NULL REFERENCES grand_prix(id) ON DELETE CASCADE,
    driver_id           integer NOT NULL REFERENCES drivers(id) ON DELETE RESTRICT,

    team_id             integer REFERENCES teams(id) ON DELETE RESTRICT,
    car_number          integer CHECK (car_number > 0),

    finish_position     integer CHECK (finish_position > 0),    
    points              numeric(4,1) NOT NULL DEFAULT 0 CHECK (points >= 0), 
    race_time           interval,       
    retire_reason       varchar(256),    
    lead_laps           integer NOT NULL DEFAULT 0 CHECK (lead_laps >= 0), 

    CONSTRAINT uq_result_gp_driver UNIQUE (grand_prix_id, driver_id),

    CONSTRAINT chk_race_results_time_or_retire
        CHECK (
            (race_time IS NOT NULL AND retire_reason IS NULL)
            OR
            (race_time IS NULL AND retire_reason IS NOT NULL)
        )
);


INSERT INTO countries (name, code) VALUES
('United Kingdom', 'GBR'),
('Italy',          'ITA'),
('Spain',          'ESP'),
('Netherlands',    'NED'),
('Germany',        'GER');


INSERT INTO seasons (year) VALUES
(2023),
(2024);


INSERT INTO grand_prix (season_id, name, round_number, race_date, country_id, location) VALUES
(
  (SELECT id FROM seasons WHERE year = 2024),
  'Australian Grand Prix', 1, DATE '2024-03-17',
  (SELECT id FROM countries WHERE name = 'Australia'),
  'Melbourne'
),
(
  (SELECT id FROM seasons WHERE year = 2024),
  'British Grand Prix', 2, DATE '2024-07-07',
  (SELECT id FROM countries WHERE name = 'United Kingdom'),
  'Silverstone'
),
(
  (SELECT id FROM seasons WHERE year = 2024),
  'Italian Grand Prix', 3, DATE '2024-09-08',
  (SELECT id FROM countries WHERE name = 'Italy'),
  'Monza'
),
(
  (SELECT id FROM seasons WHERE year = 2024),
  'Spanish Grand Prix', 4, DATE '2024-06-02',
  (SELECT id FROM countries WHERE name = 'Spain'),
  'Barcelona'
);


INSERT INTO drivers (last_name, first_name, birth_date, country_id, wins_count) VALUES
('Verstappen', 'Max',    DATE '1997-09-30', (SELECT id FROM countries WHERE name = 'Netherlands'), 0),
('Hamilton',   'Lewis',  DATE '1985-01-07', (SELECT id FROM countries WHERE name = 'United Kingdom'), 0),
('Leclerc',    'Charles',DATE '1997-10-16', (SELECT id FROM countries WHERE name = 'Italy'), 0),
('Russell',    'George', DATE '1998-02-15', (SELECT id FROM countries WHERE name = 'United Kingdom'), 0),
('Vettel',     'Sebastian',DATE '1987-07-03',(SELECT id FROM countries WHERE name = 'Germany'), 0);


INSERT INTO teams (name, engine_manufacturer, country_id) VALUES
('Red Bull Racing', 'Honda',    (SELECT id FROM countries WHERE name = 'United Kingdom')),
('Mercedes',        'Mercedes', (SELECT id FROM countries WHERE name = 'Germany')),
('Ferrari',         'Ferrari',  (SELECT id FROM countries WHERE name = 'Italy'));


-- Для Australian Grand Prix
INSERT INTO team_entries (
    team_id, grand_prix_id,
    main_driver1_id, car_number1,
    main_driver2_id, car_number2,
    reserve_driver_id
)
VALUES
(
  (SELECT id FROM teams WHERE name = 'Red Bull Racing'),
  (SELECT id FROM grand_prix WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Verstappen'),
  1,
  (SELECT id FROM drivers WHERE last_name = 'Russell'),
  63,
  (SELECT id FROM drivers WHERE last_name = 'Vettel')
),
(
  (SELECT id FROM teams WHERE name = 'Mercedes'),
  (SELECT id FROM grand_prix WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Hamilton'),
  44,
  (SELECT id FROM drivers WHERE last_name = 'Leclerc'),
  16,
  NULL
);

-- Для British Grand Prix
INSERT INTO team_entries (
    team_id, grand_prix_id,
    main_driver1_id, car_number1,
    main_driver2_id, car_number2,
    reserve_driver_id
)
VALUES
(
  (SELECT id FROM teams WHERE name = 'Red Bull Racing'),
  (SELECT id FROM grand_prix WHERE name = 'British Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Verstappen'),
  1,
  (SELECT id FROM drivers WHERE last_name = 'Russell'),
  63,
  NULL
),
(
  (SELECT id FROM teams WHERE name = 'Mercedes'),
  (SELECT id FROM grand_prix WHERE name = 'British Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Hamilton'),
  44,
  (SELECT id FROM drivers WHERE last_name = 'Leclerc'),
  16,
  (SELECT id FROM drivers WHERE last_name = 'Vettel')
);


-- Australian Grand Prix
INSERT INTO race_results (
    grand_prix_id, driver_id, team_id, car_number,
    finish_position, points, race_time, retire_reason, lead_laps
)
VALUES
(
  (SELECT id FROM grand_prix WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Verstappen'),
  (SELECT id FROM teams   WHERE name = 'Red Bull Racing'),
  1,
  1, 25, INTERVAL '1:25:00', NULL, 30
),
(
  (SELECT id FROM grand_prix WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Hamilton'),
  (SELECT id FROM teams   WHERE name = 'Mercedes'),
  44,
  2, 18, INTERVAL '1:25:10', NULL, 10
),
(
  (SELECT id FROM grand_prix WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Leclerc'),
  (SELECT id FROM teams   WHERE name = 'Ferrari'),
  16,
  3, 15, INTERVAL '1:25:20', NULL, 5
),
(
  (SELECT id FROM grand_prix WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Russell'),
  (SELECT id FROM teams   WHERE name = 'Red Bull Racing'),
  63,
  4, 0,  NULL, 'DNF - engine', 0
);

-- British Grand Prix
INSERT INTO race_results (
    grand_prix_id, driver_id, team_id, car_number,
    finish_position, points, race_time, retire_reason, lead_laps
)
VALUES
(
  (SELECT id FROM grand_prix WHERE name = 'British Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Hamilton'),
  (SELECT id FROM teams   WHERE name = 'Mercedes'),
  44,
  1, 25, INTERVAL '1:30:00', NULL, 20
),
(
  (SELECT id FROM grand_prix WHERE name = 'British Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Verstappen'),
  (SELECT id FROM teams   WHERE name = 'Red Bull Racing'),
  1,
  2, 18, INTERVAL '1:30:05', NULL, 10
),
(
  (SELECT id FROM grand_prix WHERE name = 'British Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Russell'),
  (SELECT id FROM teams   WHERE name = 'Red Bull Racing'),
  63,
  3, 15, INTERVAL '1:30:15', NULL, 3
),
(
  (SELECT id FROM grand_prix WHERE name = 'British Grand Prix'),
  (SELECT id FROM drivers WHERE last_name = 'Leclerc'),
  (SELECT id FROM teams   WHERE name = 'Ferrari'),
  16,
  4, 0, NULL, 'DNF - accident', 0
);


-- Задача 1: гонщики, которые заняли 1 место и набрали меньше 26 очков,
-- сортировка по убыванию кругов лидирования
SELECT
    rr.driver_id,
    d.first_name,
    d.last_name,
    rr.points,
    rr.lead_laps
FROM race_results rr
JOIN drivers d ON d.id = rr.driver_id
WHERE rr.finish_position = 1
  AND rr.points < 26
ORDER BY rr.lead_laps DESC;

-- Задача 2: имена и фамилии гонщиков и общее количество их очков, по убыванию
SELECT
    d.first_name,
    d.last_name,
    SUM(rr.points) AS total_points
FROM drivers d
JOIN race_results rr ON rr.driver_id = d.id
GROUP BY d.id, d.first_name, d.last_name
ORDER BY total_points DESC;


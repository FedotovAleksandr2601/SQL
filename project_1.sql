-- ФИО: Федотов Александр Максимович
-- Вариант: 1
-- Условие: система описания чемпионата Формулы‑1 (календарь, гонщики, команды, результаты).
-- БД: PostgreSQL

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


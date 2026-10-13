/* =========================================================
   PRY2204 - EFT SEMANA 9 - ANFP
   ========================================================= */

/* ---------- LIMPIEZA (permite re-ejecutar el script) ---------- */
BEGIN
    FOR t IN (SELECT table_name FROM user_tables) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
    FOR s IN (SELECT sequence_name FROM user_sequences
              WHERE sequence_name NOT LIKE 'ISEQ$$%') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

/* =========================================================
   FASE 3: CREACION DE TABLAS
   ========================================================= */

-- Tablas sin claves foraneas
CREATE TABLE region (
    id_region  NUMBER(2),
    nombre     VARCHAR2(50) NOT NULL,
    CONSTRAINT region_pk PRIMARY KEY (id_region)
);

CREATE TABLE nacionalidad (
    id_nacion    NUMBER(4) GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 2),
    descripcion  VARCHAR2(30) NOT NULL,
    CONSTRAINT nacionalidad_pk PRIMARY KEY (id_nacion)
);

CREATE TABLE asociacion (
    id_asociacion      NUMBER(3),
    nombre_asociacion  VARCHAR2(60) NOT NULL,
    fecha_creacion     DATE NOT NULL,
    tipo_asociacion    CHAR(1) DEFAULT 'P' NOT NULL,
    CONSTRAINT asociacion_pk PRIMARY KEY (id_asociacion)
);

CREATE TABLE club_futbol (
    id_club          NUMBER(4),
    nombre_club      VARCHAR2(50) NOT NULL,
    patrimonio       NUMBER(12) NOT NULL,
    ubicacion_calle  VARCHAR2(60) NOT NULL,
    tipo_club        VARCHAR2(15) DEFAULT 'Profesional' NOT NULL,
    CONSTRAINT club_futbol_pk PRIMARY KEY (id_club)
);

CREATE TABLE escuela_futbol (
    id_escuela       NUMBER(5),
    nombre_escuela   VARCHAR2(50) NOT NULL,
    capacidad        NUMBER(5) NOT NULL,
    fecha_fundacion  DATE NOT NULL,
    CONSTRAINT escuela_futbol_pk PRIMARY KEY (id_escuela)
);

CREATE TABLE genero (
    id_genero    CHAR(1),
    descripcion  VARCHAR2(15) NOT NULL,
    CONSTRAINT genero_pk PRIMARY KEY (id_genero)
);

CREATE TABLE estado_civil (
    id_estado_civil  NUMBER(2),
    descripcion      VARCHAR2(20) NOT NULL,
    CONSTRAINT estado_civil_pk PRIMARY KEY (id_estado_civil)
);

CREATE TABLE puesto (
    id_puesto    NUMBER(2),
    descripcion  VARCHAR2(30) NOT NULL,
    CONSTRAINT puesto_pk PRIMARY KEY (id_puesto)
);

CREATE TABLE idioma (
    id_idioma      NUMBER(3),
    nombre_idioma  VARCHAR2(30) NOT NULL,
    CONSTRAINT idioma_pk PRIMARY KEY (id_idioma)
);

-- Tablas con claves foraneas
CREATE TABLE comuna (
    id_comuna  NUMBER(4),
    id_region  NUMBER(2) NOT NULL,
    nombre     VARCHAR2(50) NOT NULL,
    CONSTRAINT comuna_pk PRIMARY KEY (id_comuna),
    CONSTRAINT comuna_fk_region FOREIGN KEY (id_region) REFERENCES region (id_region)
);

CREATE TABLE trabajador (
    cod_inscripcion   NUMBER(9),
    rut               NUMBER(8) NOT NULL,
    dv                CHAR(1) NOT NULL,
    pnombre           VARCHAR2(25) NOT NULL,
    snombre           VARCHAR2(25),
    apaterno          VARCHAR2(25) NOT NULL,
    amaterno          VARCHAR2(25),
    sueldo_base       NUMBER(10) NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    telefono_movil    VARCHAR2(15),
    email             VARCHAR2(60),
    direccion         VARCHAR2(80) NOT NULL,
    id_comuna         NUMBER(4) NOT NULL,
    id_genero         CHAR(1) NOT NULL,
    id_estado_civil   NUMBER(2) NOT NULL,
    id_nacion         NUMBER(4) NOT NULL,
    tipo_trabajador   CHAR(1) NOT NULL,
    CONSTRAINT trabajador_pk PRIMARY KEY (cod_inscripcion),
    CONSTRAINT trabajador_fk_comuna FOREIGN KEY (id_comuna) REFERENCES comuna (id_comuna),
    CONSTRAINT trabajador_fk_genero FOREIGN KEY (id_genero) REFERENCES genero (id_genero),
    CONSTRAINT trabajador_fk_estado_civil FOREIGN KEY (id_estado_civil) REFERENCES estado_civil (id_estado_civil),
    CONSTRAINT trabajador_fk_nacionalidad FOREIGN KEY (id_nacion) REFERENCES nacionalidad (id_nacion)
);

CREATE TABLE jugador (
    cod_inscripcion  NUMBER(9),
    id_puesto        NUMBER(2) NOT NULL,
    monto_premios    NUMBER(12) DEFAULT 0 NOT NULL,
    id_asociacion    NUMBER(3) NOT NULL,
    id_escuela       NUMBER(5),
    anio_egreso      NUMBER(4),
    CONSTRAINT jugador_pk PRIMARY KEY (cod_inscripcion),
    CONSTRAINT jugador_fk_trabajador FOREIGN KEY (cod_inscripcion) REFERENCES trabajador (cod_inscripcion),
    CONSTRAINT jugador_fk_puesto FOREIGN KEY (id_puesto) REFERENCES puesto (id_puesto),
    CONSTRAINT jugador_fk_asociacion FOREIGN KEY (id_asociacion) REFERENCES asociacion (id_asociacion),
    CONSTRAINT jugador_fk_escuela FOREIGN KEY (id_escuela) REFERENCES escuela_futbol (id_escuela)
);

CREATE TABLE personal_planta (
    cod_inscripcion   NUMBER(9),
    id_club           NUMBER(4) NOT NULL,
    horas_trabajadas  NUMBER(4),
    valor_hora_extra  NUMBER(8),
    CONSTRAINT personal_planta_pk PRIMARY KEY (cod_inscripcion),
    CONSTRAINT personal_planta_fk_trabajador FOREIGN KEY (cod_inscripcion) REFERENCES trabajador (cod_inscripcion),
    CONSTRAINT personal_planta_fk_club FOREIGN KEY (id_club) REFERENCES club_futbol (id_club)
);

CREATE TABLE jugador_club (
    cod_inscripcion      NUMBER(9),
    id_club              NUMBER(4),
    fecha_incorporacion  DATE,
    fecha_fin_contrato   DATE,
    CONSTRAINT jugador_club_pk PRIMARY KEY (cod_inscripcion, id_club, fecha_incorporacion),
    CONSTRAINT jugador_club_fk_jugador FOREIGN KEY (cod_inscripcion) REFERENCES jugador (cod_inscripcion),
    CONSTRAINT jugador_club_fk_club FOREIGN KEY (id_club) REFERENCES club_futbol (id_club)
);

CREATE TABLE jugador_idioma (
    cod_inscripcion  NUMBER(9),
    id_idioma        NUMBER(3),
    nivel_dominio    VARCHAR2(15) NOT NULL,
    CONSTRAINT jugador_idioma_pk PRIMARY KEY (cod_inscripcion, id_idioma),
    CONSTRAINT jugador_idioma_fk_jugador FOREIGN KEY (cod_inscripcion) REFERENCES jugador (cod_inscripcion),
    CONSTRAINT jugador_idioma_fk_idioma FOREIGN KEY (id_idioma) REFERENCES idioma (id_idioma)
);

-- Secuencia para el codigo de CLUB_FUTBOL
CREATE SEQUENCE seq_club START WITH 703 INCREMENT BY 4;

/* =========================================================
   FASE 3: MODIFICACIONES DEL MODELO FISICO (UN / CK)
   ========================================================= */

-- El nombre del club debe ser unico
ALTER TABLE club_futbol
    ADD CONSTRAINT club_futbol_un_nombre UNIQUE (nombre_club);

-- Tipo de club valido
ALTER TABLE club_futbol
    ADD CONSTRAINT club_futbol_ck_tipo CHECK (tipo_club IN ('Profesional','Amateur'));

-- Patrimonio no negativo
ALTER TABLE club_futbol
    ADD CONSTRAINT club_futbol_ck_patrimonio CHECK (patrimonio >= 0);

-- Fecha de creacion de la asociacion igual o posterior al 31/12/1980
ALTER TABLE asociacion
    ADD CONSTRAINT asociacion_ck_fecha CHECK (fecha_creacion >= DATE '1980-12-31');

-- Tipo de asociacion: Profesional (P) o Amateur (A)
ALTER TABLE asociacion
    ADD CONSTRAINT asociacion_ck_tipo CHECK (tipo_asociacion IN ('P','A'));

-- RUT unico y digito verificador valido
ALTER TABLE trabajador
    ADD CONSTRAINT trabajador_un_rut UNIQUE (rut);

ALTER TABLE trabajador
    ADD CONSTRAINT trabajador_ck_dv CHECK (dv IN ('0','1','2','3','4','5','6','7','8','9','K'));

-- Email opcional pero unico
ALTER TABLE trabajador
    ADD CONSTRAINT trabajador_un_email UNIQUE (email);

-- Sueldo base positivo
ALTER TABLE trabajador
    ADD CONSTRAINT trabajador_ck_sueldo CHECK (sueldo_base > 0);

-- Tipo de trabajador: Jugador (J) o Personal de planta (P)
ALTER TABLE trabajador
    ADD CONSTRAINT trabajador_ck_tipo CHECK (tipo_trabajador IN ('J','P'));

-- Premios no negativos
ALTER TABLE jugador
    ADD CONSTRAINT jugador_ck_premios CHECK (monto_premios >= 0);

-- Nivel de dominio de idioma valido
ALTER TABLE jugador_idioma
    ADD CONSTRAINT jugador_idioma_ck_nivel CHECK (nivel_dominio IN ('Basico','Intermedio','Avanzado','Nativo'));

-- Fin de contrato posterior a la incorporacion
ALTER TABLE jugador_club
    ADD CONSTRAINT jugador_club_ck_fechas CHECK (fecha_fin_contrato > fecha_incorporacion);
    
    /* =========================================================
   FASE 3: POBLAMIENTO DE TABLAS
   ========================================================= */

-- REGION (se agregan 8 y 16 porque COMUNA las referencia)
INSERT INTO region VALUES (1, 'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO region VALUES (2, 'ANTOFAGASTA');
INSERT INTO region VALUES (3, 'ATACAMA Y COQUIMBO');
INSERT INTO region VALUES (5, 'VALPARAISO');
INSERT INTO region VALUES (8, 'BIOBIO');
INSERT INTO region VALUES (13, 'METROPOLITANA');
INSERT INTO region VALUES (16, 'ÑUBLE');

-- COMUNA
INSERT INTO comuna VALUES (101, 13, 'Santiago');
INSERT INTO comuna VALUES (102, 5, 'Valparaíso');
INSERT INTO comuna VALUES (103, 8, 'Concepción');
INSERT INTO comuna VALUES (104, 2, 'Antofagasta');
INSERT INTO comuna VALUES (105, 16, 'Chillán');

-- ASOCIACION
INSERT INTO asociacion VALUES (25, 'Asociación de Fútbol de Santiago', TO_DATE('15-05-2001','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (26, 'Asociación Nacional de Fútbol Amateur', TO_DATE('10-03-1998','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (27, 'Asociación de Fútbol de Valparaíso', TO_DATE('21-07-1987','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (28, 'Asociación de Fútbol de Concepción', TO_DATE('30-11-1995','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (29, 'Asociación de Fútbol de Antofagasta', TO_DATE('25-06-2003','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (30, 'Asociación de Fútbol de Temuco', TO_DATE('12-01-2010','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (31, 'Asociación de Fútbol de Rancagua', TO_DATE('08-09-1999','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (32, 'Asociación de Fútbol de Puerto Montt', TO_DATE('20-04-2005','DD-MM-YYYY'), 'A');
INSERT INTO asociacion VALUES (33, 'Asociación de Fútbol de La Serena', TO_DATE('14-08-2012','DD-MM-YYYY'), 'P');
INSERT INTO asociacion VALUES (34, 'Asociación de Fútbol de Chillán', TO_DATE('01-12-2018','DD-MM-YYYY'), 'A');

-- NACIONALIDAD (identity: 210, 212, 214, 216, 218)
INSERT INTO nacionalidad (descripcion) VALUES ('Chilena');
INSERT INTO nacionalidad (descripcion) VALUES ('Argentina');
INSERT INTO nacionalidad (descripcion) VALUES ('Peruana');
INSERT INTO nacionalidad (descripcion) VALUES ('Boliviana');
INSERT INTO nacionalidad (descripcion) VALUES ('Brasileña');

-- CLUB_FUTBOL (secuencia: 703, 707, 711, 715, 719)
INSERT INTO club_futbol VALUES (seq_club.NEXTVAL, 'Colo-Colo', 500000000, 'Av. Marathon 5300', 'Profesional');
INSERT INTO club_futbol VALUES (seq_club.NEXTVAL, 'Universidad de Chile', 450000000, 'Av. El Parrón 0931', 'Profesional');
INSERT INTO club_futbol VALUES (seq_club.NEXTVAL, 'Deportes Antofagasta', 180000000, 'Avenida Angamos 01606', 'Profesional');
INSERT INTO club_futbol VALUES (seq_club.NEXTVAL, 'Huachipato', 220000000, 'Avenida Desiderio García 909', 'Profesional');
INSERT INTO club_futbol VALUES (seq_club.NEXTVAL, 'Ñublense', 170000000, 'Avenida Pedro Aguirre Cerda 1003', 'Profesional');

COMMIT;

/* =========================================================
   FASE 4: RECUPERACION DE DATOS
   ========================================================= */

-- INFORME 1: Asociaciones de futbol profesional creadas despues del 2000
SELECT 'ID:' || id_asociacion || ' * ' || nombre_asociacion  AS "ASOCIACION",
       TO_CHAR(fecha_creacion, 'DD-MM-YYYY')                 AS "CREADA",
       tipo_asociacion                                       AS "TIPO"
FROM asociacion
WHERE tipo_asociacion = 'P'
  AND EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER BY fecha_creacion DESC;

-- INFORME 2: Patrimonio de clubes en pesos y dolares (USD = $955)
SELECT id_club              AS "CLUB",
       nombre_club          AS "NOMBRE CLUB",
       patrimonio           AS "PATRIMONIO EN PESOS",
       patrimonio / 955     AS "PATRIMONIO EN DOLARES"
FROM club_futbol
WHERE nombre_club LIKE '%a%'
  AND patrimonio > 200000000
  AND tipo_club = 'Profesional'
ORDER BY id_club DESC;
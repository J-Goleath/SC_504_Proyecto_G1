-- ============================================================
-- PROYECTO FINAL SC-504
-- SISTEMA DE GESTION DE ESPACIOS DE COWORKING
-- BASE DE DATOS: COWORKINGDB
-- ============================================================

-- ============================================================
-- BLOQUE 1. LIMPIEZA DE OBJETOS
-- ============================================================
BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_salas_reporte'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_usuarios_reporte'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_servicios_reserva'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW vw_reporte_reservas'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_reportes'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_funciones'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_pagos'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_reservas'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_usuarios'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_validaciones'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE pkg_catalogos'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION fn_total_reserva'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE bitacora_cambios CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE pagos CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE reserva_servicios CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE servicios CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE reservas CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE estados CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE salas CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tipo_sala CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE usuarios CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE roles CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE piso CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE edificio CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- BLOQUE 2. TABLAS PRINCIPALES
-- ============================================================

CREATE TABLE edificio (
    id_edificio       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_edificio   VARCHAR2(100) NOT NULL,
    direccion         VARCHAR2(255) NOT NULL,
    CONSTRAINT ck_edificio_nombre
        CHECK (REGEXP_LIKE(nombre_edificio, '^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9 ]{2,100}$'))
);
/

CREATE TABLE piso (
    id_piso           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_piso       NUMBER(2) NOT NULL,
    id_edificio       NUMBER NOT NULL,
    CONSTRAINT ck_piso_numero CHECK (numero_piso BETWEEN 0 AND 99),
    CONSTRAINT fk_piso_edificio
        FOREIGN KEY (id_edificio) REFERENCES edificio(id_edificio) ON DELETE CASCADE,
    CONSTRAINT uq_piso_edificio UNIQUE (numero_piso, id_edificio)
);
/

CREATE TABLE roles (
    id_rol            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descripcion_rol   VARCHAR2(50) NOT NULL,
    CONSTRAINT uq_roles_descripcion UNIQUE (descripcion_rol),
    CONSTRAINT ck_roles_descripcion
        CHECK (REGEXP_LIKE(descripcion_rol, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,50}$'))
);
/

CREATE TABLE usuarios (
    id_usuario        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre            VARCHAR2(50) NOT NULL,
    apellido_1        VARCHAR2(50) NOT NULL,
    apellido_2        VARCHAR2(50),
    correo            VARCHAR2(100) NOT NULL,
    telefono          VARCHAR2(20) NOT NULL,
    codigo_pais       VARCHAR2(5) DEFAULT 'CR' NOT NULL,
    contrasena_hash   VARCHAR2(255) NOT NULL,
    id_rol            NUMBER NOT NULL,
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES roles(id_rol),
    CONSTRAINT uq_usuario_correo UNIQUE (correo),
    CONSTRAINT uq_usuario_tel_pais UNIQUE (telefono, codigo_pais),
    CONSTRAINT ck_usuario_nombre
        CHECK (REGEXP_LIKE(nombre, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,50}$')),
    CONSTRAINT ck_usuario_apellido1
        CHECK (REGEXP_LIKE(apellido_1, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,50}$')),
    CONSTRAINT ck_usuario_apellido2
        CHECK (apellido_2 IS NULL OR REGEXP_LIKE(apellido_2, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,50}$')),
    CONSTRAINT ck_usuario_correo
        CHECK (REGEXP_LIKE(correo, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$')),
    CONSTRAINT ck_usuario_codigo_pais
        CHECK (codigo_pais = 'CR'),
    CONSTRAINT ck_usuario_telefono
        CHECK (REGEXP_LIKE(telefono, '^[0-9]{8}$')),
    CONSTRAINT ck_usuario_contrasena
        CHECK (
            LENGTH(contrasena_hash) BETWEEN 8 AND 15
            AND REGEXP_LIKE(contrasena_hash, '[A-Z]')
            AND REGEXP_LIKE(contrasena_hash, '[a-z]')
            AND REGEXP_LIKE(contrasena_hash, '[0-9]')
            AND REGEXP_LIKE(contrasena_hash, '[^A-Za-z0-9]')
        )
);
/

CREATE TABLE tipo_sala (
    id_tipo           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descripcion_tipo  VARCHAR2(50) NOT NULL,
    CONSTRAINT uq_tipo_sala_descripcion UNIQUE (descripcion_tipo),
    CONSTRAINT ck_tipo_sala_descripcion
        CHECK (REGEXP_LIKE(descripcion_tipo, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,50}$'))
);
/

CREATE TABLE salas (
    id_sala           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_sala       VARCHAR2(100) NOT NULL,
    capacidad         NUMBER(3) NOT NULL,
    precio_hora       NUMBER(8,2) NOT NULL,
    id_tipo           NUMBER NOT NULL,
    id_piso           NUMBER NOT NULL,
    CONSTRAINT uq_salas_nombre UNIQUE (nombre_sala),
    CONSTRAINT ck_salas_capacidad CHECK (capacidad BETWEEN 1 AND 100),
    CONSTRAINT ck_salas_precio CHECK (precio_hora BETWEEN 1000 AND 500000),
    CONSTRAINT fk_salas_tipo FOREIGN KEY (id_tipo) REFERENCES tipo_sala(id_tipo),
    CONSTRAINT fk_salas_piso FOREIGN KEY (id_piso) REFERENCES piso(id_piso)
);
/

CREATE TABLE estados (
    id_estado         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_estado     VARCHAR2(50) NOT NULL,
    CONSTRAINT uq_estados_nombre UNIQUE (nombre_estado),
    CONSTRAINT ck_estados_nombre
        CHECK (REGEXP_LIKE(nombre_estado, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,50}$'))
);
/

CREATE TABLE reservas (
    id_reserva        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario        NUMBER NOT NULL,
    id_sala           NUMBER NOT NULL,
    id_estado         NUMBER NOT NULL,
    fecha             DATE NOT NULL,
    hora_inicio       TIMESTAMP NOT NULL,
    hora_fin          TIMESTAMP NOT NULL,
    costo_total       NUMBER(10,2),
    CONSTRAINT fk_reservas_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_reservas_sala FOREIGN KEY (id_sala) REFERENCES salas(id_sala),
    CONSTRAINT fk_reservas_estado FOREIGN KEY (id_estado) REFERENCES estados(id_estado),
    CONSTRAINT ck_reservas_horas CHECK (hora_fin > hora_inicio),
    CONSTRAINT ck_reservas_fecha_inicio CHECK (TRUNC(hora_inicio) = fecha),
    CONSTRAINT ck_reservas_fecha_fin CHECK (TRUNC(hora_fin) = fecha)
);
/

CREATE TABLE servicios (
    id_servicio       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_servicio   VARCHAR2(100) NOT NULL,
    precio_adicional  NUMBER(8,2) NOT NULL,
    CONSTRAINT uq_servicios_nombre UNIQUE (nombre_servicio),
    CONSTRAINT ck_servicios_precio CHECK (precio_adicional BETWEEN 0 AND 100000),
    CONSTRAINT ck_servicios_nombre
        CHECK (REGEXP_LIKE(nombre_servicio, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,100}$'))
);
/

CREATE TABLE reserva_servicios (
    id_reserva        NUMBER NOT NULL,
    id_servicio       NUMBER NOT NULL,
    cantidad          NUMBER(2) DEFAULT 1 NOT NULL,
    CONSTRAINT pk_reserva_servicios PRIMARY KEY (id_reserva, id_servicio),
    CONSTRAINT fk_rs_reserva FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva),
    CONSTRAINT fk_rs_servicio FOREIGN KEY (id_servicio) REFERENCES servicios(id_servicio),
    CONSTRAINT ck_rs_cantidad CHECK (cantidad BETWEEN 1 AND 20)
);
/

CREATE TABLE pagos (
    id_pago                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reserva             NUMBER NOT NULL,
    monto_total            NUMBER(10,2) NOT NULL,
    fecha_pago             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metodo_pago            VARCHAR2(50) NOT NULL,
    estado_pago            VARCHAR2(20) DEFAULT 'Pendiente' NOT NULL,
    referencia_transaccion VARCHAR2(100),
    registrado_por         NUMBER,
    CONSTRAINT fk_pagos_reserva FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva),
    CONSTRAINT fk_pagos_usuario FOREIGN KEY (registrado_por) REFERENCES usuarios(id_usuario),
    CONSTRAINT uq_pagos_reserva UNIQUE (id_reserva),
    CONSTRAINT uq_pagos_referencia UNIQUE (referencia_transaccion),
    CONSTRAINT ck_pagos_monto CHECK (monto_total BETWEEN 0 AND 99999999.99),
    CONSTRAINT ck_pagos_metodo
        CHECK (REGEXP_LIKE(metodo_pago, '^(Tarjeta|SINPE|Transferencia|Efectivo)$')),
    CONSTRAINT ck_pagos_estado
        CHECK (estado_pago IN ('Pendiente', 'Pagado', 'Rechazado', 'Reembolsado'))
);
/

CREATE TABLE bitacora_cambios (
    id_log              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reserva          NUMBER NOT NULL,
    id_estado_anterior  NUMBER,
    id_estado_nuevo     NUMBER,
    fecha_cambio        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bitacora_reserva FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva)
);
/

-- ============================================================
-- BLOQUE 3. PAQUETE DE VALIDACIONES
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_validaciones AS
    FUNCTION fn_correo_valido(p_correo IN VARCHAR2) RETURN NUMBER;
    FUNCTION fn_nombre_valido(p_texto IN VARCHAR2) RETURN NUMBER;
    FUNCTION fn_telefono_valido(p_telefono IN VARCHAR2, p_codigo_pais IN VARCHAR2) RETURN NUMBER;
END pkg_validaciones;
/

CREATE OR REPLACE PACKAGE BODY pkg_validaciones AS
    FUNCTION fn_correo_valido(p_correo IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF REGEXP_LIKE(p_correo, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$') THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END fn_correo_valido;

    FUNCTION fn_nombre_valido(p_texto IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF REGEXP_LIKE(p_texto, '^[A-Za-zÁÉÍÓÚáéíóúÑñ ]{2,100}$') THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END fn_nombre_valido;

    FUNCTION fn_telefono_valido(p_telefono IN VARCHAR2, p_codigo_pais IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF p_codigo_pais = 'CR' AND REGEXP_LIKE(p_telefono, '^[0-9]{8}$') THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END fn_telefono_valido;
END pkg_validaciones;
/

-- ============================================================
-- BLOQUE 4. FUNCION DE TOTAL DE RESERVA
-- ============================================================
CREATE OR REPLACE FUNCTION fn_total_reserva(p_id_reserva IN NUMBER)
RETURN NUMBER
IS
    v_costo_reserva    NUMBER(10,2) := 0;
    v_costo_servicios  NUMBER(10,2) := 0;
BEGIN
    BEGIN
        SELECT costo_total
          INTO v_costo_reserva
          FROM reservas
         WHERE id_reserva = p_id_reserva;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END;

    SELECT NVL(SUM(rs.cantidad * s.precio_adicional), 0)
      INTO v_costo_servicios
      FROM reserva_servicios rs
      JOIN servicios s
        ON rs.id_servicio = s.id_servicio
     WHERE rs.id_reserva = p_id_reserva;

    RETURN v_costo_reserva + v_costo_servicios;
END;
/

-- ============================================================
-- BLOQUE 5. TRIGGERS
-- ============================================================
CREATE OR REPLACE TRIGGER trg_usuarios_bi
BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
    :NEW.nombre := TRIM(:NEW.nombre);
    :NEW.apellido_1 := TRIM(:NEW.apellido_1);

    IF :NEW.apellido_2 IS NOT NULL THEN
        :NEW.apellido_2 := TRIM(:NEW.apellido_2);
    END IF;

    :NEW.correo := LOWER(TRIM(:NEW.correo));
    :NEW.telefono := TRIM(:NEW.telefono);
    :NEW.codigo_pais := UPPER(TRIM(:NEW.codigo_pais));

    IF pkg_validaciones.fn_nombre_valido(:NEW.nombre) = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Nombre invalido.');
    END IF;

    IF pkg_validaciones.fn_nombre_valido(:NEW.apellido_1) = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Primer apellido invalido.');
    END IF;

    IF :NEW.apellido_2 IS NOT NULL AND pkg_validaciones.fn_nombre_valido(:NEW.apellido_2) = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Segundo apellido invalido.');
    END IF;

    IF pkg_validaciones.fn_correo_valido(:NEW.correo) = 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Correo invalido.');
    END IF;

    IF :NEW.codigo_pais <> 'CR' THEN
        RAISE_APPLICATION_ERROR(-20014, 'Solo se permite Costa Rica.');
    END IF;

    IF LENGTH(:NEW.contrasena_hash) < 8
       OR LENGTH(:NEW.contrasena_hash) > 15
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[A-Z]')
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[a-z]')
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[0-9]')
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[^A-Za-z0-9]') THEN
        RAISE_APPLICATION_ERROR(-20015, 'La contrasena debe tener entre 8 y 15 caracteres, incluir mayuscula, minuscula, numero y simbolo.');
    END IF;

    IF pkg_validaciones.fn_telefono_valido(:NEW.telefono, :NEW.codigo_pais) = 0 THEN
        RAISE_APPLICATION_ERROR(-20016, 'Telefono invalido. Debe tener exactamente 8 numeros de Costa Rica.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_usuarios_bu
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    :NEW.nombre := TRIM(:NEW.nombre);
    :NEW.apellido_1 := TRIM(:NEW.apellido_1);

    IF :NEW.apellido_2 IS NOT NULL THEN
        :NEW.apellido_2 := TRIM(:NEW.apellido_2);
    END IF;

    :NEW.correo := LOWER(TRIM(:NEW.correo));
    :NEW.telefono := TRIM(:NEW.telefono);
    :NEW.codigo_pais := UPPER(TRIM(:NEW.codigo_pais));

    IF pkg_validaciones.fn_nombre_valido(:NEW.nombre) = 0 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Nombre invalido al actualizar.');
    END IF;

    IF pkg_validaciones.fn_nombre_valido(:NEW.apellido_1) = 0 THEN
        RAISE_APPLICATION_ERROR(-20018, 'Primer apellido invalido al actualizar.');
    END IF;

    IF :NEW.apellido_2 IS NOT NULL AND pkg_validaciones.fn_nombre_valido(:NEW.apellido_2) = 0 THEN
        RAISE_APPLICATION_ERROR(-20019, 'Segundo apellido invalido al actualizar.');
    END IF;

    IF pkg_validaciones.fn_correo_valido(:NEW.correo) = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Correo invalido al actualizar.');
    END IF;

    IF :NEW.codigo_pais <> 'CR' THEN
        RAISE_APPLICATION_ERROR(-20021, 'Solo se permite Costa Rica.');
    END IF;

    IF LENGTH(:NEW.contrasena_hash) < 8
       OR LENGTH(:NEW.contrasena_hash) > 15
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[A-Z]')
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[a-z]')
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[0-9]')
       OR NOT REGEXP_LIKE(:NEW.contrasena_hash, '[^A-Za-z0-9]') THEN
        RAISE_APPLICATION_ERROR(-20022, 'La contrasena debe tener entre 8 y 15 caracteres, incluir mayuscula, minuscula, numero y simbolo.');
    END IF;

    IF pkg_validaciones.fn_telefono_valido(:NEW.telefono, :NEW.codigo_pais) = 0 THEN
        RAISE_APPLICATION_ERROR(-20023, 'Telefono invalido al actualizar. Debe tener exactamente 8 numeros de Costa Rica.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_salas_bi
BEFORE INSERT ON salas
FOR EACH ROW
BEGIN
    IF :NEW.capacidad < 1 OR :NEW.capacidad > 100 THEN
        RAISE_APPLICATION_ERROR(-20024, 'La capacidad debe estar entre 1 y 100.');
    END IF;

    IF :NEW.precio_hora < 1000 OR :NEW.precio_hora > 500000 THEN
        RAISE_APPLICATION_ERROR(-20025, 'El precio por hora esta fuera del rango permitido.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_salas_bu
BEFORE UPDATE ON salas
FOR EACH ROW
BEGIN
    IF :NEW.capacidad < 1 OR :NEW.capacidad > 100 THEN
        RAISE_APPLICATION_ERROR(-20026, 'La capacidad actualizada esta fuera del rango permitido.');
    END IF;

    IF :NEW.precio_hora < 1000 OR :NEW.precio_hora > 500000 THEN
        RAISE_APPLICATION_ERROR(-20027, 'El precio actualizado esta fuera del rango permitido.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_servicios_bi
BEFORE INSERT ON servicios
FOR EACH ROW
BEGIN
    IF :NEW.precio_adicional < 0 OR :NEW.precio_adicional > 100000 THEN
        RAISE_APPLICATION_ERROR(-20028, 'El precio adicional esta fuera del rango permitido.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_servicios_bu
BEFORE UPDATE ON servicios
FOR EACH ROW
BEGIN
    IF :NEW.precio_adicional < 0 OR :NEW.precio_adicional > 100000 THEN
        RAISE_APPLICATION_ERROR(-20029, 'El precio adicional actualizado esta fuera del rango permitido.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pagos_validar
BEFORE INSERT OR UPDATE ON pagos
FOR EACH ROW
BEGIN
    :NEW.metodo_pago := TRIM(:NEW.metodo_pago);
    :NEW.estado_pago := INITCAP(TRIM(:NEW.estado_pago));

    IF :NEW.referencia_transaccion IS NOT NULL THEN
        :NEW.referencia_transaccion := TRIM(:NEW.referencia_transaccion);
    END IF;

    IF NOT REGEXP_LIKE(:NEW.metodo_pago, '^(Tarjeta|SINPE|Transferencia|Efectivo)$') THEN
        RAISE_APPLICATION_ERROR(-20030, 'Metodo de pago no permitido.');
    END IF;

    IF :NEW.estado_pago NOT IN ('Pendiente', 'Pagado', 'Rechazado', 'Reembolsado') THEN
        RAISE_APPLICATION_ERROR(-20031, 'Estado de pago no valido.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_pagos_calcular_total
BEFORE INSERT OR UPDATE ON pagos
FOR EACH ROW
BEGIN
    :NEW.monto_total := fn_total_reserva(:NEW.id_reserva);
END;
/

CREATE OR REPLACE TRIGGER trg_rs_bi
BEFORE INSERT ON reserva_servicios
FOR EACH ROW
BEGIN
    IF :NEW.cantidad < 1 OR :NEW.cantidad > 20 THEN
        RAISE_APPLICATION_ERROR(-20032, 'La cantidad del servicio debe estar entre 1 y 20.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_rs_bu
BEFORE UPDATE ON reserva_servicios
FOR EACH ROW
BEGIN
    IF :NEW.cantidad < 1 OR :NEW.cantidad > 20 THEN
        RAISE_APPLICATION_ERROR(-20033, 'La cantidad actualizada del servicio debe estar entre 1 y 20.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_reservas_calcular_costo
BEFORE INSERT OR UPDATE OF id_sala, fecha, hora_inicio, hora_fin ON reservas
FOR EACH ROW
DECLARE
    v_precio NUMBER;
    v_horas  NUMBER;
BEGIN
    IF TRUNC(:NEW.hora_inicio) <> :NEW.fecha OR TRUNC(:NEW.hora_fin) <> :NEW.fecha THEN
        RAISE_APPLICATION_ERROR(-20034, 'La fecha de la reserva debe coincidir con la fecha del horario.');
    END IF;

    IF :NEW.hora_fin <= :NEW.hora_inicio THEN
        RAISE_APPLICATION_ERROR(-20035, 'La hora final debe ser mayor que la hora inicial.');
    END IF;

    IF :NEW.hora_inicio < SYSTIMESTAMP THEN
        RAISE_APPLICATION_ERROR(-20036, 'No se puede crear una reserva en una fecha u hora pasada.');
    END IF;

    v_horas := (CAST(:NEW.hora_fin AS DATE) - CAST(:NEW.hora_inicio AS DATE)) * 24;

    IF v_horas < 1 THEN
        RAISE_APPLICATION_ERROR(-20037, 'La reserva debe tener una duracion minima de 1 hora.');
    END IF;

    IF v_horas > 12 THEN
        RAISE_APPLICATION_ERROR(-20038, 'La reserva no puede durar mas de 12 horas.');
    END IF;

    SELECT precio_hora
      INTO v_precio
      FROM salas
     WHERE id_sala = :NEW.id_sala;

    :NEW.costo_total := ROUND(v_precio * v_horas, 2);
END;
/

CREATE OR REPLACE TRIGGER trg_reservas_validar_disponibilidad
FOR INSERT OR UPDATE OF id_sala, fecha, hora_inicio, hora_fin ON reservas
COMPOUND TRIGGER
    TYPE t_reserva_rec IS RECORD (
        id_reserva   reservas.id_reserva%TYPE,
        id_sala      reservas.id_sala%TYPE,
        fecha        reservas.fecha%TYPE,
        hora_inicio  reservas.hora_inicio%TYPE,
        hora_fin     reservas.hora_fin%TYPE
    );
    TYPE t_reserva_tab IS TABLE OF t_reserva_rec INDEX BY PLS_INTEGER;
    g_reservas t_reserva_tab;
    g_idx NUMBER := 0;

    BEFORE EACH ROW IS
    BEGIN
        g_idx := g_idx + 1;
        g_reservas(g_idx).id_reserva  := NVL(:NEW.id_reserva, -1);
        g_reservas(g_idx).id_sala     := :NEW.id_sala;
        g_reservas(g_idx).fecha       := :NEW.fecha;
        g_reservas(g_idx).hora_inicio := :NEW.hora_inicio;
        g_reservas(g_idx).hora_fin    := :NEW.hora_fin;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_count NUMBER;
    BEGIN
        FOR i IN 1 .. g_idx LOOP
            SELECT COUNT(*)
              INTO v_count
              FROM reservas r
             WHERE r.id_sala = g_reservas(i).id_sala
               AND TRUNC(r.fecha) = TRUNC(g_reservas(i).fecha)
               AND r.id_reserva <> g_reservas(i).id_reserva
               AND g_reservas(i).hora_inicio < r.hora_fin
               AND g_reservas(i).hora_fin > r.hora_inicio;

            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20039, 'La sala ya tiene una reserva en ese horario o en un rango traslapado.');
            END IF;
        END LOOP;
    END AFTER STATEMENT;
END trg_reservas_validar_disponibilidad;
/

CREATE OR REPLACE TRIGGER trg_reservas_bitacora_estado
AFTER UPDATE OF id_estado ON reservas
FOR EACH ROW
BEGIN
    INSERT INTO bitacora_cambios (id_reserva, id_estado_anterior, id_estado_nuevo)
    VALUES (:NEW.id_reserva, :OLD.id_estado, :NEW.id_estado);
END;
/

-- ============================================================
-- BLOQUE 6. PAQUETES PRINCIPALES
-- ============================================================
CREATE OR REPLACE PACKAGE pkg_catalogos AS
    PROCEDURE sp_insertar_edificio(p_nombre_edificio IN VARCHAR2, p_direccion IN VARCHAR2);
    PROCEDURE sp_actualizar_edificio(p_id_edificio IN NUMBER, p_nombre_edificio IN VARCHAR2, p_direccion IN VARCHAR2);
    PROCEDURE sp_eliminar_edificio(p_id_edificio IN NUMBER);

    PROCEDURE sp_insertar_piso(p_numero_piso IN NUMBER, p_id_edificio IN NUMBER);
    PROCEDURE sp_actualizar_piso(p_id_piso IN NUMBER, p_numero_piso IN NUMBER, p_id_edificio IN NUMBER);
    PROCEDURE sp_eliminar_piso(p_id_piso IN NUMBER);

    PROCEDURE sp_insertar_rol(p_descripcion_rol IN VARCHAR2);
    PROCEDURE sp_actualizar_rol(p_id_rol IN NUMBER, p_descripcion_rol IN VARCHAR2);
    PROCEDURE sp_eliminar_rol(p_id_rol IN NUMBER);

    PROCEDURE sp_insertar_tipo_sala(p_descripcion_tipo IN VARCHAR2);
    PROCEDURE sp_actualizar_tipo_sala(p_id_tipo IN NUMBER, p_descripcion_tipo IN VARCHAR2);
    PROCEDURE sp_eliminar_tipo_sala(p_id_tipo IN NUMBER);

    PROCEDURE sp_insertar_sala(p_nombre_sala IN VARCHAR2, p_capacidad IN NUMBER, p_precio_hora IN NUMBER, p_id_tipo IN NUMBER, p_id_piso IN NUMBER);
    PROCEDURE sp_actualizar_sala(p_id_sala IN NUMBER, p_nombre_sala IN VARCHAR2, p_capacidad IN NUMBER, p_precio_hora IN NUMBER, p_id_tipo IN NUMBER, p_id_piso IN NUMBER);
    PROCEDURE sp_eliminar_sala(p_id_sala IN NUMBER);

    PROCEDURE sp_insertar_estado(p_nombre_estado IN VARCHAR2);
    PROCEDURE sp_actualizar_estado(p_id_estado IN NUMBER, p_nombre_estado IN VARCHAR2);
    PROCEDURE sp_eliminar_estado(p_id_estado IN NUMBER);

    PROCEDURE sp_insertar_servicio(p_nombre_servicio IN VARCHAR2, p_precio_adicional IN NUMBER);
    PROCEDURE sp_actualizar_servicio(p_id_servicio IN NUMBER, p_nombre_servicio IN VARCHAR2, p_precio_adicional IN NUMBER);
    PROCEDURE sp_eliminar_servicio(p_id_servicio IN NUMBER);

    PROCEDURE sp_insertar_reserva_servicio(p_id_reserva IN NUMBER, p_id_servicio IN NUMBER, p_cantidad IN NUMBER);
    PROCEDURE sp_actualizar_reserva_servicio(p_id_reserva IN NUMBER, p_id_servicio IN NUMBER, p_cantidad IN NUMBER);
    PROCEDURE sp_eliminar_reserva_servicio(p_id_reserva IN NUMBER, p_id_servicio IN NUMBER);

    PROCEDURE sp_insertar_bitacora(p_id_reserva IN NUMBER, p_id_estado_anterior IN NUMBER, p_id_estado_nuevo IN NUMBER);
    PROCEDURE sp_actualizar_bitacora(p_id_log IN NUMBER, p_id_estado_anterior IN NUMBER, p_id_estado_nuevo IN NUMBER);
    PROCEDURE sp_eliminar_bitacora(p_id_log IN NUMBER);

    PROCEDURE sp_listar_salas_cursor;
    PROCEDURE sp_listar_servicios_cursor;
    PROCEDURE sp_listar_bitacora_cursor;
END pkg_catalogos;
/

CREATE OR REPLACE PACKAGE BODY pkg_catalogos AS
    PROCEDURE sp_insertar_edificio(p_nombre_edificio IN VARCHAR2, p_direccion IN VARCHAR2) IS
    BEGIN
        INSERT INTO edificio (nombre_edificio, direccion)
        VALUES (p_nombre_edificio, p_direccion);
    END;

    PROCEDURE sp_actualizar_edificio(p_id_edificio IN NUMBER, p_nombre_edificio IN VARCHAR2, p_direccion IN VARCHAR2) IS
    BEGIN
        UPDATE edificio
           SET nombre_edificio = p_nombre_edificio,
               direccion = p_direccion
         WHERE id_edificio = p_id_edificio;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20200, 'No existe el edificio que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_edificio(p_id_edificio IN NUMBER) IS
    BEGIN
        DELETE FROM edificio
         WHERE id_edificio = p_id_edificio;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20201, 'No existe el edificio que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_piso(p_numero_piso IN NUMBER, p_id_edificio IN NUMBER) IS
    BEGIN
        INSERT INTO piso (numero_piso, id_edificio)
        VALUES (p_numero_piso, p_id_edificio);
    END;

    PROCEDURE sp_actualizar_piso(p_id_piso IN NUMBER, p_numero_piso IN NUMBER, p_id_edificio IN NUMBER) IS
    BEGIN
        UPDATE piso
           SET numero_piso = p_numero_piso,
               id_edificio = p_id_edificio
         WHERE id_piso = p_id_piso;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20202, 'No existe el piso que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_piso(p_id_piso IN NUMBER) IS
    BEGIN
        DELETE FROM piso
         WHERE id_piso = p_id_piso;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20203, 'No existe el piso que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_rol(p_descripcion_rol IN VARCHAR2) IS
    BEGIN
        INSERT INTO roles (descripcion_rol)
        VALUES (p_descripcion_rol);
    END;

    PROCEDURE sp_actualizar_rol(p_id_rol IN NUMBER, p_descripcion_rol IN VARCHAR2) IS
    BEGIN
        UPDATE roles
           SET descripcion_rol = p_descripcion_rol
         WHERE id_rol = p_id_rol;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20204, 'No existe el rol que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_rol(p_id_rol IN NUMBER) IS
    BEGIN
        DELETE FROM roles
         WHERE id_rol = p_id_rol;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20205, 'No existe el rol que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_tipo_sala(p_descripcion_tipo IN VARCHAR2) IS
    BEGIN
        INSERT INTO tipo_sala (descripcion_tipo)
        VALUES (p_descripcion_tipo);
    END;

    PROCEDURE sp_actualizar_tipo_sala(p_id_tipo IN NUMBER, p_descripcion_tipo IN VARCHAR2) IS
    BEGIN
        UPDATE tipo_sala
           SET descripcion_tipo = p_descripcion_tipo
         WHERE id_tipo = p_id_tipo;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20206, 'No existe el tipo de sala que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_tipo_sala(p_id_tipo IN NUMBER) IS
    BEGIN
        DELETE FROM tipo_sala
         WHERE id_tipo = p_id_tipo;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20207, 'No existe el tipo de sala que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_sala(p_nombre_sala IN VARCHAR2, p_capacidad IN NUMBER, p_precio_hora IN NUMBER, p_id_tipo IN NUMBER, p_id_piso IN NUMBER) IS
    BEGIN
        INSERT INTO salas (nombre_sala, capacidad, precio_hora, id_tipo, id_piso)
        VALUES (p_nombre_sala, p_capacidad, p_precio_hora, p_id_tipo, p_id_piso);
    END;

    PROCEDURE sp_actualizar_sala(p_id_sala IN NUMBER, p_nombre_sala IN VARCHAR2, p_capacidad IN NUMBER, p_precio_hora IN NUMBER, p_id_tipo IN NUMBER, p_id_piso IN NUMBER) IS
    BEGIN
        UPDATE salas
           SET nombre_sala = p_nombre_sala,
               capacidad = p_capacidad,
               precio_hora = p_precio_hora,
               id_tipo = p_id_tipo,
               id_piso = p_id_piso
         WHERE id_sala = p_id_sala;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20208, 'No existe la sala que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_sala(p_id_sala IN NUMBER) IS
    BEGIN
        DELETE FROM salas
         WHERE id_sala = p_id_sala;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20209, 'No existe la sala que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_estado(p_nombre_estado IN VARCHAR2) IS
    BEGIN
        INSERT INTO estados (nombre_estado)
        VALUES (p_nombre_estado);
    END;

    PROCEDURE sp_actualizar_estado(p_id_estado IN NUMBER, p_nombre_estado IN VARCHAR2) IS
    BEGIN
        UPDATE estados
           SET nombre_estado = p_nombre_estado
         WHERE id_estado = p_id_estado;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20210, 'No existe el estado que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_estado(p_id_estado IN NUMBER) IS
    BEGIN
        DELETE FROM estados
         WHERE id_estado = p_id_estado;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20211, 'No existe el estado que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_servicio(p_nombre_servicio IN VARCHAR2, p_precio_adicional IN NUMBER) IS
    BEGIN
        INSERT INTO servicios (nombre_servicio, precio_adicional)
        VALUES (p_nombre_servicio, p_precio_adicional);
    END;

    PROCEDURE sp_actualizar_servicio(p_id_servicio IN NUMBER, p_nombre_servicio IN VARCHAR2, p_precio_adicional IN NUMBER) IS
    BEGIN
        UPDATE servicios
           SET nombre_servicio = p_nombre_servicio,
               precio_adicional = p_precio_adicional
         WHERE id_servicio = p_id_servicio;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20212, 'No existe el servicio que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_servicio(p_id_servicio IN NUMBER) IS
    BEGIN
        DELETE FROM servicios
         WHERE id_servicio = p_id_servicio;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20213, 'No existe el servicio que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_reserva_servicio(p_id_reserva IN NUMBER, p_id_servicio IN NUMBER, p_cantidad IN NUMBER) IS
    BEGIN
        INSERT INTO reserva_servicios (id_reserva, id_servicio, cantidad)
        VALUES (p_id_reserva, p_id_servicio, p_cantidad);
    END;

    PROCEDURE sp_actualizar_reserva_servicio(p_id_reserva IN NUMBER, p_id_servicio IN NUMBER, p_cantidad IN NUMBER) IS
    BEGIN
        UPDATE reserva_servicios
           SET cantidad = p_cantidad
         WHERE id_reserva = p_id_reserva
           AND id_servicio = p_id_servicio;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20214, 'No existe la relacion reserva-servicio que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_reserva_servicio(p_id_reserva IN NUMBER, p_id_servicio IN NUMBER) IS
    BEGIN
        DELETE FROM reserva_servicios
         WHERE id_reserva = p_id_reserva
           AND id_servicio = p_id_servicio;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20215, 'No existe la relacion reserva-servicio que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_insertar_bitacora(p_id_reserva IN NUMBER, p_id_estado_anterior IN NUMBER, p_id_estado_nuevo IN NUMBER) IS
    BEGIN
        INSERT INTO bitacora_cambios (id_reserva, id_estado_anterior, id_estado_nuevo)
        VALUES (p_id_reserva, p_id_estado_anterior, p_id_estado_nuevo);
    END;

    PROCEDURE sp_actualizar_bitacora(p_id_log IN NUMBER, p_id_estado_anterior IN NUMBER, p_id_estado_nuevo IN NUMBER) IS
    BEGIN
        UPDATE bitacora_cambios
           SET id_estado_anterior = p_id_estado_anterior,
               id_estado_nuevo = p_id_estado_nuevo
         WHERE id_log = p_id_log;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20216, 'No existe el registro de bitacora que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_bitacora(p_id_log IN NUMBER) IS
    BEGIN
        DELETE FROM bitacora_cambios
         WHERE id_log = p_id_log;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20217, 'No existe el registro de bitacora que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_listar_salas_cursor IS
        CURSOR c_salas IS
            SELECT id_sala, nombre_sala, capacidad, precio_hora
              FROM salas
             ORDER BY id_sala;
    BEGIN
        FOR rec IN c_salas LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_sala || ' - ' || rec.nombre_sala || ' - Capacidad: ' || rec.capacidad || ' - Precio/hora: ' || rec.precio_hora);
        END LOOP;
    END;

    PROCEDURE sp_listar_servicios_cursor IS
        CURSOR c_servicios IS
            SELECT id_servicio, nombre_servicio, precio_adicional
              FROM servicios
             ORDER BY id_servicio;
    BEGIN
        FOR rec IN c_servicios LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_servicio || ' - ' || rec.nombre_servicio || ' - ' || rec.precio_adicional);
        END LOOP;
    END;

    PROCEDURE sp_listar_bitacora_cursor IS
        CURSOR c_bitacora IS
            SELECT id_log, id_reserva, id_estado_anterior, id_estado_nuevo, fecha_cambio
              FROM bitacora_cambios
             ORDER BY id_log;
    BEGIN
        FOR rec IN c_bitacora LOOP
            DBMS_OUTPUT.PUT_LINE(
                rec.id_log || ' - Reserva: ' || rec.id_reserva || ' - ' ||
                NVL(TO_CHAR(rec.id_estado_anterior), 'NULL') || ' -> ' ||
                NVL(TO_CHAR(rec.id_estado_nuevo), 'NULL') || ' - ' ||
                TO_CHAR(rec.fecha_cambio, 'DD/MM/YYYY HH24:MI:SS')
            );
        END LOOP;
    END;
END pkg_catalogos;
/

CREATE OR REPLACE PACKAGE pkg_usuarios AS
    PROCEDURE sp_insertar_usuario(
        p_nombre IN VARCHAR2,
        p_apellido_1 IN VARCHAR2,
        p_apellido_2 IN VARCHAR2,
        p_correo IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_codigo_pais IN VARCHAR2,
        p_contrasena_hash IN VARCHAR2,
        p_id_rol IN NUMBER
    );

    PROCEDURE sp_actualizar_usuario(
        p_id_usuario IN NUMBER,
        p_nombre IN VARCHAR2,
        p_apellido_1 IN VARCHAR2,
        p_apellido_2 IN VARCHAR2,
        p_correo IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_codigo_pais IN VARCHAR2,
        p_contrasena_hash IN VARCHAR2,
        p_id_rol IN NUMBER
    );

    PROCEDURE sp_eliminar_usuario(p_id_usuario IN NUMBER);
    PROCEDURE sp_listar_usuarios_cursor;
END pkg_usuarios;
/

CREATE OR REPLACE PACKAGE BODY pkg_usuarios AS
    PROCEDURE sp_insertar_usuario(
        p_nombre IN VARCHAR2,
        p_apellido_1 IN VARCHAR2,
        p_apellido_2 IN VARCHAR2,
        p_correo IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_codigo_pais IN VARCHAR2,
        p_contrasena_hash IN VARCHAR2,
        p_id_rol IN NUMBER
    ) IS
    BEGIN
        INSERT INTO usuarios (
            nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol
        )
        VALUES (
            p_nombre, p_apellido_1, p_apellido_2, p_correo, p_telefono, p_codigo_pais, p_contrasena_hash, p_id_rol
        );
    END;

    PROCEDURE sp_actualizar_usuario(
        p_id_usuario IN NUMBER,
        p_nombre IN VARCHAR2,
        p_apellido_1 IN VARCHAR2,
        p_apellido_2 IN VARCHAR2,
        p_correo IN VARCHAR2,
        p_telefono IN VARCHAR2,
        p_codigo_pais IN VARCHAR2,
        p_contrasena_hash IN VARCHAR2,
        p_id_rol IN NUMBER
    ) IS
    BEGIN
        UPDATE usuarios
           SET nombre = p_nombre,
               apellido_1 = p_apellido_1,
               apellido_2 = p_apellido_2,
               correo = p_correo,
               telefono = p_telefono,
               codigo_pais = p_codigo_pais,
               contrasena_hash = p_contrasena_hash,
               id_rol = p_id_rol
         WHERE id_usuario = p_id_usuario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20100, 'No existe el usuario que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_usuario(p_id_usuario IN NUMBER) IS
    BEGIN
        DELETE FROM usuarios
         WHERE id_usuario = p_id_usuario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20101, 'No existe el usuario que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_listar_usuarios_cursor IS
        CURSOR c_usuarios IS
            SELECT id_usuario, nombre, apellido_1, correo, telefono, codigo_pais
              FROM usuarios
             ORDER BY id_usuario;
    BEGIN
        FOR rec IN c_usuarios LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_usuario || ' - ' || rec.nombre || ' ' || rec.apellido_1 ||
                                 ' - ' || rec.correo || ' - ' || rec.telefono || ' - ' || rec.codigo_pais);
        END LOOP;
    END;
END pkg_usuarios;
/

CREATE OR REPLACE PACKAGE pkg_reservas AS
    PROCEDURE sp_insertar_reserva(
        p_id_usuario   IN NUMBER,
        p_id_sala      IN NUMBER,
        p_id_estado    IN NUMBER,
        p_fecha        IN DATE,
        p_hora_inicio  IN TIMESTAMP,
        p_hora_fin     IN TIMESTAMP
    );

    PROCEDURE sp_insertar_reserva_ret(
        p_id_usuario   IN NUMBER,
        p_id_sala      IN NUMBER,
        p_id_estado    IN NUMBER,
        p_fecha        IN DATE,
        p_hora_inicio  IN TIMESTAMP,
        p_hora_fin     IN TIMESTAMP,
        p_id_reserva   OUT NUMBER
    );

    PROCEDURE sp_actualizar_estado_reserva(
        p_id_reserva IN NUMBER,
        p_id_estado  IN NUMBER
    );

    PROCEDURE sp_eliminar_reserva(
        p_id_reserva IN NUMBER
    );

    PROCEDURE sp_lista_reservas_cursor;
    PROCEDURE sp_lista_salas_disponibles_cursor;
END pkg_reservas;
/

CREATE OR REPLACE PACKAGE BODY pkg_reservas AS
    PROCEDURE sp_insertar_reserva(
        p_id_usuario   IN NUMBER,
        p_id_sala      IN NUMBER,
        p_id_estado    IN NUMBER,
        p_fecha        IN DATE,
        p_hora_inicio  IN TIMESTAMP,
        p_hora_fin     IN TIMESTAMP
    ) IS
    BEGIN
        INSERT INTO reservas (
            id_usuario,
            id_sala,
            id_estado,
            fecha,
            hora_inicio,
            hora_fin
        )
        VALUES (
            p_id_usuario,
            p_id_sala,
            p_id_estado,
            p_fecha,
            p_hora_inicio,
            p_hora_fin
        );
    END;

    PROCEDURE sp_insertar_reserva_ret(
        p_id_usuario   IN NUMBER,
        p_id_sala      IN NUMBER,
        p_id_estado    IN NUMBER,
        p_fecha        IN DATE,
        p_hora_inicio  IN TIMESTAMP,
        p_hora_fin     IN TIMESTAMP,
        p_id_reserva   OUT NUMBER
    ) IS
    BEGIN
        INSERT INTO reservas (
            id_usuario,
            id_sala,
            id_estado,
            fecha,
            hora_inicio,
            hora_fin
        )
        VALUES (
            p_id_usuario,
            p_id_sala,
            p_id_estado,
            p_fecha,
            p_hora_inicio,
            p_hora_fin
        )
        RETURNING id_reserva INTO p_id_reserva;
    END;

    PROCEDURE sp_actualizar_estado_reserva(
        p_id_reserva IN NUMBER,
        p_id_estado  IN NUMBER
    ) IS
    BEGIN
        UPDATE reservas
           SET id_estado = p_id_estado
         WHERE id_reserva = p_id_reserva;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'No existe la reserva que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_eliminar_reserva(
        p_id_reserva IN NUMBER
    ) IS
    BEGIN
        DELETE FROM reservas
         WHERE id_reserva = p_id_reserva;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20103, 'No existe la reserva que desea eliminar.');
        END IF;
    END;

    PROCEDURE sp_lista_reservas_cursor IS
        CURSOR c_reservas IS
            SELECT r.id_reserva, u.nombre, s.nombre_sala, r.fecha, r.costo_total
              FROM reservas r
              JOIN usuarios u ON r.id_usuario = u.id_usuario
              JOIN salas s ON r.id_sala = s.id_sala
             ORDER BY r.id_reserva;
    BEGIN
        FOR rec IN c_reservas LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_reserva || ' - ' || rec.nombre || ' - ' || rec.nombre_sala ||
                                 ' - ' || TO_CHAR(rec.fecha, 'DD/MM/YYYY') || ' - ' || rec.costo_total);
        END LOOP;
    END;

    PROCEDURE sp_lista_salas_disponibles_cursor IS
        CURSOR c_salas IS
            SELECT s.id_sala, s.nombre_sala
              FROM salas s
             WHERE s.id_sala NOT IN (SELECT r.id_sala FROM reservas r)
             ORDER BY s.id_sala;
    BEGIN
        FOR rec IN c_salas LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_sala || ' - ' || rec.nombre_sala);
        END LOOP;
    END;
END pkg_reservas;
/

CREATE OR REPLACE PACKAGE pkg_pagos AS
    PROCEDURE sp_insertar_pago(
        p_id_reserva             IN NUMBER,
        p_metodo_pago            IN VARCHAR2,
        p_estado_pago            IN VARCHAR2,
        p_referencia_transaccion IN VARCHAR2,
        p_registrado_por         IN NUMBER
    );

    PROCEDURE sp_actualizar_estado_pago(
        p_id_pago      IN NUMBER,
        p_estado_pago  IN VARCHAR2
    );

    PROCEDURE sp_reporte_pagos_cursor;
END pkg_pagos;
/

CREATE OR REPLACE PACKAGE BODY pkg_pagos AS
    PROCEDURE sp_insertar_pago(
        p_id_reserva             IN NUMBER,
        p_metodo_pago            IN VARCHAR2,
        p_estado_pago            IN VARCHAR2,
        p_referencia_transaccion IN VARCHAR2,
        p_registrado_por         IN NUMBER
    ) IS
    BEGIN
        INSERT INTO pagos (id_reserva, monto_total, metodo_pago, estado_pago, referencia_transaccion, registrado_por)
        VALUES (p_id_reserva, 0, p_metodo_pago, p_estado_pago, p_referencia_transaccion, p_registrado_por);
    END;

    PROCEDURE sp_actualizar_estado_pago(
        p_id_pago      IN NUMBER,
        p_estado_pago  IN VARCHAR2
    ) IS
    BEGIN
        UPDATE pagos
           SET estado_pago = p_estado_pago
         WHERE id_pago = p_id_pago;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20073, 'No existe el pago que desea actualizar.');
        END IF;
    END;

    PROCEDURE sp_reporte_pagos_cursor IS
        CURSOR c_pagos IS
            SELECT id_pago, id_reserva, monto_total, metodo_pago, estado_pago, referencia_transaccion, fecha_pago
              FROM pagos
             ORDER BY id_pago;
    BEGIN
        FOR rec IN c_pagos LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_pago || ' - ' || rec.id_reserva || ' - ' || rec.monto_total ||
                                 ' - ' || rec.metodo_pago || ' - ' || rec.estado_pago);
        END LOOP;
    END;
END pkg_pagos;
/

CREATE OR REPLACE PACKAGE pkg_funciones AS
    FUNCTION fn_total_ingresos RETURN NUMBER;
    FUNCTION fn_cantidad_reservas_usuario(p_id_usuario IN NUMBER) RETURN NUMBER;
END pkg_funciones;
/

CREATE OR REPLACE PACKAGE BODY pkg_funciones AS
    FUNCTION fn_total_ingresos RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(monto_total), 0)
          INTO v_total
          FROM pagos;
        RETURN v_total;
    END;

    FUNCTION fn_cantidad_reservas_usuario(p_id_usuario IN NUMBER) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_total
          FROM reservas
         WHERE id_usuario = p_id_usuario;
        RETURN v_total;
    END;
END pkg_funciones;
/

CREATE OR REPLACE PACKAGE pkg_reportes AS
    PROCEDURE sp_reporte_reservas_por_fecha(p_fecha IN DATE);
    PROCEDURE sp_reporte_pagos_por_metodo(p_metodo IN VARCHAR2);
    PROCEDURE sp_reporte_salas_mas_reservadas;
END pkg_reportes;
/

CREATE OR REPLACE PACKAGE BODY pkg_reportes AS
    PROCEDURE sp_reporte_reservas_por_fecha(p_fecha IN DATE) IS
        CURSOR c_reporte IS
            SELECT r.id_reserva, s.nombre_sala, u.nombre, r.hora_inicio, r.hora_fin, r.costo_total
              FROM reservas r
              JOIN salas s ON r.id_sala = s.id_sala
              JOIN usuarios u ON r.id_usuario = u.id_usuario
             WHERE TRUNC(r.fecha) = TRUNC(p_fecha)
             ORDER BY r.hora_inicio;
    BEGIN
        FOR rec IN c_reporte LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_reserva || ' - ' || rec.nombre_sala || ' - ' || rec.nombre ||
                                 ' - ' || TO_CHAR(rec.hora_inicio, 'HH24:MI') || ' a ' ||
                                 TO_CHAR(rec.hora_fin, 'HH24:MI') || ' - ' || rec.costo_total);
        END LOOP;
    END;

    PROCEDURE sp_reporte_pagos_por_metodo(p_metodo IN VARCHAR2) IS
        CURSOR c_pagos IS
            SELECT id_pago, id_reserva, monto_total, fecha_pago
              FROM pagos
             WHERE metodo_pago = p_metodo
             ORDER BY fecha_pago;
    BEGIN
        FOR rec IN c_pagos LOOP
            DBMS_OUTPUT.PUT_LINE(rec.id_pago || ' - ' || rec.id_reserva || ' - ' || rec.monto_total ||
                                 ' - ' || TO_CHAR(rec.fecha_pago, 'DD/MM/YYYY HH24:MI:SS'));
        END LOOP;
    END;

    PROCEDURE sp_reporte_salas_mas_reservadas IS
        CURSOR c_salas IS
            SELECT s.nombre_sala, COUNT(r.id_reserva) total_reservas
              FROM salas s
              LEFT JOIN reservas r ON s.id_sala = r.id_sala
             GROUP BY s.nombre_sala
             ORDER BY total_reservas DESC, s.nombre_sala;
    BEGIN
        FOR rec IN c_salas LOOP
            DBMS_OUTPUT.PUT_LINE(rec.nombre_sala || ' - ' || rec.total_reservas);
        END LOOP;
    END;
END pkg_reportes;
/

-- ============================================================
-- BLOQUE 7. VISTAS
-- ============================================================
CREATE OR REPLACE VIEW vw_reporte_reservas AS
SELECT
    r.id_reserva,
    u.nombre || ' ' || u.apellido_1 AS usuario,
    u.codigo_pais,
    u.telefono,
    s.nombre_sala AS sala,
    e.nombre_estado AS estado,
    TO_CHAR(r.fecha, 'DD/MM/YYYY') AS fecha,
    TO_CHAR(r.hora_inicio, 'HH24:MI') AS hora_inicio,
    TO_CHAR(r.hora_fin, 'HH24:MI') AS hora_fin,
    r.costo_total
FROM reservas r
JOIN usuarios u ON r.id_usuario = u.id_usuario
JOIN salas s ON r.id_sala = s.id_sala
JOIN estados e ON r.id_estado = e.id_estado;
/

CREATE OR REPLACE VIEW vw_servicios_reserva AS
SELECT
    rs.id_reserva,
    s.nombre_servicio,
    rs.cantidad,
    s.precio_adicional,
    (rs.cantidad * s.precio_adicional) AS subtotal_servicio
FROM reserva_servicios rs
JOIN servicios s ON rs.id_servicio = s.id_servicio;
/

CREATE OR REPLACE VIEW vw_usuarios_reporte AS
SELECT
    u.id_usuario,
    u.nombre,
    u.apellido_1,
    u.apellido_2,
    u.correo,
    u.codigo_pais,
    u.telefono,
    '+' || u.codigo_pais || ' ' || u.telefono AS telefono_completo,
    u.id_rol,
    r.descripcion_rol AS rol
FROM usuarios u
JOIN roles r ON u.id_rol = r.id_rol;
/

CREATE OR REPLACE VIEW vw_salas_reporte AS
SELECT
    s.id_sala,
    s.nombre_sala,
    s.capacidad,
    s.precio_hora,
    s.id_tipo,
    ts.descripcion_tipo AS tipo_sala,
    s.id_piso,
    p.numero_piso,
    e.nombre_edificio
FROM salas s
JOIN tipo_sala ts ON s.id_tipo = ts.id_tipo
JOIN piso p ON s.id_piso = p.id_piso
JOIN edificio e ON p.id_edificio = e.id_edificio;
/

-- ============================================================
-- BLOQUE 8. DATOS INICIALES
-- ============================================================
INSERT INTO edificio (nombre_edificio, direccion)
VALUES ('Central', 'San Jose');
/

INSERT INTO piso (numero_piso, id_edificio)
VALUES (1, (SELECT id_edificio FROM edificio WHERE nombre_edificio = 'Central'));
/

INSERT INTO piso (numero_piso, id_edificio)
VALUES (2, (SELECT id_edificio FROM edificio WHERE nombre_edificio = 'Central'));
/

INSERT INTO roles (descripcion_rol) VALUES ('Administrador');
/
INSERT INTO roles (descripcion_rol) VALUES ('Cliente');
/
INSERT INTO roles (descripcion_rol) VALUES ('Servicio al Cliente');
/

INSERT INTO tipo_sala (descripcion_tipo) VALUES ('Sala de Reunion');
/
INSERT INTO tipo_sala (descripcion_tipo) VALUES ('Sala Privada');
/
INSERT INTO tipo_sala (descripcion_tipo) VALUES ('Sala de Capacitacion');
/

INSERT INTO salas (nombre_sala, capacidad, precio_hora, id_tipo, id_piso)
VALUES (
    'Sala Milan',
    6,
    12000,
    (SELECT id_tipo FROM tipo_sala WHERE descripcion_tipo = 'Sala de Reunion'),
    (SELECT p.id_piso
       FROM piso p
       JOIN edificio e ON p.id_edificio = e.id_edificio
      WHERE p.numero_piso = 1
        AND e.nombre_edificio = 'Central')
);
/

INSERT INTO salas (nombre_sala, capacidad, precio_hora, id_tipo, id_piso)
VALUES (
    'Sala Madrid',
    10,
    18000,
    (SELECT id_tipo FROM tipo_sala WHERE descripcion_tipo = 'Sala Privada'),
    (SELECT p.id_piso
       FROM piso p
       JOIN edificio e ON p.id_edificio = e.id_edificio
      WHERE p.numero_piso = 1
        AND e.nombre_edificio = 'Central')
);
/

INSERT INTO salas (nombre_sala, capacidad, precio_hora, id_tipo, id_piso)
VALUES (
    'Sala Lima',
    20,
    25000,
    (SELECT id_tipo FROM tipo_sala WHERE descripcion_tipo = 'Sala de Capacitacion'),
    (SELECT p.id_piso
       FROM piso p
       JOIN edificio e ON p.id_edificio = e.id_edificio
      WHERE p.numero_piso = 2
        AND e.nombre_edificio = 'Central')
);
/

INSERT INTO estados (nombre_estado) VALUES ('Pendiente');
/
INSERT INTO estados (nombre_estado) VALUES ('Confirmada');
/
INSERT INTO estados (nombre_estado) VALUES ('Cancelada');
/

INSERT INTO servicios (nombre_servicio, precio_adicional) VALUES ('Proyector', 5000);
/
INSERT INTO servicios (nombre_servicio, precio_adicional) VALUES ('Coffee Break', 7000);
/
INSERT INTO servicios (nombre_servicio, precio_adicional) VALUES ('Pizarra', 3000);
/
INSERT INTO servicios (nombre_servicio, precio_adicional) VALUES ('Soporte Tecnico', 10000);
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Flor', 'Martinez', 'Garcia', 'flor@correo.com', '88888888', 'CR', 'Flor123!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Administrador'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Alejandro', 'Gomez', 'Perez', 'alejandro@correo.com', '88880051', 'CR', 'Alejo123!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Natalie', 'Pinar', 'Lopez', 'natalie@correo.com', '88880052', 'CR', 'Naty123!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Kelly', 'Aguirre', 'Soto', 'kelly@correo.com', '88880053', 'CR', 'Kelly123!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Jeffrey', 'Pasos', 'Mendoza', 'jeffrey@correo.com', '88880054', 'CR', 'Jeff123!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Raquel', 'Caizas', 'Ruiz', 'raquel@correo.com', '88880055', 'CR', 'Raquel1!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Daniel', 'Quesada', 'Cascante', 'daniel@correo.com', '88880056', 'CR', 'Daniel1!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Servicio al Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Maria', 'Lopez', 'Vargas', 'maria@correo.com', '61234567', 'CR', 'Maria123!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Carlos', 'Ramirez', 'Mora', 'carlos@correo.com', '70123456', 'CR', 'Carlos1!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
VALUES ('Ana', 'Solis', 'Jimenez', 'ana@correo.com', '22345678', 'CR', 'AnaClave1!',
    (SELECT id_rol FROM roles WHERE descripcion_rol = 'Cliente'));
/

COMMIT;
/

-- ============================================================
-- BLOQUE 9. PRUEBAS POSITIVAS
-- ============================================================
BEGIN
    pkg_reservas.sp_insertar_reserva(
        1, 1, 1,
        DATE '2027-04-20',
        TO_TIMESTAMP('2027-04-20 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
        TO_TIMESTAMP('2027-04-20 10:00:00', 'YYYY-MM-DD HH24:MI:SS')
    );
END;
/

INSERT INTO reserva_servicios (id_reserva, id_servicio, cantidad) VALUES (1, 1, 1);
/
INSERT INTO reserva_servicios (id_reserva, id_servicio, cantidad) VALUES (1, 2, 2);
/

BEGIN
    pkg_pagos.sp_insertar_pago(
        1,
        'Tarjeta',
        'Pagado',
        'TXN-0001',
        1
    );
END;
/

BEGIN
    pkg_reservas.sp_actualizar_estado_reserva(1, 2);
END;
/

COMMIT;
/

-- ============================================================
-- BLOQUE 10. CONSULTAS DE VERIFICACION
-- ============================================================
SELECT table_name
FROM user_tables
WHERE table_name IN (
    'EDIFICIO', 'PISO', 'ROLES', 'USUARIOS', 'TIPO_SALA', 'SALAS',
    'ESTADOS', 'RESERVAS', 'SERVICIOS', 'RESERVA_SERVICIOS',
    'PAGOS', 'BITACORA_CAMBIOS'
)
ORDER BY table_name;
/

SELECT COUNT(*) AS total_edificios FROM edificio;
/
SELECT COUNT(*) AS total_pisos FROM piso;
/
SELECT COUNT(*) AS total_roles FROM roles;
/
SELECT COUNT(*) AS total_usuarios FROM usuarios;
/
SELECT COUNT(*) AS total_tipos_sala FROM tipo_sala;
/
SELECT COUNT(*) AS total_salas FROM salas;
/
SELECT COUNT(*) AS total_estados FROM estados;
/
SELECT COUNT(*) AS total_servicios FROM servicios;
/
SELECT COUNT(*) AS total_reservas FROM reservas;
/
SELECT COUNT(*) AS total_servicios_reserva FROM reserva_servicios;
/
SELECT COUNT(*) AS total_pagos FROM pagos;
/
SELECT COUNT(*) AS total_bitacora FROM bitacora_cambios;
/

SELECT *
FROM reservas
ORDER BY id_reserva;
/

SELECT *
FROM reserva_servicios
ORDER BY id_reserva, id_servicio;
/

SELECT id_pago,
       id_reserva,
       monto_total,
       metodo_pago,
       estado_pago,
       referencia_transaccion,
       registrado_por,
       fecha_pago
FROM pagos
ORDER BY id_pago;
/

SELECT *
FROM bitacora_cambios
ORDER BY id_log;
/

SELECT *
FROM vw_reporte_reservas;
/

SELECT *
FROM vw_servicios_reserva;
/

SELECT pkg_funciones.fn_total_ingresos AS total_ingresos
FROM dual;
/

SELECT pkg_funciones.fn_cantidad_reservas_usuario(1) AS reservas_usuario_1
FROM dual;
/

SELECT id_reserva, costo_total
FROM reservas
WHERE id_reserva = 13;

SELECT fn_total_reserva(13)
FROM dual;

SELECT id_reserva, costo_total
FROM reservas
WHERE id_reserva = 14;

SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('LISTA DE USUARIOS');
    pkg_usuarios.sp_listar_usuarios_cursor;

    DBMS_OUTPUT.PUT_LINE('LISTA DE RESERVAS');
    pkg_reservas.sp_lista_reservas_cursor;

    DBMS_OUTPUT.PUT_LINE('SALAS DISPONIBLES');
    pkg_reservas.sp_lista_salas_disponibles_cursor;

    DBMS_OUTPUT.PUT_LINE('REPORTE DE PAGOS');
    pkg_pagos.sp_reporte_pagos_cursor;

    DBMS_OUTPUT.PUT_LINE('CATALOGO DE SALAS');
    pkg_catalogos.sp_listar_salas_cursor;

    DBMS_OUTPUT.PUT_LINE('CATALOGO DE SERVICIOS');
    pkg_catalogos.sp_listar_servicios_cursor;

    DBMS_OUTPUT.PUT_LINE('BITACORA DE CAMBIOS');
    pkg_catalogos.sp_listar_bitacora_cursor;

    DBMS_OUTPUT.PUT_LINE('REPORTE DE RESERVAS POR FECHA');
    pkg_reportes.sp_reporte_reservas_por_fecha(DATE '2027-04-20');

    DBMS_OUTPUT.PUT_LINE('REPORTE DE PAGOS POR METODO');
    pkg_reportes.sp_reporte_pagos_por_metodo('Tarjeta');

    DBMS_OUTPUT.PUT_LINE('SALAS MAS RESERVADAS');
    pkg_reportes.sp_reporte_salas_mas_reservadas;
END;
/

SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('TABLE','VIEW','PACKAGE','PACKAGE BODY','FUNCTION','TRIGGER')
ORDER BY object_type, object_name;
/

-- ============================================================
-- BLOQUE 10A. CONSULTAS AUXILIARES PARA APEX
-- ============================================================
---Consultar usuarios

SELECT
    u.id_usuario,
    u.nombre || ' ' || u.apellido_1 AS nombre_completo,
    u.correo,
    u.telefono,
    r.descripcion_rol AS rol
FROM usuarios u
JOIN roles r
    ON u.id_rol = r.id_rol
ORDER BY u.id_usuario DESC;



---Consultar salas
/

SELECT *
FROM vw_salas_reporte
ORDER BY id_sala DESC;
/

SELECT
    nombre_sala || ' - Capacidad: ' || capacidad || ' - ₡' || precio_hora || '/hora' AS display_value,
    id_sala AS return_value
FROM salas
ORDER BY nombre_sala;
/

SELECT
    descripcion_tipo AS display_value,
    id_tipo AS return_value
FROM tipo_sala
ORDER BY descripcion_tipo;
/

SELECT
    descripcion_rol AS display_value,
    id_rol AS return_value
FROM roles
ORDER BY descripcion_rol;
/

SELECT
    nombre_estado AS display_value,
    id_estado AS return_value
FROM estados
ORDER BY nombre_estado;
/

SELECT
    nombre_servicio || ' - ₡' || precio_adicional AS display_value,
    id_servicio AS return_value
FROM servicios
ORDER BY nombre_servicio;
/

SELECT text
FROM user_source
WHERE name = 'PKG_RESERVAS'
  AND type IN ('PACKAGE', 'PACKAGE BODY')
ORDER BY type, line;



SELECT object_name, status
FROM user_objects
WHERE object_name = 'PKG_RESERVAS';

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('PKG_RESERVAS')
ORDER BY object_type;



-- ============================================================
-- BLOQUE 11. PRUEBAS NEGATIVAS
-- ============================================================

-- Correo invalido
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Prueba', 'Usuario', 'Demo', 'correomal', '88888888', 'CR', 'Prueba1!', 2);

-- Correo duplicado
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Laura', 'Mora', 'Lopez', 'flor@correo.com', '88889999', 'CR', 'Laura123!', 2);

-- Telefono duplicado
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Pedro', 'Ramirez', 'Soto', '88888888@correo.com', '88888888', 'CR', 'Pedro123!', 2);

-- Nombre con numeros
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Flor123', 'Martinez', 'Garcia', 'florx@correo.com', '88881234', 'CR', 'Flor123!', 2);

-- Contrasena muy corta
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Luis', 'Mora', 'Perez', 'luis@correo.com', '88881234', 'CR', 'Lui1!', 2);

-- Contrasena sin simbolo
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Mario', 'Lopez', 'Rojas', 'mario@correo.com', '88881235', 'CR', 'Mario1234', 2);

-- Codigo de pais distinto de CR
-- INSERT INTO usuarios (nombre, apellido_1, apellido_2, correo, telefono, codigo_pais, contrasena_hash, id_rol)
-- VALUES ('Pedro', 'Ramirez', 'Soto', 'pedro2@correo.com', '88888899', 'PA', 'Pedro123!', 2);

-- Rol duplicado
-- INSERT INTO roles (descripcion_rol) VALUES ('Cliente');

-- Tipo de sala duplicado
-- INSERT INTO tipo_sala (descripcion_tipo) VALUES ('Sala de Reunion');

-- Estado duplicado
-- INSERT INTO estados (nombre_estado) VALUES ('Pendiente');

-- Servicio duplicado
-- INSERT INTO servicios (nombre_servicio, precio_adicional) VALUES ('Proyector', 5000);

-- Sala duplicada
-- INSERT INTO salas (nombre_sala, capacidad, precio_hora, id_tipo, id_piso)
-- VALUES ('Sala Milan', 8, 15000, 1, 1);

-- Capacidad fuera de rango
-- INSERT INTO salas (nombre_sala, capacidad, precio_hora, id_tipo, id_piso)
-- VALUES ('Sala Error', -1, 10000, 1, 1);

-- Precio de servicio fuera de rango
-- INSERT INTO servicios (nombre_servicio, precio_adicional)
-- VALUES ('Servicio Error', -3000);

-- Metodo de pago invalido
-- BEGIN
--     pkg_pagos.sp_insertar_pago(
--         1,
--         'Cheque',
--         'Pagado',
--         'TXN-0002',
--         1
--     );
-- END;
-- /

-- Pago duplicado para la misma reserva
-- BEGIN
--     pkg_pagos.sp_insertar_pago(
--         1,
--         'Tarjeta',
--         'Pagado',
--         'TXN-0003',
--         1
--     );
-- END;
-- /

-- Reserva en el pasado
-- INSERT INTO reservas (id_usuario, id_sala, id_estado, fecha, hora_inicio, hora_fin)
-- VALUES (
--     2,
--     1,
--     1,
--     DATE '2024-01-01',
--     TO_TIMESTAMP('2024-01-01 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
--     TO_TIMESTAMP('2024-01-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS')
-- );

-- Reserva con fecha distinta al horario
-- INSERT INTO reservas (id_usuario, id_sala, id_estado, fecha, hora_inicio, hora_fin)
-- VALUES (
--     2,
--     1,
--     1,
--     DATE '2027-04-25',
--     TO_TIMESTAMP('2027-04-26 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
--     TO_TIMESTAMP('2027-04-26 10:00:00', 'YYYY-MM-DD HH24:MI:SS')
-- );

-- Reserva traslapada en la misma sala
-- INSERT INTO reservas (id_usuario, id_sala, id_estado, fecha, hora_inicio, hora_fin)
-- VALUES (
--     2,
--     1,
--     1,
--     DATE '2027-04-20',
--     TO_TIMESTAMP('2027-04-20 09:00:00', 'YYYY-MM-DD HH24:MI:SS'),
--     TO_TIMESTAMP('2027-04-20 11:00:00', 'YYYY-MM-DD HH24:MI:SS')
-- );

-- Cantidad invalida de servicio
-- INSERT INTO reserva_servicios (id_reserva, id_servicio, cantidad)
-- VALUES (1, 3, 0);
/


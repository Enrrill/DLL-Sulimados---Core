-- =============================================================================
-- 09_rrhh.sql
-- DDL para las tablas de recursos humanos (fase 1: catálogo de personal):
-- Trabajadores y su asignación multi-local (TrabajadorLocal).
-- La nómina y las comisiones (RF-49 a RF-51) quedan diferidas.
--
-- Referencias:
--   docs/ddl/06b.9-rrhh.md
--   docs/modelo-datos/06.9-rrhh.md
--   docs/03-requerimientos-del-sistema.md (RF-48)
-- =============================================================================

CREATE TABLE IF NOT EXISTS hr_trabajador (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    cargo           VARCHAR(50)  NOT NULL,  -- IMPRESOR, VENDEDOR, DISENADOR, PLANCHADOR, CONFECCIONADOR
    telefono        VARCHAR(30)  NOT NULL DEFAULT '',
    correo          VARCHAR(150) NOT NULL DEFAULT '',
    fecha_ingreso   DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_id      BIGINT       NULL,      -- referencia débil a usuarios(id) si tiene login
    activo          BOOLEAN      NOT NULL DEFAULT true,
    creado_en       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT hr_trabajador_usuario_uk UNIQUE (usuario_id)
);
CREATE INDEX IF NOT EXISTS hr_trabajador_cargo_idx
    ON hr_trabajador (cargo) WHERE activo;

CREATE TABLE IF NOT EXISTS hr_trabajador_local (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabajador_id  BIGINT      NOT NULL REFERENCES hr_trabajador(id) ON DELETE RESTRICT,
    local_id       BIGINT      NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
    es_principal   BOOLEAN     NOT NULL DEFAULT false,
    activo         BOOLEAN     NOT NULL DEFAULT true,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT hr_trabajador_local_uk UNIQUE (trabajador_id, local_id)
);
-- Solo un local principal por trabajador
CREATE UNIQUE INDEX IF NOT EXISTS hr_trabajador_local_principal_uk
    ON hr_trabajador_local (trabajador_id) WHERE es_principal;

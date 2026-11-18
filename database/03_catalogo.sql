-- =============================================================================
-- 03_catalogo.sql
-- DDL para el esquema y tablas del catálogo maestro:
-- Categorías, Subcategorías, Unidades de Medida, Tallas, Materiales,
-- Productos, Variantes de Producto y Servicios.
--
-- Referencias:
--   docs/ddl/06b.3-catalogo.md
--   docs/modelo-datos/06.3-catalogo.md
--   tasks/tareas-grupo-base-de-datos.md
-- =============================================================================

CREATE TABLE IF NOT EXISTS catalog_categoria (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    tipo           VARCHAR(20)  NOT NULL DEFAULT 'MATERIAL',
    activo         BOOLEAN      NOT NULL DEFAULT true,
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT catalog_categoria_uk UNIQUE (nombre, tipo)
);

CREATE TABLE IF NOT EXISTS catalog_subcategoria (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categoria_id   BIGINT       NOT NULL REFERENCES catalog_categoria(id) ON DELETE RESTRICT,
    nombre         VARCHAR(100) NOT NULL,
    activo         BOOLEAN      NOT NULL DEFAULT true,
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT catalog_subcategoria_uk UNIQUE (categoria_id, nombre)
);

CREATE TABLE IF NOT EXISTS catalog_unidad_medida (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo            VARCHAR(10) NOT NULL,
    nombre            VARCHAR(50) NOT NULL,
    permite_decimales BOOLEAN     NOT NULL DEFAULT true,
    activo            BOOLEAN     NOT NULL DEFAULT true,
    creado_en         TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT catalog_unidad_medida_codigo_uk UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS catalog_talla (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo         VARCHAR(10) NOT NULL,
    nombre         VARCHAR(50) NOT NULL,
    orden          SMALLINT    NOT NULL DEFAULT 0 CHECK (orden >= 0),
    activo         BOOLEAN     NOT NULL DEFAULT true,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT catalog_talla_codigo_uk UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS catalog_material (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo              VARCHAR(50)   NOT NULL,
    nombre              VARCHAR(150)  NOT NULL,
    categoria_id        BIGINT        NOT NULL REFERENCES catalog_categoria(id) ON DELETE RESTRICT,
    unidad_medida_id    BIGINT        NOT NULL REFERENCES catalog_unidad_medida(id) ON DELETE RESTRICT,
    es_continuo         BOOLEAN       NOT NULL DEFAULT false,
    stock_minimo_global NUMERIC(12, 4) NULL,
    activo              BOOLEAN       NOT NULL DEFAULT true,
    creado_en           TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT catalog_material_codigo_uk UNIQUE (codigo)
);

CREATE TABLE IF NOT EXISTS catalog_producto (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo          VARCHAR(50)   NOT NULL,
    nombre          VARCHAR(150)  NOT NULL,
    descripcion     TEXT          NOT NULL DEFAULT '',
    subcategoria_id BIGINT        NULL REFERENCES catalog_subcategoria(id) ON DELETE RESTRICT,
    tipo            VARCHAR(20)   NOT NULL DEFAULT 'TERMINADO',
    activo          BOOLEAN       NOT NULL DEFAULT true,
    creado_en       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT catalog_producto_codigo_uk UNIQUE (codigo)
);

-- Todo producto stockeable lleva al menos una variante (talla_id NULL = única)
CREATE TABLE IF NOT EXISTS catalog_variante_producto (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    producto_id     BIGINT        NOT NULL REFERENCES catalog_producto(id) ON DELETE RESTRICT,
    talla_id        BIGINT        NULL REFERENCES catalog_talla(id) ON DELETE RESTRICT,
    color           VARCHAR(50)   NOT NULL DEFAULT '',
    sku             VARCHAR(30)   NOT NULL,
    codigo_barras   VARCHAR(50)   NOT NULL DEFAULT '',
    activo          BOOLEAN       NOT NULL DEFAULT true,
    creado_en       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT catalog_variante_producto_sku_uk UNIQUE (sku),
    CONSTRAINT catalog_variante_uk UNIQUE (producto_id, talla_id)
);

CREATE TABLE IF NOT EXISTS catalog_servicio (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre            VARCHAR(150) NOT NULL,
    descripcion       TEXT         NOT NULL DEFAULT '',
    unidad_medida_id  BIGINT       NULL REFERENCES catalog_unidad_medida(id) ON DELETE RESTRICT,
    activo            BOOLEAN      NOT NULL DEFAULT true,
    creado_en         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS catalog_material_categoria_idx
    ON catalog_material (categoria_id, activo);

CREATE INDEX IF NOT EXISTS catalog_producto_subcat_idx
    ON catalog_producto (subcategoria_id, activo);

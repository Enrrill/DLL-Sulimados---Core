-- =============================================================================
-- 07_ventas.sql
-- DDL para las tablas de ventas:
-- Clientes, Pedidos de venta, Líneas de pedido, Cobros multi-moneda y
-- Facturas propias (RF-36 a RF-43).
-- Requiere: 01_nucleo.sql, 03_catalogo.sql, 08_precios.sql y 09_rrhh.sql
-- (las referencias a rrhh y precios son débiles, sin FK).
--
-- Referencias:
--   docs/ddl/06b.7-ventas.md
--   docs/modelo-datos/06.7-ventas.md
--   docs/03-requerimientos-del-sistema.md (RF-36 a RF-43)
-- =============================================================================

CREATE TABLE IF NOT EXISTS sales_cliente (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR(150) NOT NULL,
    telefono       VARCHAR(30)  NOT NULL DEFAULT '',
    correo         VARCHAR(150) NOT NULL DEFAULT '',
    rif            VARCHAR(20)  NULL,  -- NULL = consumidor final
    activo         BOOLEAN      NOT NULL DEFAULT true,
    creado_en      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sales_cliente_nombre_idx ON sales_cliente (nombre);

CREATE TABLE IF NOT EXISTS sales_pedido_venta (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo           VARCHAR(30)   NOT NULL,
    cliente_id       BIGINT        NOT NULL REFERENCES sales_cliente(id) ON DELETE RESTRICT,
    local_id         BIGINT        NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
    estado           VARCHAR(20)   NOT NULL DEFAULT 'COTIZADO',
    moneda           VARCHAR(3)    NOT NULL DEFAULT 'USD',
    total            NUMERIC(14, 2) NOT NULL DEFAULT 0,
    vendedor_id      BIGINT        NULL,  -- referencia débil a hr_trabajador(id)
    confirmado_en    TIMESTAMPTZ   NULL,
    fecha_compromiso DATE          NULL,
    motivo_anulacion VARCHAR(200)  NOT NULL DEFAULT '',
    activo           BOOLEAN       NOT NULL DEFAULT true,
    creado_en        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT sales_pedido_codigo_uk UNIQUE (codigo),
    CONSTRAINT sales_pedido_estado_ck CHECK (
        estado IN ('COTIZADO', 'CONFIRMADO', 'EN_PRODUCCION', 'LISTO',
                   'ENTREGADO', 'FACTURADO', 'ANULADO')
    ),
    CONSTRAINT sales_pedido_moneda_ck CHECK (moneda IN ('USD', 'VES')),
    CONSTRAINT sales_pedido_total_ck CHECK (total >= 0),
    -- Justificación obligatoria al anular (RF-43)
    CONSTRAINT sales_pedido_anulacion_motivo_ck CHECK (
        estado <> 'ANULADO' OR motivo_anulacion <> ''
    )
);
CREATE INDEX IF NOT EXISTS sales_pedido_estado_local_idx ON sales_pedido_venta (estado, local_id);
CREATE INDEX IF NOT EXISTS sales_pedido_cliente_idx ON sales_pedido_venta (cliente_id, creado_en DESC);

CREATE TABLE IF NOT EXISTS sales_linea_pedido (
    id                      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_venta_id         BIGINT        NOT NULL REFERENCES sales_pedido_venta(id) ON DELETE CASCADE,
    tipo_linea              VARCHAR(30)   NOT NULL DEFAULT 'PRODUCTO',
    variante_id             BIGINT        NULL REFERENCES catalog_variante_producto(id) ON DELETE RESTRICT,
    servicio_id             BIGINT        NULL REFERENCES catalog_servicio(id) ON DELETE RESTRICT,
    material_id             BIGINT        NULL REFERENCES catalog_material(id) ON DELETE RESTRICT,
    unidad_medida_id        BIGINT        NULL REFERENCES catalog_unidad_medida(id) ON DELETE RESTRICT,
    medida_cantidad         NUMERIC(12, 4) NULL,
    unidad_medida_medida_id BIGINT        NULL REFERENCES catalog_unidad_medida(id) ON DELETE RESTRICT,
    cantidad                NUMERIC(12, 4) NOT NULL,
    precio_unitario         NUMERIC(14, 2) NOT NULL,  -- snapshot al cotizar (RF-39)
    moneda                  VARCHAR(3)    NOT NULL DEFAULT 'USD',
    item_precio_id          BIGINT        NULL,  -- referencia débil a pricing_item_matriz_precios(id)
    nota                    VARCHAR(300)  NOT NULL DEFAULT '',
    activo                  BOOLEAN       NOT NULL DEFAULT true,
    creado_en               TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT sales_linea_tipo_ck CHECK (
        tipo_linea IN ('PRODUCTO', 'PRODUCTO_PERSONALIZADO', 'SERVICIO_PURO')
    ),
    CONSTRAINT sales_linea_producto_variante_ck CHECK (
        tipo_linea NOT IN ('PRODUCTO', 'PRODUCTO_PERSONALIZADO') OR variante_id IS NOT NULL
    ),
    CONSTRAINT sales_linea_servicio_ck CHECK (
        tipo_linea <> 'SERVICIO_PURO' OR servicio_id IS NOT NULL
    ),
    CONSTRAINT sales_linea_personalizado_material_ck CHECK (
        tipo_linea <> 'PRODUCTO_PERSONALIZADO' OR material_id IS NOT NULL
    ),
    CONSTRAINT sales_linea_medida_um_ck CHECK (
        (medida_cantidad IS NULL AND unidad_medida_medida_id IS NULL)
        OR (medida_cantidad IS NOT NULL AND unidad_medida_medida_id IS NOT NULL)
    ),
    CONSTRAINT sales_linea_cantidad_ck CHECK (cantidad > 0),
    CONSTRAINT sales_linea_precio_ck CHECK (precio_unitario >= 0),
    CONSTRAINT sales_linea_moneda_ck CHECK (moneda IN ('USD', 'VES'))
);
CREATE INDEX IF NOT EXISTS sales_linea_pedido_idx ON sales_linea_pedido (pedido_venta_id);

-- Cobros parciales multi-moneda (RF-42); activo = false + anulado_en = cobro anulado
CREATE TABLE IF NOT EXISTS sales_cobro (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_venta_id  BIGINT        NOT NULL REFERENCES sales_pedido_venta(id) ON DELETE RESTRICT,
    monto            NUMERIC(14, 2) NOT NULL,
    moneda           VARCHAR(3)    NOT NULL DEFAULT 'USD',
    metodo           VARCHAR(20)   NOT NULL,
    referencia       VARCHAR(100)  NOT NULL DEFAULT '',
    tasa_aplicada_id BIGINT        NULL REFERENCES core_tasa_cambio(id) ON DELETE RESTRICT,
    fecha            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    anulado_en       TIMESTAMPTZ   NULL,
    activo           BOOLEAN       NOT NULL DEFAULT true,
    creado_en        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT sales_cobro_monto_ck CHECK (monto > 0),
    CONSTRAINT sales_cobro_moneda_ck CHECK (moneda IN ('USD', 'VES')),
    CONSTRAINT sales_cobro_metodo_ck CHECK (
        metodo IN ('EFECTIVO', 'PUNTO', 'TRANSFERENCIA', 'DIVISA')
    ),
    -- Un cobro en Bs. guarda la tasa aplicada
    CONSTRAINT sales_cobro_tasa_bs_ck CHECK (
        moneda <> 'VES' OR tasa_aplicada_id IS NOT NULL
    )
);
CREATE INDEX IF NOT EXISTS sales_cobro_pedido_idx ON sales_cobro (pedido_venta_id);

-- Factura propia con correlativo por (tipo, local, año) (RF-40, RF-43)
CREATE TABLE IF NOT EXISTS sales_factura (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_venta_id  BIGINT        NOT NULL REFERENCES sales_pedido_venta(id) ON DELETE RESTRICT,
    local_id         BIGINT        NOT NULL REFERENCES locales(id) ON DELETE RESTRICT,
    numero           VARCHAR(20)   NOT NULL,
    anio             SMALLINT      NOT NULL CHECK (anio >= 0),
    tipo             VARCHAR(10)   NOT NULL DEFAULT 'PROPIA',
    estado           VARCHAR(10)   NOT NULL DEFAULT 'EMITIDA',
    total            NUMERIC(14, 2) NOT NULL,
    moneda           VARCHAR(3)    NOT NULL DEFAULT 'USD',
    fecha_emision    DATE          NOT NULL DEFAULT CURRENT_DATE,
    motivo_anulacion VARCHAR(200)  NOT NULL DEFAULT '',
    emitida_por_id   BIGINT        NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    activo           BOOLEAN       NOT NULL DEFAULT true,
    creado_en        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    actualizado_en   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT sales_factura_correlativo_uk UNIQUE (tipo, local_id, anio, numero),
    CONSTRAINT sales_factura_tipo_ck CHECK (tipo IN ('PROPIA', 'FISCAL')),
    CONSTRAINT sales_factura_estado_ck CHECK (estado IN ('EMITIDA', 'ANULADA')),
    CONSTRAINT sales_factura_total_ck CHECK (total >= 0),
    CONSTRAINT sales_factura_moneda_ck CHECK (moneda IN ('USD', 'VES')),
    CONSTRAINT sales_factura_anulacion_ck CHECK (
        estado <> 'ANULADA' OR motivo_anulacion <> ''
    )
);
CREATE INDEX IF NOT EXISTS sales_factura_repo_idx ON sales_factura (tipo, local_id, fecha_emision);

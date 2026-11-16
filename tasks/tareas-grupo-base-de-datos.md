# DLL Sublimados — Asignación de Tareas y Flujos del Grupo de Base de Datos

Documento operativo para la distribución del trabajo del **Grupo de Base de Datos**, diseñado para permitir el desarrollo en paralelo de los 4 integrantes sin conflictos de Git ni colisiones en el código.

---

## 👥 Resumen de Integrantes, Flujos y Ramas

| Integrante | Flujo / Dominio | Apps Django | Rama Git Asignada |
| :--- | :--- | :--- | :--- |
| **Enrrill (Yo)** | Núcleo, Auditoría y Documentación | `core`, `audit`, `documents` | `feature/db-core-audit-enrrill` |
| **Gaby** | Catálogo e Inventario Multi-local | `catalog`, `inventory` | `feature/db-catalog-inventory-gaby` |
| **Luis** | Abastecimiento y Taller de Producción | `purchasing`, `production` | `feature/db-purchasing-production-luis` |
| **Pablo** | Comercial, Precios y Recursos Humanos | `sales`, `pricing`, `hr` | `feature/db-sales-pricing-hr-pablo` |

---

## 🛡️ Reglas de Oro para Trabajar en Paralelo (Cero Colisiones)

1. **Aislamiento de Archivos:** Cada integrante trabaja **únicamente** en los archivos de sus módulos asignados (`backend/apps/<app>/models.py`, `admin.py`), sus DDLs en `database/` y sus seeders en `database/seeders/`. Nadie modifica archivos de otra app.
2. **Relaciones Foráneas por String:** Al definir `ForeignKey` o `ManyToManyField` que apunten a modelos de otro compañero, usar **siempre** la referencia en string:
   ```python
   local = models.ForeignKey('core.Local', on_delete=models.PROTECT, related_name='...')
   producto = models.ForeignKey('catalog.Producto', on_delete=models.CASCADE, related_name='...')
   ```
   *Esto elimina dependencias circulares y permite compilar y migrar sin esperar a que el compañero termine su rama.*
3. **Estándar Obligatorio de Modelos Django:**
   - Heredar de `backend.common.base_models.TimeStampedModel` (`creado_en`, `actualizado_en`) y `backend.common.base_models.ActivoMixin` (`activo = models.BooleanField(default=True)`).
   - Definir explícitamente `class Meta:` con `db_table` en snake_case y nombres plurales/singulares legibles en español:
     ```python
     class Meta:
         db_table = 'inventario_stock'
         verbose_name = 'stock'
         verbose_name_plural = 'stocks'
     ```
   - Tipos de datos estandarizados:
     - Montos monetarios: `models.DecimalField(max_digits=14, decimal_places=2)` + campo `moneda` ('USD', 'VES').
     - Cantidades físicas: `models.DecimalField(max_digits=12, decimal_places=4)`.
     - Porcentajes / factores: `models.DecimalField(max_digits=5, decimal_places=4)`.
4. **Commits y PR:**
   - Seguir estrictamente Conventional Commits (`feat(core): ...`, `feat(catalog): ...`).
   - Todo trabajo se integra hacia `develop` vía Pull Request revisado por el Grupo de Gestión.

---

## 📋 Tareas Detalladas por Integrante

---

### 1. Enrrill (Yo)
**Flujo:** Núcleo, Seguridad, Auditoría y Documentación Transversal  
**Rama:** `feature/db-core-audit-enrrill`  
**Apps:** `backend/apps/core/`, `backend/apps/audit/`, `backend/apps/documents/`

#### 📂 Archivos de Trabajo
- `backend/apps/core/models.py` (completar modelos faltantes)
- `backend/apps/core/admin.py`
- `backend/apps/audit/models.py`
- `backend/apps/audit/admin.py`
- `backend/apps/documents/models.py`
- `backend/apps/documents/admin.py`
- `database/01_nucleo.sql`
- `database/02_auditoria.sql`
- `database/10_documentos.sql`
- `database/seeders/01_seed_nucleo.sql`

#### 📝 Tareas de Modelado y DDL
- [ ] **Módulo `core`:**
  - [ ] Verificar y ajustar `Local` (`locales`) y `Usuario` (`usuarios`) ya existentes.
  - [ ] Implementar modelo `TasaCambio` (`core_tasa_cambio`): fecha de vigencia, tasa USD $\rightarrow$ Bs (`dolares_a_bs`), registrado por (`ForeignKey('core.Usuario')`).
  - [ ] Implementar modelo `ContadorCorrelativo` (`core_contador_correlativo`): tipo de comprobante (factura, nota_entrega, orden_produccion, etc.), prefijo, número actual, `local` (`ForeignKey('core.Local')`), control de concurrencia.
- [ ] **Módulo `audit`:**
  - [ ] Implementar modelo `BitacoraAccion` (`audit_bitacora_accion`): fecha (`creado_en`), usuario (`ForeignKey('core.Usuario')`), local (`ForeignKey('core.Local')`), acción (`INSERT`, `UPDATE`, `DELETE`, `LOGIN`, `APROBACION`), entidad (nombre de la tabla), entidad_id, datos_antes (JSONField), datos_despues (JSONField), ip_origen.
  - [ ] Implementar modelo `BitacoraStock` (`audit_bitacora_stock`): fecha, tipo_movimiento (ENTRADA, SALIDA, AJUSTE, TRANSFERENCIA), lote_id, producto_id, cantidad, local_origen_id, local_destino_id, usuario_id, motivo.
- [ ] **Módulo `documents`:**
  - [ ] Implementar modelo `PlantillaDocumento` (`documents_plantilla`): código, nombre, tipo (FACTURA, NOTA_ENTREGA, ORDEN_PRODUCCION, PRESUPUESTO), contenido_html (con variables dinámicas Jinja/Django), version, activo.
  - [ ] Implementar modelo `Documento` (`documents_documento`): correlativo, plantilla (`ForeignKey`), entidad_tipo, entidad_id, generado_por (`ForeignKey('core.Usuario')`), fecha_emision, hash_seguridad, url_archivo.

#### 🌱 Seeders Iniciales (`database/seeders/01_seed_nucleo.sql`)
- [ ] Los 3 locales de la empresa:
  - `L01`: Local Principal (Sede Central - Impresión y Corte)
  - `L02`: Local 2 (Sucursal 2 - Planchado y Confección)
  - `L03`: Local 3 (Sucursal 3 - Diseño y Acabado)
- [ ] Superadministrador (`admin`) y usuarios de prueba para cada rol (`gerente_l1`, `operario_corte`, `vendedor_l1`).
- [ ] Tasa de cambio oficial de arranque (USD/Bs).
- [ ] Registros iniciales de contadores correlativos por local (FAC-000001, NE-000001, OP-000001).
- [ ] Plantillas base HTML para Factura, Nota de Entrega y Presupuesto Comercial.

---

### 2. Gaby
**Flujo:** Catálogo Maestro e Inventario Multi-local  
**Rama:** `feature/db-catalog-inventory-gaby`  
**Apps:** `backend/apps/catalog/`, `backend/apps/inventory/`

#### 📂 Archivos de Trabajo
- `backend/apps/catalog/models.py`
- `backend/apps/catalog/admin.py`
- `backend/apps/inventory/models.py`
- `backend/apps/inventory/admin.py`
- `database/03_catalogo.sql`
- `database/04_inventario.sql`
- `database/seeders/02_seed_catalogo_inventario.sql`

#### 📝 Tareas de Modelado y DDL
- [ ] **Módulo `catalog`:**
  - [ ] Implementar `Categoria` y `Subcategoria` (`catalog_categoria`, `catalog_subcategoria`).
  - [ ] Implementar `UnidadMedida` (`catalog_unidad_medida`): código (`m`, `kg`, `pza`, `rollo`, `cm`), nombre, permite_decimales.
  - [ ] Implementar `Talla` (`catalog_talla`): código, nombre, orden.
  - [ ] Implementar `Material` (`catalog_material`): código, nombre, categoría, unidad_medida (`ForeignKey`), es_continuo (boolean para telas/rollos), stock_minimo_global.
  - [ ] Implementar `Producto` (`catalog_producto`): código, nombre, descripción, subcategoría, tipo (`TERMINADO`, `SEMITERMINADO`, `SERVICIO`).
  - [ ] Implementar `VarianteProducto` (`catalog_variante_producto`): producto (`ForeignKey`), talla (`ForeignKey`), color, sku, codigo_barras.
  - [ ] Implementar `Servicio` (`catalog_servicio`): nombre, descripción, unidad_medida.
- [ ] **Módulo `inventory`:**
  - [ ] Implementar `Stock` (`inventory_stock`): local (`ForeignKey('core.Local')`), variante (`ForeignKey`), material (`ForeignKey`, null=True), cantidad_disponible, cantidad_reservada.
  - [ ] Implementar `Lote` (`inventory_lote`): material (`ForeignKey`), local (`ForeignKey('core.Local')`), numero_lote, longitud_inicial (para rollos de tela/vinil), longitud_actual, costo_unitario, fecha_vencimiento/ingreso.
  - [ ] Implementar `MovimientoStock` (`inventory_movimiento_stock`): tipo (`ENTRADA`, `SALIDA`, `TRANSFERENCIA`), local, cantidad, referencia.
  - [ ] Implementar `GuiaTransferencia` y `LineaGuiaTransferencia` (`inventory_guia_transferencia`, `inventory_linea_guia`): tracking_code, local_origen, local_destino, estado (`BORRADOR`, `EN_TRANSITO`, `RECIBIDA`, `RECHAZADA`).
  - [ ] Implementar `NivelMinimo` (`inventory_nivel_minimo`): local, producto/material, cantidad_minima_alerta.

#### 🌱 Seeders Iniciales (`database/seeders/02_seed_catalogo_inventario.sql`)
- [ ] Unidades de medida oficiales: Metros (`m`), Centímetros (`cm`), Kilos (`kg`), Rollos (`rollo`), Piezas (`pza`), Unidades (`und`).
- [ ] Tallas: `XS`, `S`, `M`, `L`, `XL`, `XXL` y tallas infantiles (`4`, `6`, `8`, `10`, `12`, `14`, `16`).
- [ ] Categorías y Subcategorías: Telas Textiles, Tintas y Químicos, Viniles, Papel de Sublimación, Confección Terminada.
- [ ] Catálogo inicial de materiales: Rollo Microdurazno Blanco 1.60m, Tinta Sublimación Cyan/Magenta/Yellow/Black, Vinil Textil Poliuretano, Papel Sublimación 100gr.
- [ ] Catálogo de productos: Franela Deportiva Cuello Redondo Sublimada, Taza Blanca 11oz, Gorra Trucker.
- [ ] Niveles mínimos de stock para alertas automáticas en L01, L02 y L03.

---

### 3. Luis
**Flujo:** Abastecimiento (Compras) y Taller de Producción Multi-local  
**Rama:** `feature/db-purchasing-production-luis`  
**Apps:** `backend/apps/purchasing/`, `backend/apps/production/`

#### 📂 Archivos de Trabajo
- `backend/apps/purchasing/models.py`
- `backend/apps/purchasing/admin.py`
- `backend/apps/production/models.py`
- `backend/apps/production/admin.py`
- `database/05_compras.sql`
- `database/06_produccion.sql`
- `database/seeders/03_seed_compras_produccion.sql`

#### 📝 Tareas de Modelado y DDL
- [ ] **Módulo `purchasing`:**
  - [ ] Implementar `Empresa` y `Proveedor` (`purchasing_empresa`, `purchasing_proveedor`): rif, razon_social, direccion, telefono, contacto, calificacion.
  - [ ] Implementar `HistorialPrecioProveedor` (`purchasing_historial_precio`): proveedor, material/producto, precio_unitario, moneda, fecha.
  - [ ] Implementar `OrdenCompra` y `LineaOrdenCompra` (`purchasing_orden_compra`, `purchasing_linea_orden`): numero_orden, proveedor, local_destino (`ForeignKey('core.Local')`), estado (`SOLICITADA`, `APROBADA`, `RECIBIDA`, `CANCELADA`), moneda, total.
  - [ ] Implementar `RecepcionCompra` y `LineaRecepcionCompra`: orden_compra, local, fecha_recepcion, numero_guia_proveedor, observaciones.
  - [ ] Implementar `FacturaCompra`: proveedor, numero_factura_control, fecha_emision, monto_total, tasa_cambio_aplicada.
- [ ] **Módulo `production`:**
  - [ ] Implementar `Maquina` (`production_maquina`): codigo, nombre, tipo (`PLOTTER`, `CALANDRA`, `PLANCHA_TRANSFER`, `COSTURA_RECTA`, `OVERLOCK`), local (`ForeignKey('core.Local')`), horas_operativas, estado (`OPERATIVA`, `EN_MANTENIMIENTO`, `FUERA_SERVICIO`).
  - [ ] Implementar `OrdenProduccion` (`production_orden_produccion`): codigo_correlativo, pedido_venta_id (opcional), producto (`ForeignKey('catalog.Producto')`), cantidad, fecha_inicio, fecha_compromiso, estado (`PLANIFICADA`, `EN_PROCESO`, `PAUSADA`, `TERMINADA`, `CANCELADA`).
  - [ ] Implementar `PasoProduccion` (`production_paso_produccion`): orden_produccion, orden_secuencia (1, 2, 3), local_ejecucion (`ForeignKey('core.Local')` - ej. L1 corte, L2 planchado), descripcion_tarea, estado (`PENDIENTE`, `EN_PROCESO`, `COMPLETADO`).
  - [ ] Implementar `ConsumoMaterial` (`production_consumo_material`): paso_produccion, lote (`ForeignKey('inventory.Lote')`), cantidad_consumida, es_desperdicio (boolean), motivo_merma.
  - [ ] Implementar `OperacionMaquina` (`production_operacion_maquina`): maquina, paso_produccion, operador (`ForeignKey('core.Usuario')`), hora_inicio, hora_fin, resultado.

#### 🌱 Seeders Iniciales (`database/seeders/03_seed_compras_produccion.sql`)
- [ ] Proveedores de insumos registrados (telas, tintas, repuestos plóter).
- [ ] Parque de máquinas asignadas a cada local:
  - **L01:** Plóter de Sublimación Mimaki/Epson 1.60m, Cortadora Láser Textil.
  - **L02:** Plancha Térmica Industrial 80x100cm, Máquina de Coser Overlock 5 Hilos, Máquina Recta.
  - **L03:** Estampadora Combo 8 en 1 (Gorras, Tazas, Platos), Plancha de Transfer manual.
- [ ] Datos de prueba de órdenes de compra y órdenes de producción piloto demostrando el salto de ruta multi-local L1 $\rightarrow$ L2.

---

### 4. Pablo
**Flujo:** Comercialización (Ventas), Precios y Personal (RRHH)  
**Rama:** `feature/db-sales-pricing-hr-pablo`  
**Apps:** `backend/apps/sales/`, `backend/apps/pricing/`, `backend/apps/hr/`

#### 📂 Archivos de Trabajo
- `backend/apps/sales/models.py`
- `backend/apps/sales/admin.py`
- `backend/apps/pricing/models.py`
- `backend/apps/pricing/admin.py`
- `backend/apps/hr/models.py`
- `backend/apps/hr/admin.py`
- `database/07_ventas.sql`
- `database/08_precios.sql`
- `database/09_rrhh.sql`
- `database/seeders/04_seed_ventas_precios_rrhh.sql`

#### 📝 Tareas de Modelado y DDL
- [ ] **Módulo `sales`:**
  - [ ] Implementar `Cliente` (`sales_cliente`): tipo_documento (`V`, `E`, `J`, `G`), numero_documento, nombre_razon_social, direccion, telefono, correo, limite_credito.
  - [ ] Implementar `PedidoVenta` (`sales_pedido_venta`): numero_pedido, cliente, local_venta (`ForeignKey('core.Local')`), vendedor (`ForeignKey('hr.Trabajador')`), estado (`COTIZADO`, `CONFIRMADO`, `EN_PRODUCCION`, `LISTO`, `ENTREGADO`, `FACTURADO`, `ANULADO`), moneda, total_neto, iva, total_bruto.
  - [ ] Implementar `LineaPedido` (`sales_linea_pedido`): pedido, producto (`ForeignKey('catalog.Producto')`), variante (`ForeignKey('catalog.VarianteProducto', null=True)`), cantidad, precio_unitario, subtotal.
  - [ ] Implementar `Cobro` (`sales_cobro`): pedido, metodo_pago (`EFECTIVO_USD`, `PAGO_MOVIL`, `TRANSFERENCIA_BS`, `PUNTO_VENTA`, `ZELLE`), monto_moneda_original, tasa_cambio_aplicada, monto_usd_equivalente, referencia_bancaria.
  - [ ] Implementar `FacturaVenta` (`sales_factura`): numero_control, pedido, fecha_emision, total_usd, total_bs.
- [ ] **Módulo `pricing`:**
  - [ ] Implementar `ParametroFormula` (`pricing_parametro_formula`): clave (`MARGEN_GANANCIA`, `IVA`, `DESCUENTO_MAYORISTA`), valor_numerico, descripcion.
  - [ ] Implementar `ItemMatrizPrecios` (`pricing_matriz_precios`): producto/servicio, unidad_medida, rango_cantidad_min, rango_cantidad_max, precio_base, precio_final_sugerido.
  - [ ] Implementar `HistorialCambioPrecio` (`pricing_historial_cambio`): matriz_item, precio_anterior, precio_nuevo, modificado_por (`ForeignKey('core.Usuario')`), justificacion.
- [ ] **Módulo `hr`:**
  - [ ] Implementar `Trabajador` (`hr_trabajador`): cedula, nombres, apellidos, cargo (`VENDEDOR`, `OPERARIO_CORTE`, `OPERARIO_PLANCHA`, `DISENADOR`, `GERENTE`), telefono, correo, fecha_ingreso.
  - [ ] Implementar `TrabajadorLocal` (`hr_trabajador_local`): trabajador, local (`ForeignKey('core.Local')`), porcentaje_comision_venta, es_local_principal.

#### 🌱 Seeders Iniciales (`database/seeders/04_seed_ventas_precios_rrhh.sql`)
- [ ] Clientes base: Cliente genérico "Consumidor Final" y 2 clientes corporativos de prueba.
- [ ] Parámetros base de fórmulas comerciales:
  - Margen de ganancia: `1.30` (+30%).
  - Alícuota de impuesto: `0.16` (16% IVA).
  - Factor de conversión estándar.
- [ ] Matriz de precios inicial para prendas estándar y servicios de sublimación por metro.
- [ ] Fichas de trabajadores y vendedores asignados a los locales L01, L02 y L03.

---

## 🚀 Flujo de Trabajo Git Paso a Paso para Cada Integrante

### 1. Ubicarse en su rama asignada
```bash
# Ejemplo para Enrrill:
git checkout feature/db-core-audit-enrrill

# Ejemplo para Gaby:
git checkout feature/db-catalog-inventory-gaby

# Ejemplo para Luis:
git checkout feature/db-purchasing-production-luis

# Ejemplo para Pablo:
git checkout feature/db-sales-pricing-hr-pablo
```

### 2. Implementar modelos y verificar calidad
```bash
# Verificar que Django reconozca los modelos y sintaxis
python manage.py check

# Generar y aplicar migraciones de prueba en local
python manage.py makemigrations
python manage.py migrate

# Validar estilo de código
flake8 backend/
```

### 3. Guardar cambios (Conventional Commits)
```bash
git add backend/apps/<tu-modulo>/ database/
git commit -m "feat(<modulo>): implementa modelos de datos y scripts ddl" -m "- crea tablas con class Meta db_table explícito" -m "- agrega seeder inicial con datos base del negocio"
git push origin <nombre-de-tu-rama>
```

### 4. Abrir Pull Request
- Crear el PR apuntando hacia `develop`.
- Notificar al Grupo de Gestión para su revisión y merge.

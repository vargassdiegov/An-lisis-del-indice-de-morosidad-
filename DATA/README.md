# Data — Datos del proyecto IMORA TC

## Archivos

| Archivo | Formato | Descripción |
|---|---|---|
| `dataset.xls` | Excel (.xls) | Dataset principal con series mensuales de IMORA TC y 27 variables macroeconómicas |

---

## Descripción del dataset

- **Hoja:** `dataset`
- **Frecuencia:** Mensual
- **Período:** ~2010–2025 (ver rango exacto en notebook)
- **Fuente:** Banco de México (Banxico), INEGI, CNBV

### Variable dependiente

| Variable | Descripción |
|---|---|
| `IMORA.TC` | Índice de Morosidad Ajustado — Tarjetas de Crédito (banca múltiple, sistema) |
| `IMORA.TC.BBVA` | IMORA TC — BBVA |
| `IMORA.TC.Santander` | IMORA TC — Santander |
| `IMORA.TC.Banorte` | IMORA TC — Banorte |

### Variables macroeconómicas (predictores)

| Variable | Descripción |
|---|---|
| `CETE28` | Tasa de rendimiento CETES 28 días |
| `t.fija.b5` | Tasa fija bono gubernamental 5 años |
| `t.fija.b10` | Tasa fija bono gubernamental 10 años |
| `udib3` | Tasa real UDIBONO 3 años |
| `udib10` | Tasa real UDIBONO 10 años |
| `PIB` | Crecimiento anual del PIB |
| `t.desocupacion` | Tasa de desocupación (ENOE) |
| `INPC` | Índice Nacional de Precios al Consumidor (variación) |
| `TIIE` | Tasa de Interés Interbancaria de Equilibrio |
| `ahorro.bruto` | Ahorro bruto del sector privado |
| `IMCP` | Indicador Mensual del Consumo Privado |
| `IGAE` | Indicador Global de Actividad Económica |
| `tipo.de.cambio` | Tipo de cambio MXN/USD |
| `IPC.Var.BMV` | Variación del IPC de la Bolsa Mexicana de Valores |
| `t.objetivo` | Tasa objetivo del Banco de México |
| `cartera.consumo.var` | Variación de la cartera de crédito al consumo |
| `tarjetas.var` | Variación del saldo en tarjetas de crédito |
| `rem.comercio.real.var` | Variación real de remuneraciones en comercio |
| `remesas.var` | Variación de remesas recibidas |
| `infl.subyacente` | Inflación subyacente |
| `consumo.privado.var` | Variación del consumo privado |
| `m1.var` | Variación del agregado monetario M1 |
| `m2.var` | Variación del agregado monetario M2 |
| `balance.publico` | Balance del sector público (% PIB) |
| `tc.utilizadas.var` | Variación de tarjetas de crédito utilizadas |
| `cuentas.tc.var` | Variación del número de cuentas de tarjeta de crédito |
| `empleo.imss.var` | Variación del empleo formal (trabajadores asegurados IMSS) |

---

## Notas de preprocesamiento

- Los valores faltantes (`NA`) se imputan con **promedio móvil centrado** (ventana `k=3`) seguido de interpolación lineal y forward/backward fill.
- La variable dependiente `IMORA.TC` se transforma a **logit**: `Score = log(PD / (1 - PD))`, con recorte en `[1e-6, 1 - 1e-6]`.
- Todos los predictores se estandarizan con `scale()` (media 0, desviación estándar 1).
- **No se usan variables rezagadas (lags).**
- **No se transforman las variables independientes** (solo estandarización).

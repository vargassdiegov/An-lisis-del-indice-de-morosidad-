# Notebooks — Código del Modelo IMORA TC

## Archivos

| Notebook | Descripción |
|---|---|
| `modelo_pd_imora_tc.ipynb` | Notebook principal: carga de datos, preprocesamiento, modelado, validación y diagnóstico |

---

## Contenido del notebook principal

El notebook está organizado en las siguientes secciones:

| Sección | Descripción |
|---|---|
| **1. Librerías y configuración** | Importación de pandas, numpy, matplotlib, seaborn, scipy, statsmodels |
| **2. Carga de datos** | Lectura del dataset `.xls`, limpieza de columnas, conversión de fechas |
| **3. DataFrame de trabajo (d2)** | Selección de las 27 variables macro + variable dependiente IMORA TC |
| **4. Imputación** | Promedio móvil centrado (k=3) + interpolación lineal + ffill/bfill |
| **5. Transformación logit** | `Score = log(PD / (1 - PD))` sobre IMORA TC recortado |
| **6. Análisis univariado** | Gráficas de series temporales de variables seleccionadas |
| **7. Matriz de correlación** | Heatmap de correlación entre las 27 variables |
| **8. Generación de 10 modelos** | MCO en ventanas 2013–2025 y 2018–2025 (completo, reducido, stepwise) |
| **9. Validación estadística** | Shapiro-Wilk, Breusch-Pagan, Durbin-Watson (umbral p > 0.05 simultáneo) |
| **10. Corrección Prais-Winsten** | Aplicada sobre modelos con DW < 1.5 (autocorrelación detectada) |
| **11. Modelo final** | Selección, coeficientes estandarizados e interpretación económica |

---

## Cómo ejecutar

### En Google Colab (configuración original)
1. Subir `data/dataset.xls` a `/content/`
2. Abrir el notebook en Colab
3. Ejecutar todas las celdas en orden

### En Jupyter local
```bash
pip install pandas numpy matplotlib seaborn scipy statsmodels openpyxl xlrd
jupyter notebook notebooks/modelo_pd_imora_tc.ipynb
```

> **Importante:** Cambiar la variable `ruta` en la celda de carga de datos a la ruta local correcta:
> ```python
> ruta = "../data/dataset.xls"   # Relativa desde /notebooks/
> ```

---

## Dependencias

```
pandas
numpy
matplotlib
seaborn
scipy
statsmodels
openpyxl
xlrd >= 2.0.1
```

---

## Próximos notebooks sugeridos

| Notebook sugerido | Propósito |
|---|---|
| `02_exploratorio_variables.ipynb` | EDA profundo por variable: distribuciones, outliers, estacionalidad |
| `03_seleccion_variables.ipynb` | Comparación sistemática de criterios de selección (AIC, BIC, VIF) |
| `04_prais_winsten_detalle.ipynb` | Análisis comparativo MCO vs. Prais-Winsten por modelo |
| `05_modelo_final_reporte.ipynb` | Notebook limpio de presentación con resultados finales |

Modelo Macroeconómico para Cuantificar el Incumplimiento de Pago en Tarjetas de Crédito (IMORA TC)
Autor: Vargas Santana Diego  
Institución: IBERO Ciudad de México — Ciencia de Datos  
Asesor: Reyes García Jorge Luis  
Sinodales: Peñaloza Velasco Lizbeth · Díaz Infante Pesquera  
***Descripción
Este repositorio contiene el desarrollo completo de un modelo de regresión lineal múltiple para cuantificar el Índice de Morosidad Ajustado (IMORA) en el portafolio de tarjetas de crédito de la banca múltiple en México, utilizando variables macroeconómicas como predictores.
La variable dependiente es transformada mediante logit (log(PD / (1 - PD))) y los predictores son estandarizados con scale(). Se evaluaron 10 modelos (mod1–mod10) en diferentes ventanas temporales (2013–2025 y 2018–2025) con tres estrategias de selección de variables: completa (27 vars), reducción manual y stepwise bidireccional (criterio AIC).
Hipótesis principal
Las variables macroeconómicas que caracterizan el ciclo económico en México (tasas de interés de corto plazo, condiciones del mercado laboral y nivel de ahorro bruto) tienen un efecto estadísticamente significativo sobre la probabilidad de incumplimiento en la cartera de tarjetas de crédito de la banca múltiple.
***Estructura del repositorio
imora-tc-model/
│
├── data/
│   └── dataset.xls               # Dataset principal (32 variables, series mensuales)
│
├── notebooks/
│   └── modelo_pd_imora_tc.ipynb  # Notebook principal: carga, modelado y validación
│
├── docs/
│   └── trabajo_escrito.docx      # Documento académico completo (tesis/trabajo final)
│
├── outputs/
│   ├── figures/                  # Gráficas generadas (ver README interno)
│   └── tables/
│       └── matriz_correlacion.xlsx  # Matriz de correlación de las 27 variables macro
│
└── README.md
***Variables del modelo
Categoría	Variables
Tasas de interés	CETE28, t.fija.b5, t.fija.b10, udib3, udib10, TIIE, t.objetivo
Actividad económica	PIB, IGAE, IMCP, consumo.privado.var
Mercado laboral	t.desocupacion, empleo.imss.var
Precios	INPC, infl.subyacente
Sector financiero	ahorro.bruto, balance.publico, m1.var, m2.var
Mercados	tipo.de.cambio, IPC.Var.BMV
Crédito	cartera.consumo.var, tarjetas.var, tc.utilizadas.var, cuentas.tc.var
Remesas / comercio	remesas.var, rem.comercio.real.var
***Pipeline del modelo
Raw data (IMORA TC + 27 variables macro)
        ↓
Imputación con promedio móvil (k=3)
        ↓
Transformación logit de la variable dependiente
        ↓
Estandarización con scale()
        ↓
Estimación MCO (10 modelos × 2 ventanas temporales)
        ↓
Validación simultánea:
  • Shapiro-Wilk  (normalidad de residuos)
  • Breusch-Pagan (homocedasticidad)
  • Durbin-Watson (autocorrelación)
        ↓
Corrección Prais-Winsten (si DW falla)
        ↓
Modelo final seleccionado
***Requisitos
pip install pandas numpy matplotlib seaborn scipy statsmodels openpyxl xlrd
> El notebook fue desarrollado originalmente en Google Colab. Ajustar la ruta del dataset en la celda de carga de datos.
***Resultados clave
Se evaluaron 10 modelos en ventanas 2013–2025 y 2018–2025.
Los modelos mod3, mod4 y mod10 mostraron el mejor desempeño en Shapiro-Wilk y Breusch-Pagan antes de la corrección de autocorrelación.
Todos los modelos candidatos presentaron estadístico Durbin-Watson entre 0.4–1.1, indicando autocorrelación positiva.
Se implementó estimación Prais-Winsten como corrección.
> Para visualizaciones generadas: ver outputs/figures/README.md
***Referencia académica
> Vargas Santana, D. (2026). Modelo macroeconómico para cuantificar el incumplimiento de pago en el portafolio de tarjetas de crédito de las instituciones de banca múltiple en México. IBERO Ciudad de México.
> 

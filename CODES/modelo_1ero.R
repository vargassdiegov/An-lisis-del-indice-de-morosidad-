# ============================================================
# MODELO PD - IMORA TC 
# ============================================================

# ── LIBRERÍAS ────────────────────────────────────────────────
library(readxl)
library(corrplot)
library(lmtest)
library(zoo)
library(ggplot2)
library(dplyr)
library(scales)
library(reshape2)
library(tidyr)

# ── CARGA DE DATOS ───────────────────────────────────────────
ruta <- "~/Desktop/Ciencia de Datos/PROYECTO/dataset.xls"

col_types_vec <- c("date", rep("numeric", 31))
d1 <- read_excel(ruta, sheet = "dataset", col_types = col_types_vec)

names(d1)[names(d1) == "t.objetivo "] <- "t.objetivo"
d1$Fecha <- as.Date(d1$Fecha)

cat("Rango de fechas:", format(min(d1$Fecha)), "a", format(max(d1$Fecha)), "\n")

# ============================================================
# 1. DATA FRAME — 27 variables macro
# ============================================================
vars_macro <- c("CETE28", "t.fija.b5", "t.fija.b10",
                "udib3", "udib10", "PIB",
                "t.desocupacion", "INPC", "TIIE",
                "ahorro.bruto", "IMCP", "IGAE",
                "tipo.de.cambio", "IPC.Var.BMV", "t.objetivo",
                "cartera.consumo.var", "tarjetas.var",
                "rem.comercio.real.var", "remesas.var",
                "infl.subyacente", "consumo.privado.var",
                "m1.var", "m2.var", "balance.publico",
                "tc.utilizadas.var", "cuentas.tc.var",
                "empleo.imss.var")

d2 <- data.frame(Fecha = d1$Fecha, PD = d1$IMORA.TC)
d2 <- cbind(d2, d1[, vars_macro])
for (v in vars_macro) d2[[v]] <- as.numeric(d2[[v]])

# ============================================================
# 2. IMPUTACIÓN CON PROMEDIO MÓVIL
# ============================================================
imputar_promedio_movil <- function(x, k = 3) {
  if (all(!is.na(x))) return(x)
  ma <- rollmean(x, k = k, fill = NA, align = "center")
  x[is.na(x)] <- ma[is.na(x)]
  x <- na.approx(x, na.rm = FALSE)
  x <- na.locf(x, na.rm = FALSE)
  x <- na.locf(x, fromLast = TRUE, na.rm = FALSE)
  return(x)
}

for (v in vars_macro) d2[[v]] <- imputar_promedio_movil(d2[[v]])
cat("NAs después de imputación:", sum(is.na(d2)), "\n")

# ============================================================
# 3. VARIABLE DEPENDIENTE:
# ============================================================
d2$Score <- log(d2$PD / (1 - d2$PD))

# ============================================================
# 4. ANÁLISIS UNIVARIADO 
# ============================================================
par(mfrow = c(1, 2))
plot(d2$PIB,    type = "l", main = "PIB")
plot(d2$CETE28, type = "l", main = "CETE28")
par(mfrow = c(1, 1))

# ============================================================
# 5. DATASET LIMPIO
# ============================================================
d2_clean_full <- d2[complete.cases(d2), ]
cat("Observaciones totales:", nrow(d2_clean_full), "\n")

# ============================================================
# 6. VENTANAS DE TIEMPO
# ============================================================
ventanas <- list(
  completa   = c("2007-12-01", "2025-12-01"),
  desde_2008 = c("2008-01-01", "2025-12-01"),
  desde_2009 = c("2009-01-01", "2025-12-01"),
  desde_2013 = c("2013-01-01", "2025-12-01"),
  desde_2018 = c("2018-01-01", "2025-12-01")
)

filtrar_ventana <- function(datos, inicio, fin) {
  datos[datos$Fecha >= as.Date(inicio) & datos$Fecha <= as.Date(fin), ]
}

datasets_ventana <- lapply(ventanas, function(v) {
  df <- filtrar_ventana(d2_clean_full, v[1], v[2])
  cat(sprintf("Ventana %s a %s: %d obs\n", v[1], v[2], nrow(df)))
  df
})
names(datasets_ventana) <- names(ventanas)

# ============================================================
# 7. ESTANDARIZACIÓN — solo variables macro
# ============================================================
estandarizar <- function(datos) {
  d_std <- datos
  d_std[, vars_macro] <- as.data.frame(scale(datos[, vars_macro]))
  d_std
}

datasets_std <- lapply(datasets_ventana, estandarizar)
cat("✔ Datasets estandarizados\n")

# ============================================================
# 8. FÓRMULAS
# ============================================================
formula_todas <- as.formula(paste("Score ~", paste(vars_macro, collapse = " + ")))

formula_red_2008 <- Score ~ t.fija.b5 + t.desocupacion +
  ahorro.bruto + tipo.de.cambio + balance.publico +
  cartera.consumo.var + remesas.var + m2.var +
  empleo.imss.var + tc.utilizadas.var

formula_red_2013 <- Score ~ t.fija.b5 + udib10 + TIIE +
  ahorro.bruto + tipo.de.cambio + cartera.consumo.var +
  empleo.imss.var + balance.publico + tc.utilizadas.var

formula_red_2018 <- Score ~ t.fija.b5 + udib10 + TIIE +
  ahorro.bruto + tipo.de.cambio + cartera.consumo.var +
  t.desocupacion + tc.utilizadas.var

# ============================================================
# 9. MODELOS
# ============================================================
cat("\n===== Modelo 1: 27 vars | 2008-2025 =====\n")
mod1 <- lm(formula_todas, data = datasets_std[["desde_2008"]])
print(summary(mod1))

cat("\n===== Modelo 2: 27 vars | 2009-2025 =====\n")
mod2 <- lm(formula_todas, data = datasets_std[["desde_2009"]])
print(summary(mod2))

cat("\n===== Modelo 3: 27 vars | 2013-2025 =====\n")
mod3 <- lm(formula_todas, data = datasets_std[["desde_2013"]])
print(summary(mod3))

cat("\n===== Modelo 4: 27 vars | 2018-2025 =====\n")
mod4 <- lm(formula_todas, data = datasets_std[["desde_2018"]])
print(summary(mod4))

cat("\n===== Modelo 5: Reducido | 2008-2025 =====\n")
mod5 <- lm(formula_red_2008, data = datasets_std[["desde_2008"]])
print(summary(mod5))

cat("\n===== Modelo 6: Reducido | 2013-2025 =====\n")
mod6 <- lm(formula_red_2013, data = datasets_std[["desde_2013"]])
print(summary(mod6))

cat("\n===== Modelo 7: Reducido | 2018-2025 =====\n")
mod7 <- lm(formula_red_2018, data = datasets_std[["desde_2018"]])
print(summary(mod7))

cat("\n===== Modelo 8: Stepwise | 2008-2025 =====\n")
mod8 <- step(mod1, direction = "both", trace = 0)
print(summary(mod8))
cat("Variables Modelo 8:", paste(names(coef(mod8))[-1], collapse = ", "), "\n")

cat("\n===== Modelo 9: Stepwise | 2013-2025 =====\n")
mod9 <- step(mod3, direction = "both", trace = 0)
print(summary(mod9))
cat("Variables Modelo 9:", paste(names(coef(mod9))[-1], collapse = ", "), "\n")

cat("\n===== Modelo 10: Stepwise | 2018-2025 =====\n")
mod10 <- step(mod4, direction = "both", trace = 0)
print(summary(mod10))
cat("Variables Modelo 10:", paste(names(coef(mod10))[-1], collapse = ", "), "\n")

# ============================================================
# 10. COMPARATIVO FINAL
# ============================================================
ventana_label <- c(mod1="2008-2025", mod2="2009-2025", mod3="2013-2025",
                   mod4="2018-2025", mod5="2008-2025", mod6="2013-2025",
                   mod7="2018-2025", mod8="2008-2025", mod9="2013-2025", mod10="2018-2025")
tipo_label    <- c(mod1="Completo", mod2="Completo", mod3="Completo", mod4="Completo",
                   mod5="Reducido", mod6="Reducido", mod7="Reducido",
                   mod8="Stepwise", mod9="Stepwise", mod10="Stepwise")

modelos_lista <- list(mod1=mod1, mod2=mod2, mod3=mod3, mod4=mod4,
                      mod5=mod5, mod6=mod6, mod7=mod7,
                      mod8=mod8, mod9=mod9, mod10=mod10)

resumen <- do.call(rbind, lapply(names(modelos_lista), function(nm) {
  m  <- modelos_lista[[nm]]
  sm <- summary(m)
  data.frame(Modelo=nm, Tipo=tipo_label[nm], Ventana=ventana_label[nm],
             R2_adj=round(sm$adj.r.squared,4), AIC=round(AIC(m),2),
             Num_vars=length(coef(m))-1, stringsAsFactors=FALSE)
}))

cat("\n===== Comparativo final (por AIC) =====\n")
print(resumen[order(resumen$AIC), ])

# ============================================================
# 11. VALIDACIÓN ESTADÍSTICA — 10 modelos
# ============================================================
tabla_pruebas <- do.call(rbind, lapply(names(modelos_lista), function(nm) {
  m   <- modelos_lista[[nm]]
  res <- resid(m)
  sw  <- shapiro.test(res)
  bp  <- bptest(m)
  data.frame(
    Modelo  = nm, Tipo = tipo_label[nm], Ventana = ventana_label[nm],
    SW_W    = round(sw$statistic, 4), SW_p  = round(sw$p.value, 4),
    SW_ok   = ifelse(sw$p.value > 0.05, "OK", "Falla"),
    BP_stat = round(bp$statistic, 3), BP_p  = round(bp$p.value, 4),
    BP_ok   = ifelse(bp$p.value > 0.05, "OK", "Falla"),
    stringsAsFactors = FALSE
  )
}))



cat("\n===== VALIDACIÓN ESTADÍSTICA (sin Durbin-Watson) =====\n")
print(tabla_pruebas)

# ── Gráfica de validación

tabla_pruebas$Etiqueta <- paste0(
  gsub("mod", "Modelo ", tabla_pruebas$Modelo), "\n", tabla_pruebas$Ventana
)

df_long <- tabla_pruebas %>%
  select(Etiqueta, SW_p, BP_p) %>%
  pivot_longer(cols = c(SW_p, BP_p),
               names_to = "Prueba", values_to = "p_valor") %>%
  mutate(
    Prueba    = recode(Prueba,
                       "SW_p" = "Shapiro-Wilk\n(Normalidad)",
                       "BP_p" = "Breusch-Pagan\n(Homocedasticidad)"),
    Resultado = ifelse(p_valor > 0.05, "Pasa (p > 0.05)", "Falla (p ≤ 0.05)")
  )

# Mantener orden correcto de modelos
df_long$Etiqueta <- factor(df_long$Etiqueta,
                           levels = paste0(gsub("mod", "Modelo ", names(modelos_lista)),
                                           "\n", ventana_label))

p_pruebas <- ggplot(df_long, aes(x = Etiqueta, y = p_valor, fill = Resultado)) +
  geom_col(width = 0.7) +
  geom_hline(yintercept = 0.05, linetype = "dashed", color = "#1a1a1a", linewidth = 0.7) +
  annotate("text", x = 0.6, y = 0.07, label = "α = 0.05", size = 3, color = "gray30") +
  scale_fill_manual(values = c("Pasa (p > 0.05)" = "#1D9E75", "Falla (p ≤ 0.05)" = "#E24B4A"),
                    name = NULL) +
  scale_y_continuous(limits = c(0, 1.05),
                     breaks = c(0, 0.05, 0.25, 0.5, 0.75, 1.0)) +
  facet_wrap(~ Prueba, ncol = 2) +       # <-- ncol=2 (antes 3), ya no hay DW
  labs(x = NULL, y = "p-valor") +
  theme_minimal(base_size = 10) +
  theme(strip.text = element_text(face = "bold", size = 11),
        strip.background = element_rect(fill = "gray96", color = NA),
        axis.text.x = element_text(angle = 35, hjust = 1, size = 8),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        legend.position = "bottom",
        panel.spacing = unit(1.5, "lines"))
print(p_pruebas)

# ============================================================
# 12. GRÁFICA VARIABLE DEPENDIENTE — IMORA TC EN EL TIEMPO
# ============================================================

# Etiquetas de eventos relevantes para el gráfico
eventos <- data.frame(
  Fecha  = as.Date(c("2009-06-01", "2020-06-01")),
  Label  = c("Crisis\n2008-09", "COVID-19\n2020"),
  Color  = c("#E24B4A", "#E85C00"),
  vjust  = c(1.4, 1.4)
)

p_imora_tiempo <- ggplot(d2_clean_full, aes(x = Fecha, y = PD)) +
  # Área de fondo bajo la línea
  geom_ribbon(aes(ymin = min(PD) * 0.9, ymax = PD), fill = "#378ADD", alpha = 0.15) +
  # Línea principal
  geom_line(color = "#185FA5", linewidth = 1.2) +
  # Anotación crisis 2008-09
  annotate("rect",
           xmin = as.Date("2008-07-01"), xmax = as.Date("2010-06-01"),
           ymin = -Inf, ymax = Inf,
           fill = "#E24B4A", alpha = 0.10) +
  annotate("text",
           x = as.Date("2009-02-01"), y = max(d2_clean_full$PD) * 0.98,
           label = "Crisis\n2008-09", color = "#C0392B",
           fontface = "bold", size = 3.5, vjust = 1) +
  # Anotación COVID-2020
  annotate("rect",
           xmin = as.Date("2020-01-01"), xmax = as.Date("2021-06-01"),
           ymin = -Inf, ymax = Inf,
           fill = "#E85C00", alpha = 0.10) +
  annotate("text",
           x = as.Date("2020-04-01"), y = max(d2_clean_full$PD) * 0.98,
           label = "COVID-19\n2020", color = "#E85C00",
           fontface = "bold", size = 3.5, vjust = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(x = "Fecha", y = "IMOR (%)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "gray92", linewidth = 0.4),
        axis.title = element_text(size = 11))
print(p_imora_tiempo)

# ============================================================
# 13. HEATMAP MULTICOLINEALIDAD
# ============================================================
mat_cor <- cor(d2_clean_full[, vars_macro], use = "complete.obs")


etiquetas <- c(
  "CETE28"             = "CETE 28 días",
  "t.fija.b5"          = "Bono fijo 5 años",
  "t.fija.b10"         = "Bono fijo 10 años",
  "udib3"              = "Udibonos 3 años",
  "udib10"             = "Udibonos 10 años",
  "PIB"                = "PIB",
  "t.desocupacion"     = "Desocupación",
  "INPC"               = "INPC",
  "TIIE"               = "TIIE",
  "ahorro.bruto"       = "Ahorro bruto",
  "IMCP"               = "IMCP",
  "IGAE"               = "IGAE",
  "tipo.de.cambio"     = "Tipo de cambio",
  "IPC.Var.BMV"        = "IPC BMV",
  "t.objetivo"         = "Tasa objetivo",
  "cartera.consumo.var"= "Cartera consumo",
  "tarjetas.var"       = "Tarjetas crédito",
  "rem.comercio.real.var"="Rem. comerciales",
  "remesas.var"        = "Remesas",
  "infl.subyacente"    = "Infl. subyacente",
  "consumo.privado.var"= "Consumo privado",
  "m1.var"             = "Agregado M1",
  "m2.var"             = "Agregado M2",
  "balance.publico"    = "Balance público",
  "tc.utilizadas.var"  = "TC utilizadas",
  "cuentas.tc.var"     = "Cuentas TC",
  "empleo.imss.var"    = "Empleo IMSS"
)

mat_cor_long <- melt(mat_cor)
names(mat_cor_long) <- c("Variable1", "Variable2", "Correlacion")
mat_cor_long$Variable1 <- etiquetas[as.character(mat_cor_long$Variable1)]
mat_cor_long$Variable2 <- etiquetas[as.character(mat_cor_long$Variable2)]
orden_vars <- etiquetas[colnames(mat_cor)]
mat_cor_long$Variable1 <- factor(mat_cor_long$Variable1, levels = rev(orden_vars))
mat_cor_long$Variable2 <- factor(mat_cor_long$Variable2, levels = orden_vars)

p_heatmap <- ggplot(mat_cor_long, aes(x = Variable2, y = Variable1, fill = Correlacion)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_gradientn(
    colors = c("#A32D2D","#E24B4A","#F09595","white","#85B7EB","#185FA5","#042C53"),
    values = scales::rescale(c(-1,-0.6,-0.3,0,0.3,0.6,1)),
    limits = c(-1,1), name = "Correlación"
  ) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 9, color = "gray20"),
        axis.text.y = element_text(size = 9, color = "gray20"),
        panel.grid = element_blank(),
        legend.title = element_text(size = 9),
        legend.text  = element_text(size = 8))
print(p_heatmap)

# ============================================================
# 14. PERIODO DE CALIBRACIÓN 
# ============================================================

d2_clean_full <- d2_clean_full %>%
  mutate(
    color_pib = case_when(
      PIB < 0 ~ "Recesión",
      (Fecha >= as.Date("2010-01-01") & Fecha <= as.Date("2011-06-01")) |
        (Fecha >= as.Date("2021-01-01") & Fecha <= as.Date("2022-06-01")) ~ "Recuperación",
      TRUE ~ "Estabilidad"
    )
  )
p_pib_calibracion <- ggplot(d2_clean_full, aes(x = Fecha, y = PIB, fill = color_pib)) +
  geom_col(show.legend = TRUE) +
  scale_fill_manual(
    values = c(
      "Estabilidad"          = "#378ADD",
      "Recesión"          = "#E24B4A",
      "Recuperación"= "#1D9E75"   
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(x = "Fecha", y = "Variación (%)") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom",
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "gray92", linewidth = 0.4),
        axis.title = element_text(size = 11))
print(p_pib_calibracion)

# Restaurar d2_clean_full sin la columna auxiliar
d2_clean_full$color_pib <- NULL

# ============================================================
# 15. COEFICIENTES ESTANDARIZADOS
# ============================================================

etiquetas_vars <- c(
  "CETE28"             = "CETE 28 días",
  "t.fija.b5"          = "Bono gub. tasa fija 5 años",
  "t.fija.b10"         = "Bono gub. tasa fija 10 años",
  "udib3"              = "Udibonos 3 años",
  "udib10"             = "Udibonos 10 años",
  "t.desocupacion"     = "Tasa de desocupación",
  "INPC"               = "INPC",
  "TIIE"               = "TIIE",
  "ahorro.bruto"       = "Ahorro bruto",
  "tipo.de.cambio"     = "Tipo de cambio FIX",
  "IPC.Var.BMV"        = "IPC BMV",
  "t.objetivo"         = "Tasa objetivo Banxico",
  "cartera.consumo.var"= "Cartera de consumo var.",
  "tarjetas.var"       = "Tarjetas de crédito var.",
  "remesas.var"        = "Remesas familiares var.",
  "infl.subyacente"    = "Inflación subyacente",
  "consumo.privado.var"= "Consumo privado var.",
  "m1.var"             = "Agregado monetario M1 var.",
  "m2.var"             = "Agregado monetario M2 var.",
  "balance.publico"    = "Balance del sector público",
  "tc.utilizadas.var"  = "Tarjetas utilizadas var.",
  "cuentas.tc.var"     = "Cuentas de tarjetas de crédito var.",
  "empleo.imss.var"    = "Empleo formal IMSS var."
)

coefs <- as.data.frame(coef(summary(mod9)))
coefs$Variable <- rownames(coefs)
coefs <- coefs[coefs$Variable != "(Intercept)", ]
coefs <- coefs[order(coefs$Estimate), ]

# Reemplazar nombres de variable con etiquetas legibles
coefs$Etiqueta <- etiquetas_vars[coefs$Variable]
coefs$Etiqueta <- ifelse(is.na(coefs$Etiqueta), coefs$Variable, coefs$Etiqueta)
coefs$Etiqueta <- factor(coefs$Etiqueta, levels = coefs$Etiqueta)

coefs$Color <- ifelse(coefs$Estimate > 0, "#1D9E75", "#E24B4A")

p_coefs <- ggplot(coefs, aes(x = Estimate, y = Etiqueta, fill = Color)) +
  geom_col(width = 0.7) +
  geom_vline(xintercept = 0, linewidth = 0.4, color = "gray60", alpha = 0.5) +
  scale_fill_identity() +
  labs(x = "Coeficiente estandarizado (IC 95%)", y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank())
print(p_coefs)

# ============================================================
# 16. GRÁFICAS Modelo 9
# ============================================================
pred_pd <- function(mod, datos) 1 / (1 + exp(-predict(mod, newdata = datos)))

fechas_2013 <- d2_clean_full$Fecha[d2_clean_full$Fecha >= as.Date("2013-01-01")]

# ── Real vs Estimado Modelo 9 ─────────────────────────────────
df_pred <- data.frame(
  Fecha    = fechas_2013,
  Real     = d2_clean_full$PD[d2_clean_full$Fecha >= as.Date("2013-01-01")],
  Estimado = pred_pd(mod9, datasets_std[["desde_2013"]])
) %>% pivot_longer(-Fecha, names_to = "Serie", values_to = "PD")

p_real_vs_est <- ggplot(df_pred, aes(x = Fecha, y = PD, color = Serie, linewidth = Serie)) +
  geom_line() +
  scale_color_manual(values = c("Real" = "#1a1a1a", "Estimado" = "#7F77DD")) +
  scale_linewidth_manual(values = c("Real" = 1.4, "Estimado" = 0.9)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(title    = "IMORA TC: Real vs. Estimado — Modelo 9 (stepwise 2013-2025)",
       subtitle = "R² ajustado = 82.4%  |  AIC = -308.17  |  13 variables seleccionadas",
       x = NULL, y = "Probabilidad de default", color = NULL, linewidth = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))
print(p_real_vs_est)

# ── Histograma de residuos Modelo 9 ──────────────────────────
res9_vec  <- resid(mod9)
media_res <- mean(res9_vec)
sd_res    <- sd(res9_vec)
sw_test   <- shapiro.test(res9_vec)

p_hist_res9 <- ggplot(data.frame(Residuo = res9_vec), aes(x = Residuo)) +
  geom_histogram(aes(y = after_stat(density)), bins = 20,
                 fill = "#7F77DD", color = "white", linewidth = 0.3, alpha = 0.85) +
  stat_function(fun = dnorm, args = list(mean = media_res, sd = sd_res),
                color = "#1a1a1a", linewidth = 1) +
  geom_vline(xintercept = media_res, color = "#E24B4A", linewidth = 0.8, linetype = "dashed") +
  annotate("text", x = Inf, y = Inf, hjust = 1.1, vjust = 1.5,
           label = paste0("Shapiro-Wilk\nW = ", round(sw_test$statistic, 4),
                          "\np-valor = ", round(sw_test$p.value, 4)),
           size = 3.5, color = "gray30", fontface = "italic") +
  labs(title    = "Distribución de residuos — Modelo 9 (stepwise 2013-2025)",
       subtitle = "Curva negra = distribución normal teórica  |  Línea roja = media",
       x = "Residuo", y = "Densidad") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(color = "gray50", size = 9),
        panel.grid.minor = element_blank())
print(p_hist_res9)

# ── Residuos en el tiempo Modelo 9 ───────────────────────────
p_res_ts <- ggplot(data.frame(Fecha = fechas_2013, Residuo = res9_vec),
                   aes(x = Fecha, y = Residuo)) +
  geom_line(color = "#378ADD", linewidth = 0.7) +
  geom_hline(yintercept = c(-0.05, 0, 0.05),
             linetype = c("dashed","solid","dashed"),
             color    = c("gray50","#E24B4A","gray50")) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  labs(title    = "Residuos en el tiempo — Modelo 9",
       subtitle = paste0("Shapiro-Wilk p = ", round(sw_test$p.value, 4),
                         "  |  Breusch-Pagan p = ", round(bptest(mod9)$p.value, 4)),
       x = NULL, y = "Residuo") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))
print(p_res_ts)

# ============================================================
# 17. GRÁFICA FACETAS — 10 modelos
# ============================================================
f2008 <- d2_clean_full$Fecha[d2_clean_full$Fecha >= as.Date("2008-01-01")]
f2009 <- d2_clean_full$Fecha[d2_clean_full$Fecha >= as.Date("2009-01-01")]
f2013 <- d2_clean_full$Fecha[d2_clean_full$Fecha >= as.Date("2013-01-01")]
f2018 <- d2_clean_full$Fecha[d2_clean_full$Fecha >= as.Date("2018-01-01")]

real <- data.frame(
  Fecha = f2008,
  PD    = d2_clean_full$PD[d2_clean_full$Fecha >= as.Date("2008-01-01")]
)

estimados <- bind_rows(
  data.frame(Fecha=f2008, PD=pred_pd(mod1,datasets_std[["desde_2008"]]),  Modelo="Modelo 1 — Completo 27v\n2008-2025"),
  data.frame(Fecha=f2009, PD=pred_pd(mod2,datasets_std[["desde_2009"]]),  Modelo="Modelo 2 — Completo 27v\n2009-2025"),
  data.frame(Fecha=f2013, PD=pred_pd(mod3,datasets_std[["desde_2013"]]),  Modelo="Modelo 3 — Completo 27v\n2013-2025"),
  data.frame(Fecha=f2018, PD=pred_pd(mod4,datasets_std[["desde_2018"]]),  Modelo="Modelo 4 — Completo 27v\n2018-2025"),
  data.frame(Fecha=f2008, PD=pred_pd(mod5,datasets_std[["desde_2008"]]),  Modelo="Modelo 5 — Reducido\n2008-2025"),
  data.frame(Fecha=f2013, PD=pred_pd(mod6,datasets_std[["desde_2013"]]),  Modelo="Modelo 6 — Reducido\n2013-2025"),
  data.frame(Fecha=f2018, PD=pred_pd(mod7,datasets_std[["desde_2018"]]),  Modelo="Modelo 7 — Reducido\n2018-2025"),
  data.frame(Fecha=f2008, PD=pred_pd(mod8,datasets_std[["desde_2008"]]),  Modelo="Modelo 8 — Stepwise\n2008-2025"),
  data.frame(Fecha=f2013, PD=pred_pd(mod9,datasets_std[["desde_2013"]]),  Modelo="Modelo 9 — Stepwise\n2013-2025"),
  data.frame(Fecha=f2018, PD=pred_pd(mod10,datasets_std[["desde_2018"]]), Modelo="Modelo 10 — Stepwise\n2018-2025")
)

orden_paneles <- c(
  "Modelo 1 — Completo 27v\n2008-2025", "Modelo 2 — Completo 27v\n2009-2025",
  "Modelo 3 — Completo 27v\n2013-2025", "Modelo 4 — Completo 27v\n2018-2025",
  "Modelo 5 — Reducido\n2008-2025",     "Modelo 6 — Reducido\n2013-2025",
  "Modelo 7 — Reducido\n2018-2025",     "Modelo 8 — Stepwise\n2008-2025",
  "Modelo 9 — Stepwise\n2013-2025",     "Modelo 10 — Stepwise\n2018-2025"
)
estimados$Modelo <- factor(estimados$Modelo, levels = orden_paneles)

colores_mod <- c(
  "Modelo 1 — Completo 27v\n2008-2025" = "#85B7EB",
  "Modelo 2 — Completo 27v\n2009-2025" = "#378ADD",
  "Modelo 3 — Completo 27v\n2013-2025" = "#185FA5",
  "Modelo 4 — Completo 27v\n2018-2025" = "#0C447C",
  "Modelo 5 — Reducido\n2008-2025"     = "#EF9F27",
  "Modelo 6 — Reducido\n2013-2025"     = "#BA7517",
  "Modelo 7 — Reducido\n2018-2025"     = "#854F0B",
  "Modelo 8 — Stepwise\n2008-2025"     = "#AFA9EC",
  "Modelo 9 — Stepwise\n2013-2025"     = "#7F77DD",
  "Modelo 10 — Stepwise\n2018-2025"    = "#3C3489"
)

p_facetas <- ggplot() +
  geom_line(data = real, aes(x=Fecha, y=PD), color="gray75", linewidth=0.7) +
  geom_line(data = estimados, aes(x=Fecha, y=PD, color=Modelo), linewidth=0.85) +
  scale_color_manual(values = colores_mod, guide = "none") +
  scale_y_continuous(labels = percent_format(accuracy=1), limits=c(0.03,0.23)) +
  scale_x_date(date_breaks = "4 years", date_labels = "%Y") +
  facet_wrap(~ Modelo, ncol=5) +
  labs(subtitle = "Azul = completo  |  Naranja = reducido  |  Púrpura = stepwise  |  Gris = IMORA real",
       x=NULL, y="Probabilidad de default (%)") +
  theme_minimal(base_size=11) +
  theme(plot.subtitle=element_text(color="gray50",size=9,margin=margin(b=12)),
        strip.text=element_text(face="bold",size=8.5,color="gray20"),
        strip.background=element_rect(fill="gray96",color=NA),
        panel.grid.minor=element_blank(),
        panel.grid.major=element_line(color="gray92",linewidth=0.35),
        panel.spacing=unit(1.0,"lines"),
        axis.text=element_text(color="gray45",size=7.5))
print(p_facetas)
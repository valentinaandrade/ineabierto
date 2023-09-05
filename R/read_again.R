# 1. Load packages --------------------------------------------------------

pacman::p_load(tidyverse, haven )

# 2. Load data --------------------------------------------------------


years <- 2010:2021

data_list <- map(setNames(nm = years), ~{
  url <- paste0("https://www.ine.gob.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/",
                .,
                "/stata/ene-",
                .,
                "-11-ond.dta")
  read_dta(url)
})


data <- data_list %>% bind_rows()



# 3. Process data ---------------------------------------------------------

# Crear una nueva variable 'informalidad' que combine 'b7_5' y 'b7a_3'
data <- data %>%
  mutate(
    informalidad = case_when(
      ano_trimestre %in% 2010:2016 ~ as.character(b7_5),
      ano_trimestre %in% 2017:2021 ~ as.character(b7a_3),
      TRUE ~ NA_character_
    )
  )

# Calcular la tasa de informalidad total y por sexo
tasa_informalidad <- data %>%
  group_by(ano_trimestre, sexo) %>%
  summarise(
    Total = sum(informalidad %in% c("1", "2"), na.rm = TRUE),
    Informal = sum(informalidad == "2", na.rm = TRUE),
    Tasa_Informalidad = (Informal / Total) * 100,
    .groups = 'drop'
  )


# 4. Survey ------------------------------------------------------------------
data_muestral <- data %>% 
  filter(!is.na(fact)) %>% 
  as_survey_design(ids = idrph, 
                   strata = estrato,
                   weights = fact)


# Calcular la tasa de informalidad total y por sexo usando ponderación
tasa_informalidad <- data_muestral %>%
  group_by(ano_trimestre, sexo) %>%
  summarise(
    Total = survey_total(informalidad %in% c("1", "2"), na.rm = TRUE),
    Informal = survey_total(informalidad == "2", na.rm = TRUE),
    Tasa_Informalidad = (Informal / Total) * 100
  )


# 5. Figures --------------------------------------------------------------

ggplot(data = tasa_informalidad, aes(x = as_factor(ano_trimestre), y = Tasa_Informalidad, color = as.factor(sexo), group = sexo)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Tasa de Empleo Informal por Año y Sexo",
    x = "Año",
    y = "Tasa de Empleo Informal (%)",
    color = "Sexo"
  ) +
  scale_color_manual(values = c("blue", "red"), labels = c("Hombre", "Mujer")) +
  theme_minimal()

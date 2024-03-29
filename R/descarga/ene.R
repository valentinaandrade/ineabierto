# ENE ---------------------------------------------------------------------
# URL
# https://www.ine.cl/estadisticas/sociales/mercado-laboral/ocupacion-y-desocupacion
# 
# Patrón
# https://www.ine.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/2010/formato-stata/ene-2010-12.dta?sfvrsn=60ff0348_4&download=true
# https://www.ine.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/2020/stata/ene-2020-02-efm.dta?sfvrsn=56f12b0f_8&download=true


# paquetes ----------------------------------------------------------------
library(haven)
library(purrr)
library(lubridate)
library(stringr)
library(fs) # FileSystem, craer carpetas, rutas de archivos, etc
library(dplyr)


# descarga ----------------------------------------------------------------
fechas <- seq.Date(
  ymd(20100201),
  ymd(20200901),
  by = "month"
)

fs::dir_create("data/")
fs::dir_create("data/ene/")

meses <- unlist(str_split("defmamjjasonde", ""))

walk(fechas, function(fecha = sample(fechas, 1)){
  
  # fecha <- ymd("2010-02-01")
  
  message("Descargando ", fecha)
  
  archivo <- fs::path("data/ene/", fecha, ext = "rds")
    
  if(fs::file_exists(archivo)) return(TRUE)
  
  mes <- month(fecha)
  trimestre <- str_c(meses[ mes + c(0, 1, 2)], collapse = "")
  
  url <- str_glue(
    "https://www.ine.gob.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/{ anio }/{ ruta }/ene-{ anio }-{ mes }-ond.dta",
    anio = year(fecha),
    ruta = ifelse(year(fecha) <= 2019, "stata", "stata"),
    mes  = str_pad(month(fecha), width = 2, pad = "0"),
    tri  = case_when(
      between(year(fecha), 2018, 2019) ~ "",
      between(year(fecha), 2010, 2012) ~ "",
      TRUE ~ str_c("-", trimestre)
    ) 
  )
  
  if(fecha ==  ymd("2014-08-01")){
    message("Gracias INE!")
    url <- "https://www.ine.gob.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/2014/stata/ene-2014-08-nde.dta"
  }
  #"https://www.ine.gob.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/2020/stata/ene-2020-11-ond.dta"
  # "https://www.ine.gob.cl/docs/default-source/ocupacion-y-desocupacion/bbdd/2010/stata/ene-2010-02-efm.dta"
  #   url,
  #   archivo,
  #   method = "wininet"
  # )
  
  data <- haven::read_dta(url)
  
  saveRDS(data, archivo)
  
})


# union -------------------------------------------------------------------
# data <- readRDS("data/ene/2020-01-01.rds")

anios <- dir("data/ene/", full.names = TRUE) %>% 
  str_extract("[0-9]{4}") %>% 
  unique()


unir_anio <- function(anio = 2017) {
  
  dir("data/ene/", full.names = TRUE) %>%
    str_subset(as.character(anio)) %>%
    map_df(function(x) {
      
      message("\t", x)
      
      readRDS(x) %>% 
        mutate_at(vars(contains("conglomerado")), as.numeric) %>% 
        select(
          everything()
          # -b17_mes, 
          # -e6_mes,
          # 2016
          # -b7_1, -b7_2, -b7_3, -b7_4, -b7_5, -b7_6
        )
    })
  
}

data <- unir_anio(2018)

data

data2016 <- unir_anio(2016)


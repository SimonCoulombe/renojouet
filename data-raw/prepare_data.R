## code to prepare `clients` dataset goes here

library(tidyverse)
library(ggmap)
library(sf)
library(hereR)
register_google(key = Sys.getenv("googlemap_api_key"),
                account_type="premium")
hereR::set_key(Sys.getenv("HERE_key"))

renojouet_adresse <- "2699 Avenue Watt, Québec, QC G1P 3X3"
usethis::use_data(renojouet_adresse)

renojouet_location <- hereR::geocode(renojouet_adresse)
usethis::use_data(renojouet_location)

renojouet_location2 <- bind_rows(renojouet_location, renojouet_location)
isolines <- hereR::isoline(grenojouet_location2, range_type = "time", mode = "car",
                type = "fast", range = c(10,20,30,60) * 60)
usethis::use_data(isolines)

shp_secteurs_municipaux <- st_read(here::here("data-raw/shp/SM2017_Que_region.shp"),
                             options = "ENCODING=windows-1252") %>%
  st_set_crs(., "+init=epsg:3347") %>%  #3347 lambert canada
  st_transform(., crs = "+proj=longlat +datum=WGS84")

usethis::use_data(shp_secteurs_municipaux)

shp_arrondissements <- st_read(here::here("data-raw/shp/vdq-arrondissement.shp"))
usethis::use_data(shp_arrondissements)

clients <- read_csv(here::here("data-raw/csv/clients.csv")) %>%
  janitor::clean_names() %>%
  mutate(code_postal = toupper(str_replace_all(code_postal," ", "")))

donateurs <- read_csv(here::here("data-raw/csv/donateurs.csv")) %>%
  janitor::clean_names() %>%
  mutate(code_postal = toupper(str_replace_all(code_postal," ", "")))


unique_valid_code_postal <-
  bind_rows(clients, donateurs) %>%
  filter(str_length(code_postal) == 6) %>%
  distinct(code_postal) %>%
  mutate(geocode_text = paste0( code_postal, ", Canada"))

latlons <- ggmap::geocode(location = unique_valid_code_postal$geocode_text, output = "latlon", source= "google")

geocoded_code_postal <- unique_valid_code_postal  %>% bind_cols(latlons)
write_csv(geocoded_code_postal, here::here("data-raw/geocoded_code_postal.csv"))
usethis::use_data(geocoded_code_postal)

usethis::use_data(clients)
usethis::use_data(donateurs)

sf_clients <- clients %>%
  left_join(geocoded_code_postal) %>%
  filter(!is.na(lat)) %>%
  sf::st_as_sf(x = ., coords = c("lon", "lat"), crs = 4326, agr = "constant")

sf_donateurs <- donateurs %>%
  left_join(geocoded_code_postal) %>%
  filter(!is.na(lat)) %>%
  sf::st_as_sf(x = ., coords = c("lon", "lat"), crs = 4326, agr = "constant")
usethis::use_data(sf_clients)
usethis::use_data(sf_donateurs)


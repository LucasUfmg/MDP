#' Deforestation
#'
#' @export

#get_prodes <- function() {

  #path <- download_data(
  #  url = data_catalog$prodes,
  #  filename = "prodes_package.gpkg"
  #)

  #sf::st_read( path, quiet = T)
  #sf::st_read( "C:/Users/luktr/AppData/Local/R/cache/R/mdp/prodes_package.gpkg", quiet = T)

#}

get_prodes <- function() {

  path <- download_data(
    url = data_catalog$prodes,
    filename = "prodes_package.gpkg"
  )

  sf::st_read(path, quiet = TRUE)
}

#' Deforestation
#'
#' @export

get_prodes <- function() {

  path <- download_data(
    url = data_catalog$prodes,
    filename = "prodes_package.gpkg"
  )

  sf::st_read( path, quiet = T)

}


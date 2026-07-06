#' Focos
#'
#' @export
get_focos <- function() {

  path <- download_data(
    url = data_catalog$focos,
    filename = "focos_package_2016_2024.gpkg"
  )

  sf::st_read(
    path,
    quiet = TRUE
  )

}



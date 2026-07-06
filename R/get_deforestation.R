#' Deforestation
#'
#' @export
get_deforestation <- function() {

  path <- download_data(
    url = data_catalog$deforestation,
    filename = "deter_package.gpkg"
  )

  sf::st_read(
    path,
    quiet = TRUE
  )

}

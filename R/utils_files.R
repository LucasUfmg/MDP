#' Run prioritization model
#'
#' Executes model fitting and prioritization for each month.
#'
#' @param name file name
#' @param package package necessary
#' @return shapefile
#' @export
# Internal helper to load shapefiles from inst/extdata
load_ext_shp <- function(name, package = "pdm") {

  shp_path <- system.file("extdata", paste0(name), package = package)

  print(paste("DEBUG path:", shp_path))

  if (shp_path == "") {
    stop("Shapefile not found in inst/extdata/: ", name, call. = FALSE)
  }

  sf::st_read(shp_path, quiet = TRUE)
}


#' Load external shapefile
#'
#' Reads a spatial file from inst/extdata.
#'
#' @param name Name of the spatial file.
#' @param package Package containing the file.
#'
#' @return An sf object.
#' @export
load_ext_csv <- function(name, package = "pdm") {

  csv_path <- system.file("extdata", paste0(name), package = package)

  print(paste("DEBUG path:", csv_path))

  if (csv_path == "") {
    stop("Table not found in inst/extdata/: ", name, call. = FALSE)
  }

  utils::read.csv(csv_path)
}

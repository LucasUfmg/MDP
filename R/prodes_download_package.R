#' Amazon biome download update months
#'
#' @export
update_deforestation_prodes <- function() {

  # 1. Load baseline from GitHub release

  base <- get_prodes() |> dplyr::rename(geometry = .data$geom,
                                        ano = .data$prodes_amazonia_legal_2025_v20260408)
  base_up <- base

  # # 2. Find last date in local dataset
  # base$YEAR <- as.Date(base$YEAR)
  # last_date <- max(base$YEAR, na.rm = TRUE)
  #
  # message("Last local date: ", last_date)
  #
  # # 3. Define update range (next day → today)
  # start_date <- last_date + 1
  # end_date <- Sys.Date()
  #
  # if (start_date > end_date) {
  #   message("Dataset already up to date.")
  #   return(base)
  # }
  #
  # # 4. Build CQL filter
  # cql <- sprintf(
  #   "view_date >= '%s' AND view_date <= '%s'",
  #   start_date,
  #   end_date
  # )
  #
  # cql <- utils::URLencode(cql, reserved = TRUE)

  # 5. Paginated download from GeoServer
  #start_index <- 0
  #page_size <- 10000
  #pieces <- list()

  # repeat {
  #
  #   url <- paste0(
  #     "https://terrabrasilis.dpi.inpe.br/geoserver/ows?",
  #     "service=WFS",
  #     "&version=2.0.0",
  #     "&request=GetFeature",
  #     "&typeNames=prodes-amazon-nb:yearly_deforestation_biome",
  #     "&outputFormat=application/json",
  #     "&CQL_FILTER=", cql,
  #     "&count=", page_size,
  #     "&startIndex=", start_index,
  #     "&sortBy=id"
  #   )
  #
  #   x <- try(sf::st_read(url, quiet = TRUE), silent = TRUE)
  #
  #   if (inherits(x, "try-error") || nrow(x) == 0)
  #     break
  #
  #   pieces[[length(pieces) + 1]] <- x
  #
  #   if (nrow(x) < page_size)
  #     break
  #
  #   start_index <- start_index + page_size
  # }

  # 6. Merge + deduplicate
  # if (length(pieces) > 0) {
  #
  #   cat("foi encontrado novos desmatamentos prodes")
  #   new_data <- dplyr::bind_rows(pieces)
  #   #print(class(new_data))
  #
  #   #colunas maisculas menos geometry
  #   geom_col <- attr(x, "sf_column")
  #
  #   names(new_data)[names(new_data) != geom_col] <-
  #     toupper(names(new_data)[names(new_data) != geom_col])
  #
  #   #new_data <- new_data |>
  #     #dplyr::rename(
  #       #FID = .data$FID,
  #       #GEOCODIBGE = .data$MUN_GEOCOD,
  #       #MUNICIPALI = .data$MUNICIPALITY
  #     #) |>
  #     #dplyr::select(-c("PUBLISH_MONTH", "GID"))
  #
  #   # remove ID GID
  #   base_up <- dplyr::bind_rows(base, new_data)
  #   #base_up <- base_up[!duplicated(base_up$gid), ]
  #
  #   return(base_up)
  # }

  #base_up
}




#' Update the DETER deforestation dataset
#'
#' Retrieves new DETER alerts from TerraBrasilis and combines
#' them with the cached dataset.
#'
#' @param update_remote Logical. If TRUE, attempts to retrieve
#'   new alerts from TerraBrasilis. If FALSE, returns only the
#'   cached dataset.
#'
#' @return An sf object containing the cached dataset and,
#'   when successfully retrieved, new DETER alerts.
#'
#' @importFrom magrittr %>%
#' @export

update_deforestation <- function(update_remote = TRUE) {

  # 1. Load cached baseline
  base <- get_deforestation() |>
    dplyr::rename(geometry = .data$geom)

  base$VIEW_DATE <- as.Date(base$VIEW_DATE)

  # 2. Use cache only when update_remote = FALSE
  if (!isTRUE(update_remote)) {
    message("Remote update disabled. Using cached DETER data.")
    return(base)
  }

  # 3. Define update range
  valid_dates <- base$VIEW_DATE[!is.na(base$VIEW_DATE)]

  if (length(valid_dates) == 0) {
    stop("The cached DETER dataset has no valid VIEW_DATE.")
  }

  last_date <- max(valid_dates)

  message("Last local date: ", last_date)

  start_date <- last_date + 1
  end_date <- Sys.Date()

  if (start_date > end_date) {
    message("Dataset already up to date.")
    return(base)
  }

  # 4. Configure TerraBrasilis WFS
  endpoint <- paste0(
    "https://terrabrasilis.dpi.inpe.br/",
    "geoserver/deter-amz/wfs"
  )

  cql <- sprintf(
    "view_date >= '%s' AND view_date <= '%s'",
    format(start_date, "%Y-%m-%d"),
    format(end_date, "%Y-%m-%d")
  )

  # 5. Download with pagination and retries
  start_index <- 0
  page_size <- 500
  max_attempts <- 5
  pieces <- list()
  download_failed <- FALSE

  repeat {

    message(
      "Downloading DETER records from index ",
      start_index, "..."
    )

    response <- NULL

    for (attempt in seq_len(max_attempts)) {

      response <- tryCatch(
        httr::GET(
          endpoint,
          query = list(
            service = "WFS",
            version = "2.0.0",
            request = "GetFeature",
            typeNames = "deter-amz:deter_amz",
            outputFormat = "application/json",
            CQL_FILTER = cql,
            count = page_size,
            startIndex = start_index,
            sortBy = "gid"
          ),
          httr::timeout(180)
        ),
        error = function(e) {
          message(
            "Connection error: ",
            conditionMessage(e)
          )
          NULL
        }
      )

      if (!is.null(response) &&
          httr::status_code(response) == 200) {
        break
      }

      status <- if (is.null(response)) {
        "connection error"
      } else {
        httr::status_code(response)
      }

      message(
        "Attempt ", attempt, "/", max_attempts,
        " failed (", status, ")."
      )

      if (attempt < max_attempts) {
        wait_seconds <- min(2^attempt, 30)
        message("Retrying in ", wait_seconds, " seconds...")
        Sys.sleep(wait_seconds)
      }
    }

    # If the request still fails, discard the incomplete update
    if (is.null(response) ||
        httr::status_code(response) != 200) {
      message(
        "Download failed at index ", start_index, "."
      )
      download_failed <- TRUE
      break
    }

    response_text <- httr::content(
      response,
      as = "text",
      encoding = "UTF-8"
    )

    if (!jsonlite::validate(response_text)) {
      message(
        "Invalid JSON received at index ",
        start_index, "."
      )
      download_failed <- TRUE
      break
    }

    obj <- tryCatch(
      jsonlite::fromJSON(
        response_text,
        simplifyVector = FALSE
      ),
      error = function(e) NULL
    )

    if (is.null(obj) || is.null(obj$features)) {
      message(
        "Unexpected GeoJSON response at index ",
        start_index, "."
      )
      download_failed <- TRUE
      break
    }

    n_features <- length(obj$features)

    message("Records received: ", n_features)

    if (n_features == 0) {
      break
    }

    # Read GeoJSON from a temporary file
    temp_file <- tempfile(fileext = ".geojson")

    writeLines(
      response_text,
      temp_file,
      useBytes = TRUE
    )

    page <- tryCatch(
      sf::st_read(temp_file, quiet = TRUE),
      error = function(e) {
        message(
          "Could not parse GeoJSON: ",
          conditionMessage(e)
        )
        NULL
      },
      finally = unlink(temp_file)
    )

    if (is.null(page) || nrow(page) != n_features) {
      message(
        "Incomplete or invalid page at index ",
        start_index, "."
      )
      download_failed <- TRUE
      break
    }

    pieces[[length(pieces) + 1]] <- page

    message(
      "Total downloaded: ",
      sum(vapply(pieces, nrow, integer(1)))
    )

    if (n_features < page_size) {
      break
    }

    # Advance only after successfully processing the page
    start_index <- start_index + n_features
  }

  # 6. Fall back to cache if the download was incomplete
  if (download_failed) {
    warning(
      "Could not complete the DETER download. ",
      "Returning cached data."
    )
    return(base)
  }

  # 7. No new alerts
  if (length(pieces) == 0) {
    message("No new DETER alerts. Using cached data.")
    return(base)
  }

  # 8. Combine downloaded pages
  new_data <- tryCatch(
    dplyr::bind_rows(pieces),
    error = function(e) {
      message(
        "Could not combine downloaded pages: ",
        conditionMessage(e)
      )
      NULL
    }
  )

  if (is.null(new_data)) {
    warning("Could not combine DETER pages. Returning cached data.")
    return(base)
  }

  geom_col <- attr(new_data, "sf_column")

  if (is.null(geom_col) || !geom_col %in% names(new_data)) {
    warning("Invalid geometry column. Returning cached data.")
    return(base)
  }

  # Standardize geometry column
  if (geom_col != "geometry") {
    names(new_data)[names(new_data) == geom_col] <- "geometry"
    attr(new_data, "sf_column") <- "geometry"
  }

  # Uppercase attribute names
  attr_cols <- names(new_data) != "geometry"
  names(new_data)[attr_cols] <- toupper(names(new_data)[attr_cols])

  # Rename fields only when the source column exists
  if ("GID" %in% names(new_data) && !"FID" %in% names(new_data)) {
    names(new_data)[names(new_data) == "GID"] <- "FID"
  } else if ("ID" %in% names(new_data) && !"FID" %in% names(new_data)) {
    names(new_data)[names(new_data) == "ID"] <- "FID"
  }

  if ("MUN_GEOCOD" %in% names(new_data) &&
      !"GEOCODIBGE" %in% names(new_data)) {
    names(new_data)[names(new_data) == "MUN_GEOCOD"] <- "GEOCODIBGE"
  }

  if ("MUNICIPALITY" %in% names(new_data) &&
      !"MUNICIPALI" %in% names(new_data)) {
    names(new_data)[names(new_data) == "MUNICIPALITY"] <- "MUNICIPALI"
  }

  new_data <- dplyr::select(
    new_data,
    -dplyr::any_of("PUBLISH_MONTH")
  )

  if ("VIEW_DATE" %in% names(new_data)) {
    new_data$VIEW_DATE <- as.Date(new_data$VIEW_DATE)
  }

  # 9. Match CRS
  crs_base <- sf::st_crs(base)
  crs_new <- sf::st_crs(new_data)

  if (!is.na(crs_base) && !is.na(crs_new) &&
      crs_base != crs_new) {
    new_data <- sf::st_transform(new_data, crs_base)
  }

  # 10. Merge cached and new data
  base_up <- tryCatch(
    dplyr::bind_rows(base, new_data),
    error = function(e) {
      message(
        "Could not merge cached and new data: ",
        conditionMessage(e)
      )
      NULL
    }
  )

  if (is.null(base_up)) {
    warning("Could not merge DETER data. Returning cached data.")
    return(base)
  }

  message(
    "DETER update completed. New records: ",
    nrow(new_data),
    " | Total records: ",
    nrow(base_up)
  )

  return(base_up)
}

download_data <- function(url, filename, force = FALSE) {

  tmp <- get_cache_dir()

  local_file <- file.path(tmp, filename)

  if (!file.exists(local_file) || force) {

    dir.create(tmp, recursive = TRUE, showWarnings = FALSE)

    utils::download.file(
      url = url,
      destfile = local_file,
      mode = "wb",
      quiet = FALSE
    )
  }

  local_file
}


download_data <- function(
    url,
    filename,
    force = FALSE
) {

  #local_file <- file.path(
  #  get_cache_dir(),
  #  filename
  #)

  if (!file.exists(local_file) || force) {

    utils::download.file(
      url,
      local_file,
      mode = "wb"
    )

  }

  local_file

}

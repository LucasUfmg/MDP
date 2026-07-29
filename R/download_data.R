download_data <- function(
    url,
    filename,
    force = FALSE
) {


  tmp <- "C:/Users/luktr/AppData/Local/R/cache/R/mdp"

  local_file <- file.path(
    tmp,
    #get_cache_dir(),
    filename
  )

  if (!file.exists(local_file) || force) {

    utils::download.file(
      url,
      local_file,
      mode = "wb"
    )

  }

  local_file

}

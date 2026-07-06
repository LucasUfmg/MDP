#' Get cache directory
#'
#' Returns the local cache directory used by pdm.
#'
#' @return Character string containing the cache path.
#' @export

get_cache_dir <- function() {

  cache_dir <- tools::R_user_dir(
    package = "mdp",
    which = "cache"
  )

  dir.create(
    cache_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )

  return(cache_dir)

}

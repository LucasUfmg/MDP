#' Fires download update months
#'
#' @param ano_inicial Start year
#' @param ano_final End year
#' @param mes_inicial Start month
#' @param mes_final End month
#' @export

# Focos

update_fires <- function(mes_inicial,mes_final,ano_inicial,ano_final) {

  if(ano_inicial > 2025){
    cat("Base de focos usada de 2025")
    ano_inicial <- 2025 - 4
    ano_final <- 2025
  } else {
    ano_inicial <- ano_inicial - 4
  }

  # 5. State dictionary
  uf_dict <- tibble::tribble(
    ~sigla, ~nome_completo,
    "AC",   "ACRE",
    "AP",   "AMAP\u00c1",
    "RO",   "ROND\u00d4NIA",
    "PA",   "PARA",
    "AM",   "AMAZONAS",
    "MT",   "MATO GROSSO",
    "RR",   "RORAIMA"
  )

  nomes_norte <- uf_dict$nome_completo
  start_date <- as.Date(paste0(ano_inicial,"-",mes_inicial,"-01"))
  end_date <- as.Date(paste0(ano_final,"-",mes_final,"-01"))



  # 6. Download missing fire spots
  new_data <- try(
    queimadasR::download_fire_spots(
      start_date_str = format(start_date, "%d/%m/%Y"),
      end_date_str = format(end_date, "%d/%m/%Y"),
      target_states = nomes_norte,
      target_satellites = c("AQUA_M-T"),
      timeout = 1800,
      deduplicate_final = TRUE
    ),
    silent = TRUE
  )

  # 7. Check download
  if (
    inherits(new_data, "try-error") ||
    is.null(new_data) ||
    nrow(new_data) == 0
  ) {
    message("No new fire spots found.")
    return(new_data)
  }

  message(
    nrow(new_data),
    " new fire spots found."
  )

  # 8. Standardize new data
  new_data <- new_data |>
    dplyr::mutate(
      data_pas = as.Date(.data$data_pas,format = "%d/%m/%Y"),
      ano = format(.data$data_pas, "%Y"),
      mes = format(.data$data_pas, "%m"),
      anomes = format(.data$data_pas, "%Y-%m"),
      estado = toupper(.data$estado)
    )

  # 9. Merge datasets
  #base_up <- dplyr::bind_rows(
  #  base,
  #  new_data
  #)

  # 10. Remove duplicated fire spots
  base_up <- new_data |>
    dplyr::distinct(
      .data$data_pas,
      .data$latitude,
      .data$longitude,
      .keep_all = TRUE
    )

  message(
    "Fire dataset updated. Total records: ",
    nrow(base_up)
  )

  return(base_up)
}


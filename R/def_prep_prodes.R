#' Prepare dataset for monthly prioritization
#'
#' Aggregates deforestation, fire, and distance variables into 25km grid.
#'
#' @param folder Path to data folder
#' @param ano_inicial Start year
#' @param ano_final End year
#' @param mes_inicial Start month
#' @param mes_final End month
#' @param annual Logical, whether to run PRODES or DETER
#'
#' @return Data frame with aggregated results
#' @export
def_prep_prodes <- function(folder, ano_inicial, ano_final,mes_inicial, mes_final, annual) {

  # Disable S2 (safe for package use)
  sf::sf_use_s2(FALSE)

  # Create output folder if needed
  if (!dir.exists(file.path(folder, "tabelas"))) {
    dir.create(file.path(folder, "tabelas"), recursive = TRUE)
  }

  # Load data
  #deter <- sf::st_read(file.path(folder, "deter-amz-deter-public.shp"), quiet = TRUE)
  #deter <- get_deforestation()

    message("Running with PRODES in def_prep...")
    deter <- update_deforestation_prodes() # chave para trazer dados atualizados
    deter <- ensure_crs(deter)
    deter <- sf::st_cast(deter, "POLYGON")
    message("PRODES loaded.")


  q <- load_ext_shp("Grade_Random_Forest.shp")
  qt <- ensure_crs(q, sf::st_crs(deter))

  #df_focos <- sf::read_sf(file.path(folder, "focos_2016_2024.shp"), quiet = TRUE)
  #df_focos <- get_focos()
  df_focos <- update_fires(ano_inicial = ano_inicial,
                         ano_final = ano_final,
                        mes_inicial = 1,
                       mes_final = 12)
  #df_focos <- ensure_crs(df_focos, sf::st_crs(deter))

  points <- load_ext_shp("Pontos.shp")
  points <- ensure_crs(points, sf::st_crs(deter))

  q_deter <- qt

  # Loop
  year_list <- data.frame()

  for (i in ano_inicial:ano_final) {

    lag_list <- data.frame()

    for (k in c(-1, 0, 1, 3)) {

      # -------------------------
      # Build filtered deter (d)
      # -------------------------

      d <- deter

      if (k == -1) {# proprio ano

        d <- d |>
          dplyr::filter(
            year == i#,
            #lubridate::month(VIEW_DATE) == j,
            #CLASSNAME %in% c("DESMATAMENTO_CR", "DESMATAMENTO_VEG", "MINERACAO")
          ) |>
          #dplyr::select(CLASSNAME, UF, MUNICIPALI) |>
          sf::st_transform(sf::st_crs(deter))

      } else {

        d <- d |>
          dplyr::filter(
           year >= i - 1 - k,
            year <= i - 1#,
            #CLASSNAME %in% c("DESMATAMENTO_CR", "DESMATAMENTO_VEG", "MINERACAO")
          ) |>
          #dplyr::select(CLASSNAME, UF, MUNICIPALI) |>
          sf::st_transform(sf::st_crs(deter))
      }

      # -------------------------
      # Aggregate deforestation
      # -------------------------

      patches_in_region <- dplyr::left_join(
        q_deter,
        d |>
          dplyr::mutate(area_m2 = sf::st_area(.data$geometry), year = i) |>
          sf::st_join(q_deter, join = sf::st_intersects) |>
          sf::st_drop_geometry() |>
          dplyr::group_by(OBJECTID) |>
          dplyr::summarise(s = sum(area_m2, na.rm = TRUE), .groups = "drop"),
        by = "OBJECTID"
      ) |>
        dplyr::mutate(s = ifelse(is.na(s), 0, s))

      # -------------------------
      # Distance calculation
      # -------------------------

      nearest_id <- sf::st_nearest_feature(points, patches_in_region)

      dist_m <- sf::st_distance(
        points,
        patches_in_region[nearest_id, ],
        by_element = TRUE
      )

      poly_atts <- sf::st_drop_geometry(
        d[nearest_id, #c("CLASSNAME", "UF", "MUNICIPALI"),
          drop = FALSE]
      )

      points$poly_id <- nearest_id
      points$dist_m <- as.numeric(dist_m)
      points <- cbind(points, poly_atts)

      points_no_geom <- sf::st_drop_geometry(points)

      # -------------------------
      # Fire aggregation
      # -------------------------

      df_focos <- sf::st_as_sf(
        df_focos,
        coords = c("longitude", "latitude"),
        crs = 4326)

      df_focos <- ensure_crs(df_focos, sf::st_crs(qt))

      f <- dplyr::left_join(
        qt,
       tmp <- df_focos |>
          #dplyr::filter(Month == j) |>
          #dplyr::filter(.data$mes == j) |>
          #sf::st_transform(sf::st_crs(qt)) |>
          sf::st_join(qt) |>
          sf::st_drop_geometry() |>
          #dplyr::group_by(Id, Month) |>
          dplyr::group_by(Id) |> #, .data$mes
          dplyr::summarise(n = dplyr::n(), .groups = "drop") |>
          dplyr::rename(OBJECTID = Id),
        by = "OBJECTID"
      ) |>
        dplyr::mutate(
          n = ifelse(is.na(.data$n), 0, .data$n),
          #Month = j
          #mes = j

        )

      # -------------------------
      # Merge outputs
      # -------------------------

      patches_df <- sf::st_drop_geometry(sf::st_transform(patches_in_region, sf::st_crs(points)))
      #fire_df <- sf::st_drop_geometry(sf::st_transform(f, sf::st_crs(points)))

      fire_df <- sf::st_drop_geometry(sf::st_transform(f, sf::st_crs(points)))

      df_final <- fire_df |>
        dplyr::left_join(patches_df[, c("OBJECTID", "s")], by = "OBJECTID") |>
        dplyr::left_join(points_no_geom[, c("OBJECTID", "dist_m")], by = "OBJECTID")

      df_final_f <- df_final |>
        dplyr::rename(focos = n, area_deter_m2 = s) |>
        dplyr::mutate(year = i, lag = k)

      lag_list <- rbind(lag_list, df_final_f)
    }

    year_list <- rbind(lag_list, year_list)
  }

  utils::write.csv(
    year_list,
    file.path(folder, "tabelas",
              paste0("df_operacionalizado_prodes_", ano_inicial, "_", ano_final, ".csv")),
    row.names = FALSE
  )
}

#' Visualize prioritization results
#'
#' @param folder Character. Path to root folder.
#' @param annual Character. Path to root folder.
#' @param mes_inicial Integer. Initial month (1–12).
#' @param mes_final Integer. Final month (1–12).
#' @param ano_inicial Integer. Initial year defined by the user
#' @param ano_final Integer. Final year defined by the user
#' @return Invisibly returns NULL.
#' @export

def_viz <- function(folder, mes_inicial, mes_final, ano_final, ano_inicial, annual) {

  sf::sf_use_s2(FALSE)

  # ============================================================
  # CONFIGURATION
  # ============================================================

  if (annual == T) {
    months <- 1
    output_path <- file.path(folder, "outputs")

  } else {
    months <- mes_inicial:mes_final
  }

  dir.create(output_path, recursive = TRUE, showWarnings = FALSE)


  # ============================================================
  # LOAD DEFORESTATION DATA
  # ============================================================

  if (annual == T) {

    message("Running with PRODES in def_viz...")

    deter <- update_deforestation_prodes()
    deter <- ensure_crs(deter)
    deter <- sf::st_cast(deter, "POLYGON")

    message("PRODES loaded.")

  } else {

    message("Running with DETER in def_viz...")

    deter <- update_deforestation()
    deter <- ensure_crs(deter)

    message("DETER loaded.")
  }


  # ============================================================
  # OBJECTS THAT WILL STORE ALL YEARS
  # ============================================================

  result_all <- data.frame()
  dff_all <- data.frame()


  # ============================================================
  # LOOP OVER YEARS
  # ============================================================

  for (yr in ano_inicial:ano_final) {

    message("Processing year: ", yr)

    # ------------------------------------------------------------
    # OUTPUT PATH
    # ------------------------------------------------------------

    if (annual == T) {

      # All annual outputs go to ONE folder
      save_path <- output_path

    } else {

      # Monthly mode keeps one folder per year
      save_path <- file.path(folder, "outputs", yr)

      dir.create(
        save_path,
        recursive = TRUE,
        showWarnings = FALSE
      )
    }


    # Objects for this year
    result <- data.frame()
    dff <- data.frame()


    # ============================================================
    # LOOP OVER MONTHS
    # ============================================================

    for (i in months) {

      # ----------------------------------------------------------
      # PRIORITIZATION
      # ----------------------------------------------------------


        # Monthly mode:
        # keep the original structure
        prio_path <- file.path(
          save_path,
          paste0(yr,"/v", i),
          "priorizacao.gpkg"
        )



      prio <- sf::st_read(prio_path)


      # Define NA prioritization as LOW
      prio <- prio |>
        dplyr::mutate(
          priority1 = dplyr::case_when(
            is.na(priority) ~ "Low",
            TRUE ~ as.character(priority)
          )
        )


      # ----------------------------------------------------------
      # CRS
      # ----------------------------------------------------------

      if (sf::st_crs(prio) != sf::st_crs(deter)) {
        prio <- sf::st_transform(
          prio,
          sf::st_crs(deter)
        )
      }


      # ==========================================================
      # DEFORESTATION DATA
      # ==========================================================

      if (annual == T) {

        d <- deter |>
          dplyr::filter(year == yr)

      } else {

        d <- deter |>
          dplyr::filter(
            lubridate::year(VIEW_DATE) == yr &
              lubridate::month(VIEW_DATE) == i &
              CLASSNAME %in% c(
                "DESMATAMENTO_CR",
                "DESMATAMENTO_VEG",
                "MINERACAO"
              )
          )
      }


      d <- sf::st_make_valid(d)


      # ==========================================================
      # PLOT 1 - PRIORITIZATION MAP
      # ==========================================================

      if (annual == T) {

        map_path <- file.path(
          save_path,
          paste0("map_", yr, ".png")
        )

      } else {

        map_path <- file.path(
          save_path,
          paste0("v", i),
          paste0("plot_", i, ".png")
        )

        dir.create(
          dirname(map_path),
          recursive = TRUE,
          showWarnings = FALSE
        )
      }


      grDevices::png(
        map_path,
        width = 3000,
        height = 2400,
        res = 300
      )

      print(
        ggplot2::ggplot(prio) +
          ggplot2::geom_sf(
            ggplot2::aes(fill = priority1)
          ) +
          ggplot2::geom_sf(
            data = d
          ) +
          ggplot2::theme_minimal()
      )

      grDevices::dev.off()


      # ==========================================================
      # SPATIAL JOIN
      # ==========================================================

      patches_touching1 <- d |>
        sf::st_join(
          prio |>
            dplyr::select(dplyr::all_of("priority1")),
          join = sf::st_intersects,
          left = FALSE
        ) |>
        dplyr::distinct() |>
        dplyr::mutate(
          area_m2 = as.numeric(
            sf::st_area(.data$geometry)
          )
        ) |>
        sf::st_drop_geometry()


      has_deter <- lengths(
        sf::st_intersects(prio, d)
      ) > 0


      grid_with_patches <- prio |>
        dplyr::mutate(
          has_patch = lengths(
            sf::st_intersects(prio, d)
          ) > 0
        ) |>
        dplyr::mutate(
          category = dplyr::case_when(
            priority1 == "High" & has_deter ~ "High + Patch",
            priority1 == "High" & !has_deter ~ "High + No Patch",
            TRUE ~ "Other"
          )
        )


      # ==========================================================
      # PLOT 2 - COMMISSION ERROR MAP
      # ==========================================================

      if (annual == T) {

        map_path <- file.path(
          save_path,
          paste0("erro_comissao_MAPA_", yr, ".png")
        )

      } else {

        map_path <- file.path(
          save_path,
          paste0("v", i),
          paste0("erro_comissao_MAPA_", i, ".png")
        )
      }


      grDevices::png(
        map_path,
        width = 3000,
        height = 2400,
        res = 300
      )

      print(
        ggplot2::ggplot() +
          ggplot2::geom_sf(
            data = grid_with_patches,
            ggplot2::aes(fill = category),
            color = "grey30",
            size = 0.1
          ) +
          ggplot2::geom_sf(
            data = d,
            fill = NA,
            color = "black",
            size = 0.2
          ) +
          ggplot2::scale_fill_manual(
            values = c(
              "High + Patch" = "green",
              "High + No Patch" = "red",
              "Other" = "lightgrey"
            )
          ) +
          ggplot2::theme_minimal()
      )

      grDevices::dev.off()


      # ==========================================================
      # HISTORICAL SERIES
      # ==========================================================

      prio1 <- prio |>
        dplyr::mutate(
          has_deter = has_deter
        )


      prio2 <- prio1 |>
        dplyr::mutate(
          high_with_deter =
            priority1 == "High" & has_deter
        )


      prio_summary <- prio2 |>
        dplyr::mutate(
          interaction_var =
            interaction(priority1, has_deter)
        ) |>
        dplyr::filter(
          interaction_var %in%
            c("High.FALSE", "High.TRUE")
        ) |>
        dplyr::group_by(interaction_var) |>
        dplyr::summarise(
          n = dplyr::n(),
          .groups = "drop"
        ) |>
        sf::st_drop_geometry() |>
        dplyr::mutate(
          year = yr,
          month = if (annual == T) 1 else i
        )


      dff <- rbind(
        dff,
        prio_summary
      )


      # ==========================================================
      # COMMISSION RATE
      # ==========================================================

      high_cells <- grid_with_patches |>
        dplyr::filter(
          priority1 == "High"
        )

      n_total_high <- nrow(high_cells)


      commission_errors <- grid_with_patches |>
        dplyr::filter(
          priority1 == "High" &
            has_patch == FALSE
        )


      n_commission <- nrow(
        commission_errors
      )


      commission_rate <-
        n_commission / n_total_high


      # ==========================================================
      # AREA BY REGION
      # ==========================================================

      area_by_region <- patches_touching1 |>
        dplyr::group_by(priority1) |>
        dplyr::summarise(
          area_tot = sum(area_m2),
          .groups = "drop"
        ) |>
        dplyr::mutate(
          area_comp = sum(area_tot)
        ) |>
        dplyr::mutate(
          p = 100 * area_tot / area_comp,
          ref_yer = if (annual == T) yr else i,
          comission_rate = commission_rate,
          year = yr
        ) |>
        dplyr::select(
          priority1,
          p,
          ref_yer,
          comission_rate,
          year
        )


      result <- rbind(
        result,
        area_by_region
      )
    }


    # ============================================================
    # SAVE THIS YEAR INTO GLOBAL OBJECTS
    # ============================================================

    result_all <- rbind(
      result_all,
      result
    )

    dff_all <- rbind(
      dff_all,
      dff
    )


    # ============================================================
    # MONTHLY MODE:
    # GRAPHS ARE GENERATED INSIDE EACH YEAR
    # ============================================================

    if (annual == F) {

      # ----------------------------------------------------------
      # PLOT 3 - PERCENTUAL
      # ----------------------------------------------------------

      grDevices::png(
        file.path(
          save_path,
          "plot_percentual.png"
        ),
        width = 4000,
        height = 3000,
        res = 300
      )

      print(
        result |>
          ggplot2::ggplot() +
          ggplot2::aes(
            x = ref_yer,
            y = p,
            color = priority1
          ) +
          ggplot2::geom_point(size = 2.5) +
          ggplot2::geom_line(size = 1.1) +
          ggplot2::scale_x_continuous(
            breaks = 1:12,
            labels = month.name
          ) +
          ggplot2::ylab("%") +
          ggplot2::geom_text(
            ggplot2::aes(
              label = round(p, 2)
            ),
            vjust = -0.5,
            size = 4
          ) +
          ggplot2::theme_classic(
            base_size = 16
          )
      )

      grDevices::dev.off()


      # ----------------------------------------------------------
      # PLOT 4 - COMMISSION
      # ----------------------------------------------------------

      grDevices::png(
        file.path(
          save_path,
          "comissao.png"
        ),
        width = 3000,
        height = 3000,
        res = 300
      )

      print(
        result |>
          dplyr::group_by(ref_yer) |>
          dplyr::summarise(
            n = mean(comission_rate * 100),
            .groups = "drop"
          ) |>
          ggplot2::ggplot() +
          ggplot2::aes(
            x = ref_yer,
            y = n
          ) +
          ggplot2::geom_point(size = 2.5) +
          ggplot2::geom_line(size = 1.1) +
          ggplot2::scale_x_continuous(
            breaks = 1:12,
            labels = month.name
          ) +
          ggplot2::geom_text(
            ggplot2::aes(
              label = round(n, 2)
            ),
            vjust = -1,
            size = 4
          ) +
          ggplot2::ggtitle(
            "Comission Erros"
          ) +
          ggplot2::theme_classic(
            base_size = 16
          )
      )

      grDevices::dev.off()


      # ----------------------------------------------------------
      # PLOT 5 - FINAL COMMISSION ERROR
      # ----------------------------------------------------------

      grDevices::png(
        file.path(
          save_path,
          "erro_comissao_final.png"
        ),
        width = 3000,
        height = 2400,
        res = 300
      )

      print(
        dff |>
          dplyr::mutate(
            month = factor(
              month,
              levels = 1:12,
              labels = month.abb
            )
          ) |>
          dplyr::group_by(month) |>
          dplyr::mutate(
            perc = n / sum(n) * 100
          ) |>
          ggplot2::ggplot(
            ggplot2::aes(
              x = month,
              y = n,
              fill = interaction_var
            )
          ) +
          ggplot2::geom_col(
            position = "dodge"
          ) +
          ggplot2::geom_text(
            ggplot2::aes(
              label = paste0(
                round(perc, 1),
                "%"
              )
            ),
            position = ggplot2::position_dodge(0.8),
            vjust = -0.5
          ) +
          ggplot2::theme_minimal()
      )

      grDevices::dev.off()
    }
  }


  # ============================================================
  # ANNUAL MODE:
  # GENERATE GRAPHS ONCE USING ALL YEARS
  # ============================================================

  if (annual == T) {

    # ------------------------------------------------------------
    # PLOT 3 - PERCENTUAL
    # ------------------------------------------------------------

    grDevices::png(
      file.path(
        output_path,
        "plot_percentual.png"
      ),
      width = 4000,
      height = 3000,
      res = 300
    )

    print(
      result_all |>
        ggplot2::ggplot() +
        ggplot2::aes(
          x = year,
          y = p,
          color = priority1
        ) +
        ggplot2::geom_point(size = 2.5) +
        ggplot2::geom_line(
          ggplot2::aes(
            group = priority1
          ),
          size = 1.1
        ) +
        ggplot2::geom_text(
          ggplot2::aes(
            label = round(p, 2)
          ),
          vjust = -0.5,
          size = 4
        ) +
        ggplot2::xlab("Year") +
        ggplot2::ylab("%") +
        ggplot2::theme_classic(
          base_size = 16
        )
    )

    grDevices::dev.off()


    # ------------------------------------------------------------
    # PLOT 4 - COMMISSION
    # ------------------------------------------------------------

    grDevices::png(
      file.path(
        output_path,
        "comissao.png"
      ),
      width = 3000,
      height = 3000,
      res = 300
    )

    commission_plot <- result_all |>
      dplyr::group_by(year) |>
      dplyr::summarise(
        n = mean(comission_rate * 100),
        .groups = "drop"
      )

    print(
      commission_plot |>
        ggplot2::ggplot() +
        ggplot2::aes(
          x = year,
          y = n
        ) +
        ggplot2::geom_point(size = 2.5) +
        ggplot2::geom_line(size = 1.1) +
        ggplot2::geom_text(
          ggplot2::aes(
            label = round(n, 2)
          ),
          vjust = -1,
          size = 4
        ) +
        ggplot2::xlab("Year") +
        ggplot2::ylab("Commission errors (%)") +
        ggplot2::ggtitle(
          "Commission Errors"
        ) +
        ggplot2::theme_classic(
          base_size = 16
        )
    )

    grDevices::dev.off()


    # ------------------------------------------------------------
    # PLOT 5 - FINAL COMMISSION ERROR
    # ------------------------------------------------------------

    grDevices::png(
      file.path(
        output_path,
        "erro_comissao_final.png"
      ),
      width = 3000,
      height = 2400,
      res = 300
    )

    print(
      dff_all |>
        dplyr::group_by(year, month) |>
        dplyr::mutate(
          perc = n / sum(n) * 100
        ) |>
        ggplot2::ggplot(
          ggplot2::aes(
            x = year,
            y = n,
            fill = interaction_var
          )
        ) +
        ggplot2::geom_col(
          position = "dodge"
        ) +
        ggplot2::geom_text(
          ggplot2::aes(
            label = paste0(
              round(perc, 1),
              "%"
            )
          ),
          position = ggplot2::position_dodge(0.8),
          vjust = -0.5
        ) +
        ggplot2::xlab("Year") +
        ggplot2::theme_minimal()
    )

    grDevices::dev.off()
  }


  invisible(
    list(
      result = result_all,
      dff = dff_all
    )
  )
}








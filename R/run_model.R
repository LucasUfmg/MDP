#' Run full MDP pipeline
#'
#' Executes def_prep, def_prio, and def_viz sequentially.
#'
#' @param folder Path to root folder
#' @param ano_inicial Start year
#' @param ano_final End year
#' @param mes_inicial Start month
#' @param mes_final End month
#' @param run_prio Logical
#' @param run_prep Logical, whether to run def_prep
#' @param annual Logical, whether to run PRODES or DETER
#' @param data_ano_max Maximum year available in the dataset
#' @param data_mes_max Maximum month available in the dataset
#' @param allow_partial Logical, whether to automatically use the
#'   available period when the requested period exceeds the data
#' @export
run_pipeline <- function(
    folder,
    ano_inicial = NULL,
    ano_final = NULL,
    mes_inicial = NULL,
    mes_final = NULL,
    run_prio = TRUE,
    run_prep = TRUE,
    annual = FALSE,
    data_ano_max = NULL,
    data_mes_max = NULL,
    allow_partial = TRUE
) {

  # ------------------------------------------------------------
  # DEFAULTS
  # ------------------------------------------------------------

  if (is.null(ano_inicial)) {
    message("Using default initial year...")
    ano_inicial <- 2018
  }

  if (is.null(ano_final)) {
    message("Using default final year...")
    ano_final <- 2022
  }

  if (is.null(mes_inicial)) {
    message("Using default initial month...")
    mes_inicial <- 1
  }

  if (is.null(mes_final)) {
    message("Using default final month...")
    mes_final <- 12
  }


  # ------------------------------------------------------------
  # DATA AVAILABILITY CHECK
  # ------------------------------------------------------------

  data_ano_max <- mdp_config$deter$ano_max
  data_mes_max <- mdp_config$deter$mes_max

  if (!isTRUE(annual) &&
      !is.null(data_ano_max) &&
      !is.null(data_mes_max)) {

    # Only restrict the final month when the requested
    # final year is the current maximum available year.
    if (ano_final == data_ano_max &&
        mes_final > data_mes_max) {

      if (isTRUE(allow_partial)) {

        message(
          "Requested period extends beyond available data."
        )

        message(
          sprintf(
            "Requested: %02d/%d",
            mes_final,
            ano_final
          )
        )

        message(
          sprintf(
            "Available data ends at: %02d/%d",
            data_mes_max,
            data_ano_max
          )
        )

        warning(
          sprintf(
            "Data are only available until %02d/%d. ",
            data_mes_max,
            data_ano_max
          ),
          "The pipeline will run using the available period only."
        )

        # Adjust only the final month
        mes_final <- data_mes_max

      } else {

        stop(
          sprintf(
            paste0(
              "Requested period ends at %02d/%d, ",
              "but data are only available until %02d/%d."
            ),
            mes_final,
            ano_final,
            data_mes_max,
            data_ano_max
          )
        )
      }
    }
  }

  # ------------------------------------------------------------
  # CHECK VALID PERIOD
  # ------------------------------------------------------------

  if (mes_inicial < 1 || mes_inicial > 12) {
    stop("mes_inicial must be between 1 and 12.")
  }

  if (mes_final < 1 || mes_final > 12) {
    stop("mes_final must be between 1 and 12.")
  }

  if (ano_inicial > ano_final) {
    stop("ano_inicial cannot be greater than ano_final.")
  }


  # ------------------------------------------------------------
  # INFORMATION
  # ------------------------------------------------------------

  message(
    sprintf(
      "Running period: %02d/%d to %02d/%d",
      mes_inicial,
      ano_inicial,
      mes_final,
      ano_final
    )
  )

  if (isTRUE(annual)) {
    message("Running with PRODES...")
  } else {
    message("Running with DETER...")
  }


  # ------------------------------------------------------------
  # PREPARATION
  # ------------------------------------------------------------

  if (isTRUE(run_prep)) {

    if (isTRUE(annual)) {

      message("Running def_prep_prodes...")

      def_prep_prodes(
        folder = folder,
        ano_inicial = ano_inicial,
        ano_final = ano_final,
        annual = annual
      )

      message("def_prep_prodes completed.")

    } else {

      message("Running def_prep...")

      def_prep(
        folder = folder,
        ano_inicial = ano_inicial,
        ano_final = ano_final,
        mes_inicial = mes_inicial,
        mes_final = mes_final,
        annual = annual
      )

      message("def_prep completed.")
    }

  } else {

    message("Skipping def_prep.")
  }


  # ------------------------------------------------------------
  # PRIORITIZATION
  # ------------------------------------------------------------

  if (isTRUE(run_prio)) {

    message("Running def_prio...")

    def_prio(
      folder = folder,
      ano_inicial = ano_inicial,
      ano_final = ano_final,
      mes_inicial = mes_inicial,
      mes_final = mes_final,
      annual = annual
    )

    message("def_prio completed.")

  } else {

    message("Skipping def_prio.")
  }


  # ------------------------------------------------------------
  # VISUALIZATION
  # ------------------------------------------------------------

  message("Running def_viz...")

  def_viz(
    folder = folder,
    mes_inicial = mes_inicial,
    mes_final = mes_final,
    ano_final = ano_final,
    ano_inicial = ano_inicial,
    annual = annual
  )

  message("def_viz completed.")


  # ------------------------------------------------------------
  # FINISHED
  # ------------------------------------------------------------

  message(
    sprintf(
      "Pipeline finished successfully for %02d/%d to %02d/%d.",
      mes_inicial,
      ano_inicial,
      mes_final,
      ano_final
    )
  )

  invisible(
    list(
      ano_inicial = ano_inicial,
      ano_final = ano_final,
      mes_inicial = mes_inicial,
      mes_final = mes_final
    )
  )
}

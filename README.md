# Installation

You can install the required packages directly from GitHub:

```r
# Install devtools if needed
install.packages("devtools")

# Install package dependencies
devtools::install_github("albhasan/prioritizedeforestationhotspots")
devtools::install_github("LucasUfmg/MDP")
devtools::install_github("wtassinari/queimadasR")

```

# Load the packages

```r
library(prioritizedeforestationhotspots)
library(mdp)
library(queimadasR)
```

# Minimal example

Run the complete pipeline by specifying your working directory and the desired time period.

```r
mdp::run_pipeline(
  folder      = "C:/Users/luktr/Desktop/lucas/testa_pacote",  # Path to the project directory
  mes_inicial = 1,
  mes_final   = 1,
  ano_inicial = 2024,
  ano_final   = 2025,
  run_prep    = T, # if TRUE function builds data base at 25x25 grid 
  run_prio    = T, # if TRUE function runs the random forest model
  annual = T) # if TRUE funtion runs with PRODES at annual basis, otherwise it runs with DETER at monthly basis
```

### Arguments

| Argument | Description |
|----------|-------------|
| `folder` | Path to the project directory. |
| `mes_inicial` | Initial month to process. |
| `mes_final` | Final month to process. |
| `ano_inicial` | Initial year to process. |
| `ano_final` | Final year to process. |
| `run_prep` | Run the data preparation step (`TRUE`/`FALSE`). |
| `run_prio` | Run the model step (`TRUE`/`FALSE`). |
| `annual` | Run model annual or monthyl step (`TRUE`/`FALSE`). |


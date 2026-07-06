# Installation

You can install the required packages directly from GitHub:

```r
# Install devtools if needed
install.packages("devtools")

# Install package dependencies
devtools::install_github("albhasan/prioritizedeforestationhotspots")
devtools::install_github("LucasUfmg/mdp")
```

# Load the packages

```r
library(prioritizedeforestationhotspots)
library(mdp)
```

# Minimal example

Run the complete pipeline by specifying your working directory and the desired time period.

```r
mdp::run_pipeline(
  folder      = "your_path_here",  # Path to the project directory
  mes_inicial = 9,
  mes_final   = 9,
  ano_inicial = 2022,
  ano_final   = 2022,
  run_prep    = TRUE)
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


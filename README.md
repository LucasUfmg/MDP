# install.packages("devtools")
devtools::install_github("albhasan/prioritizedeforestationhotspots")
devtools::install_github("LucasUfmg/mdp")

library(prioritizedeforestationhotspots)
library(mdp)

# Minimal example
mdp::run_pipeline(folder = "your_path_here", # define the directory!
                  mes_inicial = 9,mes_final = 9, ano_inicial = 2022, 
                  ano_final = 2022, run_prep = T,run_prio = T)

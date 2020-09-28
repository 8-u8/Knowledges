# loading library
library(BTYD)      # Buy Till You Dead model(Survival Analysis)
library(tidyverse) # data tabulation.

# reference: https://cran.r-project.org/web/packages/BTYD/vignettes/BTYD-walkthrough.pdf

cdnow_log <- system.file("data/cdnowElog.csv", package = "BTYD")
ec_log <- BTYD::dc.ReadLines(cdnow_log,
                             cust.idx  = 2, # customers' ID
                             date.idx  = 3, # purchase features
                             sales.idx = 5  # sales features
                             )
class(ec_log) # data.frame
ec_log %>% head # chk

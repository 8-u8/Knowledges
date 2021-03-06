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
ec_log$date <- as.Date(ec_log$date, "%Y%m%d")
ec_log_MTOSD <- BTYD::dc.MergeTransactionsOnSameDate(ec_log)
class(ec_log_MTOSD)
end_of_cal_period <- as.Date("1997-09-30")
ec_log_MTOSD_cal <- ec_log_MTOSD[which(ec_log_MTOSD$date <= end_of_cal_period),]

# make two table
## repeat.trans.elog: 
## cust data: data columns defined bellow:
### cust: customers' ID
### birth.per: the date of first purchase in this data.
### first.sales: the sales value at birth per.
### last.date: the date of last purchase in this data.
### last.sales: the sales value at last.date
splited_data <- BTYD::dc.SplitUpElogForRepeatTrans(ec_log_MTOSD_cal)
cleaned_elog <- splited_data$repeat.trans.elog

head(splited_data$repeat.trans.elog)
head(splited_data$cust.data)

# pivot_wider?
freq_cbt <- BTYD::dc.CreateFreqCBT(cleaned_elog)
class(freq_cbt)

tot_cbt <- BTYD::dc.CreateFreqCBT(ec_log_MTOSD)
cal_cbt <- BTYD::dc.MergeCustomers(tot_cbt, freq_cbt)
# 
# class(tot_cbt)
# class(cal_cbt)
# 
# tot_cbt[1:3,1:5]
# cal_cbt[1:3,1:5]
# 
# dim(freq_cbt)
# dim(tot_cbt)
# dim(cal_cbt)

birth_periods <- splited_data$cust.data$birth.per
last_dates <- splited_data$cust.data$last.date
cal_cbs_dates <- data.frame(
  birth_periods, # first purchase by person
  last_dates,    # last purchase by person
  end_of_cal_period # last purchase on global
)

# What is it calculated??
## x: time definition: dialy/weekly/monthly/quartery/yeary.
## t.x: difference time per x.
## T.cal: difference between end_of_date and personal last purchase day per x.
cal_cbs <- BTYD::dc.BuildCBSFromCBTAndDates(as.data.frame(cal_cbt),       # cbt table.
                                            cal_cbs_dates, # dates parameter(end_of_cal_period).
                                            per = "week")
# parameter Estimation
params <- pnbd.EstimateParameters(cal.cbs = cal_cbs)
params
LL     <- pnbd.cbs.LL(params, cal_cbs)
LL

p_matrix <- c(params, LL);
for (i in 1:2){
  params <- pnbd.EstimateParameters(cal_cbs, params);
  LL <- pnbd.cbs.LL(params, cal_cbs);
  p_matrix_row <- c(params, LL);
  p_matrix <- rbind(p_matrix, p_matrix_row);
}
colnames(p_matrix) <- c("r", "alpha", "s", "beta", "LL");
# r: personal purchase parameter(maybe shape parameter of Gamma dist.)
# alpha: personal purchase parameter(maybe scale parameter of Gamma dist.)
# s: withdrawal ratio parameter(maybe shape parameter of Gamma)
# beta: withdrawal ratio parameter(maybe scale parameter of Gamma)

# then, we can predict personal purchase count and withdrawal ratio
# by above parameters.
rownames(p_matrix) <- 1:3
p_matrix


# fitting and expectation
## plot transaction parameters gamma(distribution lambda on Poisson)
pnbd.PlotTransactionRateHeterogeneity(params)
## plot droopout parameters gamma(distribution inversed mu on Exponential)
pnbd.PlotDropoutRateHeterogeneity(params)

pnbd.Expectation(params, t = 52)
exp_indivisual <- cal_cbs["1516",]
pnbd.ConditionalExpectedTransactions(params, T.star = 52,
                                     x = exp_indivisual[1],
                                     t.x = exp_indivisual[2],
                                     T.cal = exp_indivisual[3])
pnbd.PAlive(params,                  
            x = exp_indivisual[1],
            t.x = exp_indivisual[2],
            T.cal = exp_indivisual[3])











# data preparation for tidy style.
ec_log <- ec_log %>% 
    dplyr::mutate(cust=as.numeric(cust),
                  date = lubridate::ymd(date)) %>% 
    dplyr::arrange(cust) %>% 
    dplyr::group_by(cust, date) %>% 
    dplyr::summarise(sales = sum(sales)) %>% 
    dplyr::ungroup() %>% 
    dplyr::filter(date <= lubridate::ymd("1997-09-30"))
  
# dc.SplitUpElogForRepeatTrans with tidy style.
  
  

repeat_trans_elog <- ec_log  %>% 
  dplyr::group_by(cust) %>% 
  dplyr::mutate(birth_per = min(date)) %>% 
  dplyr::filter(date != birth_per) %>% 
  dplyr::ungroup()%>% 
  dplyr::select(-birth_per)

cust_data <- ec_log %>% 
  dplyr::group_by(cust) %>% 
  dplyr::mutate(birth_per = min(date),
                last_date = max(date)) %>% 
  dplyr::summarise(birth.per = birth_per[1],
                   last.date = last_date[1],
                   first.sales = sales[1],
                   last.sales  = sales[length(sales)]) %>% 
  dplyr::ungroup()

split_data_tidy <- list(repeat.trans.elog = repeat_trans_elog,
                        cust.data         = cust_data)
library(tidyverse)

UseData_JP <- readr::read_csv("covid19/data/individuals.csv") %>% 
  dplyr::mutate(yyyymmdd = lubridate::ymd(paste0(.$`確定年`,"-",.$`確定月`,"-",.$`確定日`))) %>% 
  dplyr::filter(str_detect(`居住地1`, pattern = "東京都")==TRUE) 

UseData_JP_2 <- UseData_JP %>% 
  dplyr::filter(yyyymmdd >= lubridate::ymd("2020-02-13")) %>% 
  group_by(yyyymmdd) %>% 
  summarise(amounts_by_day = n()) %>% 
  ungroup() %>% 
  dplyr::mutate(lags = dplyr::lag(amounts_by_day),
                lag_2wk = dplyr::lag(amounts_by_day, n=14),
                diff = amounts_by_day - lags,
                diff_2wk = amounts_by_day - lag_2wk,
                cum  = cumsum(amounts_by_day),
                ratio_by_lag = amounts_by_day/lags,
                ratio_by_lag2wk = amounts_by_day / lag_2wk,
                inc_ratio = amounts_by_day/sum(amounts_by_day),
                pareto = cum / sum(amounts_by_day),
                weekday = lubridate::wday(yyyymmdd))
trendy <- UseData_JP_2 %>% 
  group_by(weekday) %>% 
  summarise(mean_of_trend = mean(amounts_by_day)) %>% 
  ungroup

UseData_JP_2 <- UseData_JP_2 %>% 
  inner_join(trendy , by = "weekday") %>% 
  dplyr::mutate(diff_wkmean = amounts_by_day - mean_of_trend)

plot(UseData_JP_2$yyyymmdd, UseData_JP_2$diff_wkmean, type="b")
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==7], col ="blue") # sat
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==1], col ="red")  # sun
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==2], col ="green") # mon
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==3], col ="orange")# tue

trendline <- stl(ts(as.numeric(UseData_JP_2$amounts_by_day), frequency = 7), s.window = 'per')$time.series
UseData_JP_2 <- UseData_JP_2 %>% 
  dplyr::mutate(seasonal_shift = trendline[,1],
                trend_shift = trendline[,2],
                # amount_diff_seasonal = amounts_by_day - seasonal,
                # amount_diff_trend = amounts_by_day - trend,
  )

plot(UseData_JP_2$yyyymmdd, UseData_JP_2$seasonal_shift, type="b")
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==7], col ="blue") # sat
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==1], col ="red")  # sun
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==2], col ="green") # mon
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==3], col ="orange")# tue


Weather_JP_Tokyo <- read.csv("input/weather_data.csv", fileEncoding = "CP932")
Weather_JP_Tokyo$年月日 <- lubridate::ymd(Weather_JP_Tokyo$年月日)
plot(Weather_JP_Tokyo$年月日, scale(Weather_JP_Tokyo$日照時間.時間.), type ="b", ylim=c(-3,4))
par(new = T)
plot(UseData_JP_2$yyyymmdd,scale(trendline[,3]), type = "b", col=2, ylim = c(-3,4))
# par(new=T)
# plot(UseData_JP_2$yyyymmdd,scale(UseData_JP_2$amounts_by_day), type = "b", col=3, ylim = c(-3,4))
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==7], col ="blue") # sat
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==1], col ="red")  # sun
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==2], col ="green") # mon
abline(v=UseData_JP_2$yyyymmdd[UseData_JP_2$weekday==3], col ="orange")# tue

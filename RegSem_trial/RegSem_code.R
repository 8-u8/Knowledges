library(psych)
library(lavaan)
library(regsem)
data(bfi)

head(bfi)
# A1 A2 A3 A4 A5 C1 C2 C3 C4 C5 E1 E2 E3 E4 E5 N1 N2 N3 N4 N5 O1 O2 O3 O4 O5 gender education age
# 61617  2  4  3  4  4  2  3  3  4  4  3  3  3  4  4  3  4  2  2  3  3  6  3  4  3      1        NA  16
# 61618  2  4  5  2  5  5  4  4  3  4  1  1  6  4  3  3  3  3  5  5  4  2  4  3  3      2        NA  18
# 61620  5  4  5  4  4  4  5  4  2  5  2  4  4  4  5  4  5  4  2  3  4  2  5  5  2      2        NA  17
# 61621  4  4  6  5  5  4  4  3  5  5  5  3  4  4  4  2  5  2  4  1  3  3  4  3  5      2        NA  17
# 61622  2  3  3  4  5  4  4  5  3  2  2  2  5  4  5  2  3  4  4  3  3  3  4  3  3      1        NA  17
# 61623  6  6  5  6  5  6  6  6  1  3  2  1  6  5  6  3  5  2  2  3  4  3  5  6  1      2         3  21
bfi2 <- bfi[1:250, c(1:5, 18,22)]

bfi2[,1] <- psych::reverse.code(-1, bfi2[,1])

mod <- "
f1 =~ NA * A1 + A2 + A3 + A4 + A5 + O2 + N3
f1~~1*f1
"

## まず因子分析を行う
cfa_output <- lavaan::cfa(mod, bfi2)
summary(cfa_output)

## RAM行列とかいうのを取り出す
### https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4937830/
### Reticular Action Model
### https://www.researchgate.net/figure/Diagram-of-structural-equation-model-in-reticular-action-model-RAM-style-which-is_fig2_315733872
### こういう構造に対して有効。
### なんでも3つの行列（F,S,A）がある？
regsem::extractMatrices(cfa_output)$`S` # 潜在因子と通常変数の分散共分散行列

# A1 A2 A3 A4 A5 O2 N3 f1
# A1  8  0  0  0  0  0  0  0
# A2  0  9  0  0  0  0  0  0
# A3  0  0 10  0  0  0  0  0
# A4  0  0  0 11  0  0  0  0
# A5  0  0  0  0 12  0  0  0
# O2  0  0  0  0  0 13  0  0
# N3  0  0  0  0  0  0 14  0
# f1  0  0  0  0  0  0  0  0

regsem::extractMatrices(cfa_output)$`F` # 変数 × (変数+潜在因子)の行列

# A1 A2 A3 A4 A5 O2 N3 f1
# A1  1  0  0  0  0  0  0  0
# A2  0  1  0  0  0  0  0  0
# A3  0  0  1  0  0  0  0  0
# A4  0  0  0  1  0  0  0  0
# A5  0  0  0  0  1  0  0  0
# O2  0  0  0  0  0  1  0  0
# N3  0  0  0  0  0  0  1  0

regsem::extractMatrices(cfa_output)$`A` # 因子負荷量 論文中lambda

# A1 A2 A3 A4 A5 O2 N3 f1
# A1  0  0  0  0  0  0  0  1
# A2  0  0  0  0  0  0  0  2
# A3  0  0  0  0  0  0  0  3
# A4  0  0  0  0  0  0  0  4
# A5  0  0  0  0  0  0  0  5
# O2  0  0  0  0  0  0  0  6
# N3  0  0  0  0  0  0  0  7
# f1  0  0  0  0  0  0  0  0

start_time <- proc.time()
output_regsem <- regsem::cv_regsem(cfa_output, type = "lasso",
                                   pars_pen = c(1:7), # NULLにすると潜在因子がすべての変数にパスを飛ばす。
                                                      ## 今回は各変数に1個ずつ飛ばすパスを仮定。
                                   n.lambda = 15,     ## 罰則項
                                   jump = .05        ## 罰則項の刻み幅
                                   )
# 警告メッセージ: 
#   regsem(model = model, lambda = SHRINK, type = type, data = data,  で: 
#            WARNING: Model did not converge! It is recommended to try multi_optim()
end_time <- proc.time()
diff_time <- end_time - start_time
print(paste0("calculated! time is spend: ", diff_time[1], "seconds"))

library(tidyverse)
output_regsem$parameters %>% 
  round(., 2) %>% 
  head

# f1 -> A1 f1 -> A2 f1 -> A3 f1 -> A4 f1 -> A5 f1 -> O2 f1 -> N3 A1 ~~ A1 A2 ~~ A2 A3 ~~ A3 A4 ~~ A4 A5 ~~ A5 O2 ~~ O2
# [1,]     0.56     0.77     1.08     0.70     0.90    -0.03    -0.08     1.52     0.69     0.53     1.84     0.88     2.45
# [2,]     0.50     0.72     1.03     0.62     0.84     0.00    -0.01     1.54     0.70     0.52     1.85     0.90     2.45
# [3,]     0.44     0.67     0.98     0.55     0.78     0.00     0.00     1.53     0.71     0.52     1.85     0.90     2.45
# [4,]     0.39     0.63     0.95     0.49     0.74     0.00     0.00     1.57     0.72     0.51     1.89     0.92     2.45
# [5,]     0.34     0.60     0.92     0.44     0.70     0.00     0.00     1.58     0.73     0.50     1.92     0.93     2.45
# [6,]     0.30     0.57     0.90     0.38     0.67     0.00     0.00     1.60     0.75     0.50     1.94     0.94     2.45
# N3 ~~ N3
# [1,]     2.29
# [2,]     2.30
# [3,]     2.29
# [4,]     2.30
# [5,]     2.30
# [6,]     2.30

output_regsem$fits

# lambda conv   rmsea         BIC         chisq
# [1,]   0.00    0 0.08255    5713.574      37.08935
# [2,]   0.05    0 0.08213    5710.476      39.48472
# [3,]   0.10    0 0.08620    5710.270      44.77133
# [4,]   0.15    0 0.09553    5716.838      51.33941
# [5,]   0.20    0 0.10659    5725.489      59.99048
# [6,]   0.25    0 0.11836    5735.739      70.24050
# [7,]   0.30    0 0.13064    5747.581      82.08211
# [8,]   0.35    0 0.14345    5761.176      95.67710
# [9,]   0.40    0 0.15708    5777.038     111.53937
# [10,]   0.45    0 0.17225    5796.381     130.88249
# [11,]   0.50    0 0.19163    5823.694     158.19503
# [12,]   0.55    1 0.00000 -987208.231 -992884.71596
# [13,]   0.60    0 0.21395    5865.326     205.32088
# [14,]   0.65    0 0.22054    5869.831     204.33220
# [15,]   0.70    0 0.24312    5959.428     321.39495

plot(output_regsem, show.minimum = "BIC")  

library(testthat)
library(magrittr)
library(recipes)
library(tibble)

n <- 20
ex_dat <- data.frame(x1 = seq(0, 1, length = n),
                     x2 = rep(1:5, 4))

test_that('simple sqrt trans', {
  
      rec <- recipe(~., data = ex_dat) %>% 
        step_sqrt(x1, x2)
      
      rec_trained <- learn(rec, training = ex_dat, verbose = FALSE)
      rec_trans <- process(rec_trained, newdata = ex_dat)

      exp_res <- as_tibble(lapply(ex_dat, sqrt))
      expect_equal(rec_trans, exp_res)
  
})

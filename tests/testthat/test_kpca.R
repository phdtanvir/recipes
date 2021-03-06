library(testthat)
library(magrittr)
library(kernlab)
library(recipes)

set.seed(131)
tr_dat <- matrix(rnorm(100*6), ncol = 6)
te_dat <- matrix(rnorm(20*6), ncol = 6)
colnames(tr_dat) <- paste0("X", 1:6)
colnames(te_dat) <- paste0("X", 1:6)

rec <- recipe(X1 ~ ., data = tr_dat)

test_that('correct kernel PCA values', {
  kpca_rec <- rec %>%
    step_kpca(X2, X3, X4, X5, X6)
  
  kpca_trained <- learn(kpca_rec, training = tr_dat, verbose = FALSE)
  
  pca_pred <- process(kpca_trained, newdata = te_dat)
  pca_pred <- as.matrix(pca_pred)
  
  pca_exp <- kpca(as.matrix(tr_dat[, -1]), 
                  kernel = kpca_rec$steps[[1]]$options$kernel,
                  kpar = kpca_rec$steps[[1]]$options$kpar)

  pca_pred_exp <- kernlab::predict(pca_exp, te_dat[, -1])[, 1:kpca_trained$steps[[1]]$num]
  colnames(pca_pred_exp) <- paste0("kPC", 1:kpca_trained$steps[[1]]$num)
  
  rownames(pca_pred) <- NULL
  rownames(pca_pred_exp) <- NULL
  
  expect_equal(pca_pred, pca_pred_exp)
})


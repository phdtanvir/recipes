# Recipes


[![Build Status](https://travis-ci.org/topepo/recipes.svg?branch=master)](https://travis-ci.org/topepo/recipes)
[![Coverage Status](https://img.shields.io/codecov/c/github/topepo/recipes/master.svg)](https://codecov.io/github/topepo/recipes?branch=master)

The `recipes` package is an alternative method for creating and preprocessing design matrices that can be used for modeling or visualization. From [wikipedia](https://en.wikipedia.org/wiki/Design_matrix):

 > In statistics, a **design matrix** (also known as regressor matrix or model matrix) is a matrix of values of explanatory variables of a set of objects, often denoted by X. Each row represents an individual object, with the successive columns corresponding to the variables and their specific values for that object.

While R already has long-standing methods for creating these matrices (e.g. [formulas](https://www.rstudio.com/rviews/2017/02/01/the-r-formula-method-the-good-parts) and `model.matrix`), there are some limitations to what the existing infrastructure can do. 

The idea of the `recipes` package is to define a recipe or blueprint that can be used to sequentially define the encodings and preprocessing of the data (i.e. "feature engineering"). For example, to create a simple recipe containing only an outcome and predictors and have the predictors centered and scaled:


```r
library(recipes)
library(mlbench)
data(Sonar)
sonar_rec <- recipe(Class ~ ., data = Sonar) %>%
  step_center(all_predictors()) %>%
  step_scale(all_predictors())
```

The package is still in development and is not yet on CRAN. To install it, use:

```r
if (packageVersion("devtools") < 1.6) {
  install.packages("devtools")
}
devtools::install_github("topepo/recipes")
```

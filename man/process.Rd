% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/recipe.R
\name{process}
\alias{process}
\alias{process.recipe}
\alias{process.recipe}
\title{Apply a Trained Data Recipe}
\usage{
process(object, ...)

\method{process}{recipe}(object, newdata = object$template, ...)
}
\arguments{
\item{object}{A trained object such as a \code{\link{recipe}} with at least one preprocessing step.}

\item{...}{One or more selector functions to choose which variables will be returned by the function. See \code{\link{selections}} for more details. If no selectors are given, the default is to use \code{\link{all_predictors}}.}

\item{newdata}{A data frame or tibble for whom the preprocessing will be applied.}
}
\value{
A tibble that may have different columns than the original columns in \code{newdata}.
}
\description{
For a recipe with at least one preprocessing step that has been trained by \code{\link{learn.recipe}}, apply the computations to new data.
}
\details{
\code{\link{process}} takes a trained recipe and applies the operations to a data set to create a design matrix.

If the original data used to train the data are to be processed, time can be saved by using the \code{retain = TRUE} option of \code{\link{learn}} to avoid duplicating the same operations.

A tibble is always returned but can be easily converted to a data frame or matrix as needed.
}
\author{
Max Kuhn
}
\concept{
preprocessing model_specification
}
\keyword{datagen}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/misc.R
\name{step}
\alias{step}
\title{A General Step Wrapper}
\usage{
step(subclass, ...)
}
\arguments{
\item{subclass}{A character string for the resulting class. For example, if \code{subclass = "blah"} the step object that is returned has class \code{step_blah}.}

\item{...}{All arguments to the step that should be returned.}
}
\value{
A updated step with the new class.
}
\description{
\code{step} sets the class of the step.
}
\concept{
preprocessing
}
\keyword{datagen}

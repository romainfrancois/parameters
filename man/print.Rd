% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/print.parameters_model.R
\name{print}
\alias{print}
\alias{print.parameters_model}
\title{Print model parameters}
\usage{
\method{print}{parameters_model}(
  x,
  pretty_names = TRUE,
  split_components = TRUE,
  select = NULL,
  digits = 2,
  ci_digits = 2,
  p_digits = 3,
  ...
)
}
\arguments{
\item{x}{An object returned by \code{\link[=model_parameters]{model_parameters()}}.}

\item{pretty_names}{Pretty parameters' names.}

\item{split_components}{Logical, if \code{TRUE} (default), For models with
multiple components (zero-inflation, smooth terms, ...), each component is
printed in a separate table. If \code{FALSE}, model parameters are printed
in a single table and a \code{Component} column is added to the output.}

\item{select}{Character vector (or numeric index) of column names that should
be printed. If \code{NULL} (default), all columns are printed.}

\item{digits}{Number of decimal places for numeric values (except confidence intervals and p-values).}

\item{ci_digits}{Number of decimal places for confidence intervals.}

\item{p_digits}{Number of decimal places for p-values. May also be \code{"scientific"} for scientific notation of p-values.}

\item{...}{Arguments passed to or from other methods.}
}
\value{
\code{NULL}
}
\description{
A \code{print()}-method for objects from \code{\link[=model_parameters]{model_parameters()}}.
}
\examples{
library(parameters)
if (require("glmmTMB")) {
  model <- glmmTMB(
    count ~ spp + mined + (1 | site),
    ziformula = ~mined,
    family = poisson(),
    data = Salamanders
  )
  mp <- model_parameters(model)

  print(mp, pretty_names = FALSE)

  print(mp, split_components = FALSE)

  print(mp, select = c("Parameter", "Coefficient", "CI_low", "CI_high"))
}
}

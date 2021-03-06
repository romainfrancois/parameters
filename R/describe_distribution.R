#' Describe a distribution
#'
#' This function describes a distribution by a set of indices (e.g., measures of centrality, dispersion, range, skewness, kurtosis).
#'
#' @param x A numeric vector.
#' @param range Return the range (min and max).
#' @param include_factors Logical, if \code{TRUE}, factors are included in the output, however, only columns for range (first and last factor levels) as well as n and missing will contain information.
#' @param ci Confidence Interval (CI) level. Default is \code{NULL}, i.e. no confidence intervals are computed. If not \code{NULL}, confidence intervals are based on bootstrap replicates (see \code{iterations}).
#' @param iterations The number of bootstrap replicates for computing confidence intervals. Only applies when \code{ci} is not \code{NULL}.
#' @param iqr Logical, if \code{TRUE}, the interquartile range is calculated (based on \code{\link[stats]{IQR}}, using \code{type = 6}).
#' @inheritParams bayestestR::point_estimate
#'
#' @return A data frame with columns that describe the properties of the variables.
#' @examples
#' describe_distribution(rnorm(100))
#'
#' data(iris)
#' describe_distribution(iris)
#' describe_distribution(iris, include_factors = TRUE)
#' @export
describe_distribution <- function(x, ...) {
  UseMethod("describe_distribution")
}


#' @rdname describe_distribution
#' @importFrom stats na.omit IQR
#' @importFrom bayestestR ci
#' @export
describe_distribution.numeric <- function(x, centrality = "mean", dispersion = TRUE, iqr = TRUE, range = TRUE, ci = NULL, iterations = 100, ...) {
  out <- data.frame(.temp = 0)

  # Missing
  n_missing <- sum(is.na(x))
  x <- stats::na.omit(x)


  # Point estimates
  out <- cbind(
    out,
    bayestestR::point_estimate(x, centrality = centrality, dispersion = dispersion, ...)
  )


  # interquartile range, type same as minitab and SPSS
  if (iqr) {
    out$IQR <- stats::IQR(x, na.rm = TRUE, type = 6)
  }


  # Confidence Intervals
  if (!is.null(ci)) {
    if (!requireNamespace("boot", quietly = TRUE)) {
      warning("Package 'boot' needed for bootstrapping SEs.", call. = FALSE)
    } else {
      results <- boot::boot(data = x, statistic = .boot_distribution, R = iterations, centrality = centrality)
      out_ci <- bayestestR::ci(results$t, ci = ci, verbose = FALSE)
      out <- cbind(out, data.frame(CI_low = out_ci$CI_low[1], CI_high = out_ci$CI_high[1]))
    }
  }


  # Range
  if (range) {
    out <- cbind(
      out,
      data.frame(
        Min = min(x, na.rm = TRUE),
        Max = max(x, na.rm = TRUE)
      )
    )
  }


  # Skewness
  out <- cbind(
    out,
    data.frame(
      Skewness = as.numeric(skewness(x)),
      Kurtosis = as.numeric(kurtosis(x))
    )
  )

  out$n <- length(x)
  out$n_Missing <- n_missing
  out$`.temp` <- NULL

  class(out) <- unique(c("parameters_distribution", "see_parameters_distribution", class(out)))
  attr(out, "data") <- x
  attr(out, "ci") <- ci
  out
}





#' @rdname describe_distribution
#' @export
describe_distribution.factor <- function(x, dispersion = TRUE, range = TRUE, ...) {
  # Missing
  n_missing <- sum(is.na(x))
  x <- stats::na.omit(x)

  out <- data.frame(
    Mean = NA,
    SD = NA,
    CI_low = NA,
    CI_high = NA,
    IQR = NA,
    Min = levels(x)[1],
    Max = levels(x)[nlevels(x)],
    Skewness = as.numeric(skewness(x)),
    Kurtosis = as.numeric(kurtosis(x)),
    n = length(x),
    n_Missing = n_missing,
    stringsAsFactors = FALSE
  )


  if (!dispersion) {
    out$SD <- NULL
  }


  dot.arguments <- list(...)
  if (is.null(dot.arguments[["ci"]])) {
    out$CI_low <- NULL
    out$CI_high <- NULL
  }
  if (is.null(dot.arguments[["iqr"]])) {
    out$IQR <- NULL
  }


  if (!range) {
    out$Min <- NULL
    out$Max <- NULL
  }

  class(out) <- unique(c("parameters_distribution", "see_parameters_distribution", class(out)))
  attr(out, "data") <- x
  out
}



#' @export
describe_distribution.character <- function(x, dispersion = TRUE, range = TRUE, ...) {
  # Missing
  n_missing <- sum(is.na(x))
  x <- stats::na.omit(x)
  values <- unique(x)

  out <- data.frame(
    Mean = NA,
    SD = NA,
    IQR = NA,
    CI_low = NA,
    CI_high = NA,
    Min = values[1],
    Max = values[length(values)],
    Skewness = as.numeric(skewness(x)),
    Kurtosis = as.numeric(kurtosis(x)),
    n = length(x),
    n_Missing = n_missing,
    stringsAsFactors = FALSE
  )


  if (!dispersion) {
    out$SD <- NULL
  }


  dot.arguments <- list(...)
  if (is.null(dot.arguments[["ci"]])) {
    out$CI_low <- NULL
    out$CI_high <- NULL
  }
  if (is.null(dot.arguments[["iqr"]])) {
    out$IQR <- NULL
  }


  if (!range) {
    out$Min <- NULL
    out$Max <- NULL
  }

  class(out) <- unique(c("parameters_distribution", "see_parameters_distribution", class(out)))
  attr(out, "data") <- x
  out
}



#' @rdname describe_distribution
#' @export
describe_distribution.data.frame <- function(x, centrality = "mean", dispersion = TRUE, iqr = TRUE, range = TRUE, include_factors = FALSE, ci = NULL, iterations = 100, ...) {
  out <- do.call(rbind, lapply(x, function(i) {
    if ((include_factors && is.factor(i)) || (!is.character(i) && !is.factor(i))) {
      describe_distribution(i, centrality = centrality, dispersion = dispersion, iqr = iqr, range = range, ci = ci, iterations = iterations)
    }
  }))

  out$Variable <- row.names(out)
  row.names(out) <- NULL
  out <- out[c("Variable", setdiff(colnames(out), "Variable"))]

  class(out) <- unique(c("parameters_distribution", "see_parameters_distribution", class(out)))
  attr(out, "object_name") <- deparse(substitute(x), width.cutoff = 500)
  attr(out, "ci") <- ci
  out
}




#' @export
describe_distribution.grouped_df <- function(x, centrality = "mean", dispersion = TRUE, iqr = TRUE, range = TRUE, include_factors = FALSE, ci = NULL, iterations = 100, ...) {
  group_vars <- setdiff(colnames(attributes(x)$groups), ".rows")
  group_data <- expand.grid(lapply(x[group_vars], function(i) unique(sort(i))))
  groups <- split(x, x[group_vars])

  out <- do.call(rbind, lapply(1:length(groups), function(i) {
    d <- describe_distribution.data.frame(groups[[i]], centrality = centrality, dispersion = dispersion, iqr = iqr, range = range, include_factors = include_factors, ci = ci, iterations = iterations, ...)
    d[[".group"]] <- paste(sprintf("%s=%s", group_vars, sapply(group_data[i, ], as.character)), collapse = " | ")
    d
  }))

  class(out) <- unique(c("parameters_distribution", "see_parameters_distribution", class(out)))
  attr(out, "object_name") <- deparse(substitute(x), width.cutoff = 500)
  attr(out, "ci") <- ci
  out
}






#' @export
print.parameters_distribution <- function(x, digits = 2, ...) {
  orig_x <- x

  if (all(c("Min", "Max") %in% names(x))) {
    x$Min <- insight::format_ci(x$Min, x$Max, ci = NULL, digits = digits, width = "auto", brackets = TRUE)
    x$Max <- NULL
    colnames(x)[which(colnames(x) == "Min")] <- "Range"
  }

  if (all(c("CI_low", "CI_high") %in% names(x))) {
    x$CI_low <- insight::format_ci(x$CI_low, x$CI_high, ci = NULL, digits = digits, width = "auto", brackets = TRUE)
    x$CI_high <- NULL
    ci_lvl <- attributes(x)$ci
    if (!is.null(ci_lvl)) {
      colnames(x)[which(colnames(x) == "CI_low")] <- sprintf("%i%% CI", round(100 * ci_lvl))
    } else {
      colnames(x)[which(colnames(x) == "CI_low")] <- "CI"
    }
  }

  if (".group" %in% colnames(x)) {
    grps <- split(x, x[[".group"]])
    for (i in names(grps)) {
      grps[[i]][[".group"]] <- NULL
      insight::print_color(sprintf("# %s\n\n", i), "blue")
      cat(insight::format_table(grps[[i]]))
      cat("\n")
    }
  } else {
    cat(insight::format_table(x))
  }

  invisible(orig_x)
}





# bootstrapping CIs ----------------------------------

.boot_distribution <- function(data, indices, centrality) {
  out <- parameters::describe_distribution(
    data[indices],
    centrality = centrality,
    dispersion = FALSE,
    iqr = FALSE,
    range = FALSE,
    ci = NULL
  )
  out[[1]]
}

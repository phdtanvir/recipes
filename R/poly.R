#' Orthogonal Polynomial Basis Functions
#'
#' \code{step_poly} creates a \emph{specification} of a recipe step that will create new columns that are basis expansions of variables using orthogonal polynomials.
#'
#' @inheritParams step_center
#' @param role For model terms created by this step, what analysis role should they be assigned?. By default, the function assumes that the new columns created from the original variables will be used as predictors in a model.
#' @param objects A list of \code{\link[stats]{poly}} objects created once the step has been learned.
#' @param options A list of options for  \code{\link[stats]{poly}} which should not include \code{x} or \code{simple}. Note that the option \code{raw = TRUE} will produce the regular polynomial values (not orthogonalized).
#' @return \code{step_poly} returns an object of class \code{step_poly}.
#' @keywords datagen
#' @concept preprocessing basis_expansion
#' @export
#' @details \code{step_poly} can new features from a single variable that enable fitting routines to model this variable in a nonlinear manner. The extent of the possible nonlinearity is determined by the \code{degree} argument of  \code{\link[stats]{poly}}. The original variables are removed from the data and new columns are added. The naming convention for the new variables is \code{varname_poly_1} and so on.
#' @examples
#' data(biomass)
#'
#' biomass_tr <- biomass[biomass$dataset == "Training",]
#' biomass_te <- biomass[biomass$dataset == "Testing",]
#'
#' rec <- recipe(HHV ~ carbon + hydrogen + oxygen + nitrogen + sulfur,
#'               data = biomass_tr)
#'
#' quadratic <- rec %>%
#'   step_poly(carbon, hydrogen)
#' quadratic <- learn(quadratic, training = biomass_tr)
#'
#' expanded <- process(quadratic, biomass_te)
#' expanded
#' @seealso \code{\link{step_ns}} \code{\link{recipe}} \code{\link{learn.recipe}} \code{\link{process.recipe}}


step_poly <- function(recipe, ..., role = "predictor", trained = FALSE,
                      objects = NULL, options = list(degree = 2)) {
  terms <- quos(...)
  if(is_empty(terms))
    stop("Please supply at least one variable specification. See ?selections.")
  add_step(
    recipe,
    step_poly_new(
      terms = terms,
      trained = trained,
      role = role,
      objects = objects,
      options = options)
  )
}

step_poly_new <- function(terms = NULL, role = NA, trained = FALSE,
                          objects = NULL, options = NULL) {
  step(
    subclass = "poly",
    terms = terms,
    role = role,
    trained = trained,
    objects = objects,
    options = options
  )
}


poly_wrapper <- function(x, args) {
  args$x <- x
  args$simple <- FALSE
  poly_obj <- do.call("poly", args)

  ## don't need to save the original data so keep 1 row
  out <- matrix(NA, ncol = ncol(poly_obj), nrow = 1)
  class(out) <- c("poly", "basis", "matrix")
  attr(out, "degree") <- attr(poly_obj, "degree")
  attr(out, "coefs") <- attr(poly_obj, "coefs")
  out
}

#' @importFrom stats poly
#' @export
learn.step_poly <- function(x, training, info = NULL, ...) {
  col_names <- select_terms(x$terms, info = info)

  obj <- lapply(training[, col_names], poly_wrapper, x$options)
  for(i in seq(along = col_names))
    attr(obj[[i]], "var") <- col_names[i]

  step_poly_new(terms = x$terms, role = x$role,
                trained = TRUE, objects = obj,
                options = x$options)
}

#' @importFrom tibble as_tibble is_tibble
#' @importFrom stats predict
#' @export
process.step_poly <- function(object, newdata, ...) {
  ## pre-allocate a matrix for the basis functions.
  new_cols <- vapply(object$objects, ncol, c(int = 1L))
  poly_values <- matrix(NA, nrow = nrow(newdata), ncol = sum(new_cols))
  colnames(poly_values) <- rep("", sum(new_cols))
  strt <- 1
  for(i in names(object$objects)) {
    cols <- (strt):(strt+new_cols[i]-1)
    orig_var <- attr(object$objects[[i]], "var")
    poly_values[, cols] <- predict(object$objects[[i]], getElement(newdata, i))
    new_names <- paste(orig_var, "poly", names0(new_cols[i], ""), sep = "_")
    colnames(poly_values)[cols] <- new_names
    strt <- max(cols)+1
    newdata[, orig_var] <- NULL
  }
  newdata <- cbind(newdata, as_tibble(poly_values))
  if(!is_tibble(newdata)) newdata <- as_tibble(newdata)
  newdata
}


print.step_poly <- function(x, width = max(20, options()$width - 35), ...) {
  cat("Orthogonal polynomials on ")
  if(x$trained) {
    cat(format_ch_vec(names(x$objects), width = width))
  } else cat(format_selectors(x$terms, wdth = width))
  if(x$trained) cat(" [trained]\n") else cat("\n")
  invisible(x)
}

#' Create a Recipe for Preprocessing Data
#'
#' A recipe is a description of what steps should be applied to a data set in order to get it ready for data analysis.
#'
#' @aliases recipe recipe.default recipe.formula
#' @param x an object. For the default method, \code{x} is a data frame or tibble of the \emph{template} data set (see below).
#' @author Max Kuhn
#' @keywords datagen
#' @concept preprocessing model_specification
#' @export
recipe <- function(x, ...) UseMethod("recipe")

#' @rdname recipe
#' @param data a data frame or tibble of the \emph{template} data set (see below).
#' @param vars a character string of column names corresponding to variables that will be used in any context (see below)
#' @param roles a character string (the same length of \code{vars}) that describes a single role that the variable will take. This value could be anything but common roles are \code{"outcome"}, \code{"predictor"}, \code{"case_weight"}, or \code{"ID"}
#' @param ... further arguments passed to or from other methods (not currently used).
#' @return An object of class \code{recipe} with sub-objects: \item{var_info}{A tibble containing information about the original data set columns}\item{term_info}{A tibble that contains the current set of terms in the data set. This initially defaults to the same data contained in \code{var_info}.}\item{steps}{A list of \code{step} objects that define the sequence of preprocessing steps that will be applied to data. The default value is \code{NULL}}\item{template}{A tibble of the data. This is initialized to be the same as the data given in the \code{data} argument but can be different after the recipe is trained.}
#'
#' @export
#' @importFrom tibble as_tibble is_tibble tibble
#' @importFrom dplyr full_join
#' @importFrom stats predict
recipe.default <- function(x, vars = colnames(x), roles = NULL, ...) {
  
  if(!is_tibble(x)) x <- as_tibble(x)
  if(is.null(vars)) vars <- colnames(x)
  if(any(table(vars) > 1))
    stop("`vars` should have unique members")
  if(any(!(vars %in% colnames(x))))
    stop("1+ elements of `vars` are not in `x`")
  
  x <- x[, vars]
  
  var_info <- tibble(variable = vars)
  
  ## Check and add roles when available
  if(!is.null(roles)) {
    if(length(roles) != length(vars))
      stop("The number of roles should be the same as the number of variables")
    var_info$role <- roles
  } else var_info$role <- ""
  
  ## Add types
  var_info <- full_join(get_types(x), var_info, by = "variable")
  var_info$source <- "original"
  
  ## Return final object of class `recipe`
  out <- list(var_info = var_info,
              term_info = var_info,
              steps = NULL,
              template = x)
  class(out) <- "recipe"
  out
}

#' @rdname recipe
#' @param formula A model formula. No in-line functions should be used here (e.g. \code{log(x)}, \code{x:y}, etc.). These types of transformations should be enacted using \code{step} functions in this package. Dots are allowed. 
#' @export
#' @importFrom stats as.formula
#' @importFrom tibble as_tibble is_tibble 

recipe.formula <- function(formula, data, ...) {
  if(!is_formula(formula))
    formula <- as.formula(formula)
  ## check for in-line formulas
  check_elements(formula, allowed = NULL)
  
  if(!is_tibble(data)) data <- as_tibble(data)
  
  ## use lazyeval to get both sides of the formula
  outcomes <- get_lhs_vars(formula, data)
  predictors <- get_rhs_vars(formula, data)
  
  ## get `vars` from lhs and rhs of formula
  
  vars <- c(predictors, outcomes)
  
  ## subset data columns
  data <- data[, vars]
  
  ## derive roles
  roles <- rep("predictor", length(predictors))
  if(length(outcomes) > 0)
    roles <- c(roles, rep("outcome", length(outcomes)))
  
  ## pass to recipe.default with vars and roles
  
  recipe.default(x = data, vars = vars, roles = roles, ...)
}


#' @aliases learn learn.recipe
#' @param x an object
#' @param ... further arguments passed to or from other methods (not currently used).
#' @author Max Kuhn
#' @keywords datagen
#' @concept preprocessing model_specification
#' @export
learn   <- function(x, ...) UseMethod("learn")

#' Train a Data Recipe
#'
#' For a recipe with at least one preprocessing step, estimate the required parameters from a training set that can be later applied to other data sets.
#' @param training A data frame or tibble that will be used to estimate parameters for preprocessing.
#' @param fresh A logical indicating whether already trained steps should be re-trained. If \code{TRUE}, you should pass in a data set to the argument \code{training}. 
#' @param verbose A logical that controls wether progress is reported as steps are executed.
#' @param retain A logical: should the processed training set be saved into the \code{template} slot of the recipe after training? This is a good idea if you want to add more steps later but want to avoid re-training the existing steps. 
#' @return A recipe whose step objects have been updated with the required quantities (e.g. parameter estimates, model objects, etc). Also, the \code{term_info} object is likely to be modified as the steps are executed.
#' @rdname learn
#' @importFrom tibble as_tibble is_tibble tibble
#' @importFrom dplyr left_join
#' @export
learn.recipe <- function(x, training = NULL, fresh = FALSE, verbose = TRUE, retain = FALSE, ...) {
  if(length(x$steps) == 0)
    stop("Add some steps")
  if(is.null(training)) {
    if(fresh)
      stop("A training set must be supplied to the `training` argument when `fresh = TRUE`")
    training <- x$template
  } else {
    training <- if(!is_tibble(training))
      as_tibble(training[, x$var_info$variable, drop = FALSE]) else
        training[, x$var_info$variable]
  }
  
  for(i in seq(along = x$steps)) {
    note <- paste("step", i, gsub("^step_", "", class(x$steps[[i]])[1]))
    if(!x$steps[[i]]$trained | fresh) {
      if(verbose) 
        cat(note, "training", "\n")
      
      # Compute anything needed for the pre-processing steps
      # then apply it to the current training set
      
      x$steps[[i]] <- learn(x$steps[[i]], training = training, info = x$term_info)
      training <- process(x$steps[[i]], newdata = training)
      x$term_info <- left_join(get_types(training), x$term_info, by = c("variable", "type"))
      
      ## Update the roles and the term source
      ## These next two steps needs to be smarter to find diffs
      if(!is.na(x$steps[[i]]$role))
        x$term_info$role[is.na(x$term_info$role)] <- x$steps[[i]]$role
      x$term_info$source[is.na(x$term_info$source)] <- "derived"
    } else {
      if(verbose) 
        cat(note, "[pre-trained]\n")
    }
  }
  if(retain) x$template <- training
  
  x
}

#' @rdname process
#' @aliases process process.recipe
#' @author Max Kuhn
#' @keywords datagen
#' @concept preprocessing model_specification
#' @export
process <- function(object, ...) UseMethod("process")

#' Apply a Trained Data Recipe
#'
#' For a recipe with at least one preprocessing step that has been trained by \code{\link{learn.recipe}}, apply the computations to new data.
#' @param object A trained object such as a \code{\link{recipe}} with at least one preprocessing step.
#' @param ... further arguments passed to or from other methods (not currently used).
#' @param newdata A data frame or tibble for whom the preprocessing will be applied.
#' @param roles A character vector to choose which types of columns to return (e.g. "predictor"). By default all columns are returned.
#' @return A tibble that may have different columns than the original columns in \code{newdata}.
#' @rdname process
#' @importFrom tibble as_tibble 
#' @importFrom dplyr filter
#' @export

process.recipe <- function(object, newdata = object$template, roles = "all", ...) {
  newdata <- if(!is_tibble(newdata))
    as_tibble(newdata[, object$var_info$variable, drop = FALSE]) else
      newdata[, object$var_info$variable]
  
  for(i in seq(along = object$steps)) {
    newdata <- process(object$steps[[i]], newdata = newdata)
  }
  if(all(roles != "all")) {
    dat_info <- filter(object$term_info, role %in% roles)
    if(nrow(dat_info) == 0) {
      msg <- paste("No matching `roles` were found; returning everything instead", 
                   "Existing roles are:", 
                   paste0(sort(unique(object$term_info$role)), collapse = ", "))
      warning(msg)
    }
    keepers <- dat_info$variable
    newdata <- newdata[, names(newdata) %in% keepers]
  }
  newdata
}

#' Print a Recipe
#' 
#' @aliases print.recipe
#' @param x A \code{recipe} object
#' @param form_width The number of characters used to print the variables or terms in a formula
#' @param ... further arguments passed to or from other methods (not currently used).
#' @return The original object (invisibly)
#'
#' @author Max Kuhn
#' @export 
print.recipe <- function(x, form_width = 30, ...) {
  tab <- as.data.frame(table(x$var_info$role))
  colnames(tab) <- c("role", "#variables")
  cat("Data Recipe\n\n")
  cat("Inputs:\n\n")
  print(tab, row.names = FALSE)
  
  
  if(!is.null(x$steps)) {
    cat("\nSteps:\n\n")
    for(i in seq_along(x$steps))
      print(x$steps[[i]], form_width = form_width)
  }
  invisible(x)
}
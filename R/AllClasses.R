setOldClass("ModelFrame")
setOldClass("recipe")


#' Resampling Controls
#' 
#' @description
#' The base \code{MLControl} constructor initializes a set of control parameters
#' that are common to all resampling methods.
#' 
#' @rdname MLControl
#' 
#' @param surv_times numeric vector of follow-up times at which to predict
#' survival events.
#' @param seed integer to set the seed at the start of resampling.  This is set
#' to a random integer by default (NULL).
#' @param ...  arguments to be passed to \code{MLControl}.
#' 
#' @return \code{MLControl} class object.
#' 
#' @seealso \code{\link{resample}}
#' 
MLControl <- function(surv_times = numeric(), seed = NULL, ...) {
  MLControl_depwarn(...)
  if (is.null(seed)) seed <- sample.int(.Machine$integer.max, 1)
  new("MLControl", surv_times = surv_times, seed = seed)
}


MLControl_depwarn <- function(summary = NULL, cutoff = NULL,
                              cutoff_index = NULL, na.rm = NULL, ...) {
  if (!is.null(summary)) {
    depwarn("'summary' argument to MLControl is deprecated",
            "apply the modelmetrics function to Resamples output directly")
  }
  
  if (!is.null(cutoff)) {
    depwarn("'cutoff' argument to MLContorl is deprecated",
            "specify in calls to modelmetrics instead")
  }
  
  if (!is.null(cutoff_index)) {
    depwarn("'cutoff_index' argument to MLControl is deprecated",
            "specify in calls to modelmetrics instead")
  }
  
  if (!is.null(na.rm)) {
    depwarn("'na.rm' argument to MLControl is deprecated",
            "specify in calls to modelmetrics instead")
  }
}


setClass("MLControl",
  slots = c(surv_times = "numeric", seed = "numeric")
)


#' @description
#' \code{BootControl} constructs an \code{MLControl} object for simple bootstrap
#' resampling in which models are fit with bootstrap resampled training sets and
#' used to predict the full data set.
#' 
#' @rdname MLControl
#' 
#' @param samples number of bootstrap samples.
#' 
#' @examples
#' ## 100 bootstrap samples
#' BootControl(samples = 100)
#' 
BootControl <- function(samples = 25, ...) {
  new("BootMLControl", MLControl(...), samples = samples)
}


setClass("BootMLControl",
  slots = c(samples = "numeric"),
  contains = "MLControl"
)


#' @description
#' \code{CVControl} constructs an \code{MLControl} object for repeated K-fold
#' cross-validation.  In this procedure, the full data set is repeatedly
#' partitioned into K-folds.  Within a partitioning, prediction is performed on
#' each of the K folds with models fit on all remaining folds.
#' 
#' @rdname MLControl
#' 
#' @param folds number of cross-validation folds (K).
#' @param repeats number of repeats of the K-fold partitioning.
#' 
#' @examples
#' ## 5 repeats of 10-fold cross-validation
#' CVControl(folds = 10, repeats = 5)
#' 
CVControl <- function(folds = 10, repeats = 1, ...) {
  new("CVMLControl", MLControl(...), folds = folds, repeats = repeats)
}


setClass("CVMLControl",
  slots = c(folds = "numeric", repeats = "numeric"),
  contains = "MLControl"
)


#' @description
#' \code{OOBControl} constructs an \code{MLControl} object for out-of-bootstrap
#' resampling in which models are fit with bootstrap resampled training sets and
#' used to predict the unsampled cases.
#' 
#' @rdname MLControl
#' 
#' @examples
#' ## 100 out-of-bootstrap samples
#' OOBControl(samples = 100)
#' 
OOBControl <- function(samples = 25, ...) {
  new("OOBMLControl", MLControl(...), samples = samples)
}


setClass("OOBMLControl",
  slots = c(samples = "numeric"),
  contains = "MLControl"
)


#' @description
#' \code{SplitControl} constructs an \code{MLControl} object for splitting data
#' into a seperate trianing and test set.
#' 
#' @rdname MLControl
#' 
#' @param prop proportion of cases to include in the training set
#' (\code{0 < prop < 1}).
#' 
#' @examples
#' ## Split sample of 2/3 training and 1/3 testing
#' SplitControl(prop = 2/3)
#' 
SplitControl <- function(prop = 2/3, ...) {
  new("SplitMLControl", MLControl(...), prop = prop)
}


setClass("SplitMLControl",
  slots = c(prop = "numeric"),
  contains = "MLControl"
)


#' @description
#' \code{TrainControl} constructs an \code{MLControl} object for training and
#' performance evaluation to be performed on the same training set.
#' 
#' @rdname MLControl
#' 
#' @examples
#' ## Same training and test set
#' TrainControl()
#' 
TrainControl <- function(...) {
  new("TrainMLControl", MLControl(...))
}


setClass("TrainMLControl",
  contains = "MLControl"
)


MLFitBits <- setClass("MLFitBits",
  slots = c(packages = "character",
            predict = "function",
            varimp = "function",
            x = "ANY",
            y = "ANY")
)


#' MLModel Class Constructor
#' 
#' @param name character string name for the instantiated \code{MLModel} object.
#' @param packages character vector of packages required by the object.
#' @param types character vector of response variable types on which the model
#' can be fit.
#' @param params list of user-specified model parameters.
#' @param nvars function to return the number of predictor variables for a
#' given model frame.
#' @param fit model fitting function.
#' @param predict model prediction function.
#' @param varimp variable importance function.
#' 
MLModel <- function(name = "MLModel", packages = character(0),
                    types = character(0), params = list(),
                    nvars = function(data) NULL,
                    fit = function(formula, data, weights, ...)
                      stop("no fit function"),
                    predict = function(object, newdata, times, ...)
                      stop("no predict function"),
                    varimp = function(object, ...) NULL) {
  
  stopifnot(types %in% c("binary", "factor", "matrix", "numeric", "ordered",
                         "Surv"))
  
  new("MLModel",
      name = name,
      packages = packages,
      types = types,
      params = params,
      nvars = nvars,
      fit = fit,
      fitbits = MLFitBits(packages = packages,
                          predict = predict,
                          varimp = varimp))
}


setClass("MLModel",
  slots = c(name = "character",
            packages = "character",
            types = "character",
            params = "list",
            nvars = "function",
            fit = "function",
            fitbits = "MLFitBits")
)


setClass("MLModelFit",
  slots = c(fitbits = "MLFitBits"),
  contains = "VIRTUAL"
)


setClass("SVMModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMANOVAModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMBesselModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMLaplaceModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMLinearModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMPolyModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMRadialModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMSplineModelFit", contain = c("MLModelFit", "ksvm"))
setClass("SVMTanhModelFit", contain = c("MLModelFit", "ksvm"))
setClass("CForestModelFit", contains = c("MLModelFit", "RandomForest"))


#' @name resample
#' @rdname resample-methods
#' 
#' @param ... named or unnamed \code{resample} output to combine together with
#' the \code{Resamples} constructor.
#' 
#' @details Output being combined from more than one model with the
#' \code{Resamples} constructor must have been generated with the same
#' resampling \code{control} object.
#' 
Resamples <- function(...) {
  .Resamples(...)
}


.Resamples <- function(..., .control = NULL, .strata = character()) {
  args <- list(...)
  
  if (length(args) == 0) stop("no resample output given")
  
  .Data <- args[[1]]
  if (length(args) > 1) {
    if (!all(sapply(args, function(x) is(x, "Resamples")))) {
      stop("values to combine must be Resamples objects")
    }
    
    .control <- .Data@control
    is_equal_control <- function(x) isTRUE(all.equal(x@control, .control))
    if (!all(sapply(args, is_equal_control))) {
      stop("resamples have different control structures")
    }
    
    .strata <- .Data@strata
    if (!all(sapply(args, function(x) x@strata == .strata))) {
      stop("resamples have different strata variables")
    }
    
    .Data <- do.call(append, make_unique_levels(args, which = "Model"))
  }
  
  var_names <- c("Model", "Resample", "Case", "Observed", "Predicted")
  is_missing <- !(var_names %in% names(.Data))
  if (any(is_missing)) {
    stop("missing resample variables: ", toString(var_names[is_missing]))
  }
  
  new("Resamples", .Data, control = .control, strata = as.character(.strata))
}


setClass("Resamples",
  slots = c(control = "MLControl", strata = "character"),
  contains = "data.frame"
)


MLModelTune <- setClass("MLModelTune",
  slots = c(grid = "data.frame", resamples = "Resamples", selected = "numeric"),
  contains = "MLModel"
)


#' @name calibration
#' @rdname calibration
#' 
#' @param ... named or unnamed \code{calibration} output to combine together
#' with the \code{Calibration} constructor.
#' 
Calibration <- function(...) {
  args <- list(...)
  
  if (!all(sapply(args, is.data.frame))) {
    stop("values to combine must inherit from data.frame")
  }
  
  var_names <- c("Response", "Midpoint", "Observed")
  for (x in args) {
    is_missing <- !(var_names %in% names(x))
    if (any(is_missing)) {
      stop("missing calibration variables: ", toString(var_names[is_missing]))
    }
  }

  args <- make_unique_levels(args, which = "Model")
  new("Calibration", do.call(append, args))
}


setClass("Calibration",
  contains = "data.frame"
)


#' @name confusion
#' @rdname confusion
#' 
#' @param ... named or unnamed \code{confusion} output to combine together with
#' the \code{Confusion} constructor.
#' 
Confusion <- function(...) {
  args <- list(...)
  
  conf_list <- list()
  for (i in seq(args)) {
    x <- args[[i]]
    if (is(x, "ConfusionMatrix")) {
      x <- list("Model" = x)
    } else if (!is(x, "Confusion")) {
      stop("values to combine must be Confusion or ConfusionMatrix objects")
    }
    arg_name <- names(args)[i]
    if (!is.null(arg_name) && nzchar(arg_name)) {
      names(x) <- rep(arg_name, length(x))
    }
    conf_list <- c(conf_list, x)
  }
  names(conf_list) <- make.unique(names(conf_list))

  structure(conf_list, class = c("Confusion", "listof"))
}


ConfusionMatrix <- function(object) {
   structure(object, class = c("ConfusionMatrix", "table"))
}


HTestResamples <- setClass("HTestResamples",
  slots = c("adjust" = "character"),
  contains = "array"
)


#' @name lift
#' @rdname lift
#' 
#' @param ... named or unnamed \code{lift} output to combine together with the
#' \code{Lift} constructor.
#' 
Lift <- function(...) {
  args <- list(...)
  
  if (!all(sapply(args, is.data.frame))) {
    stop("values to combine must inherit from data.frame")
  }
  
  var_names <- c("Found", "Tested")
  for (x in args) {
    is_missing <- !(var_names %in% names(x))
    if (any(is_missing)) {
      stop("missing lift variables: ", toString(var_names[is_missing]))
    }
  }

  args <- make_unique_levels(args, which = "Model")
  new("Lift", do.call(append, args))
}


setClass("Lift",
  contains = "data.frame"
)


ModelMetrics <- setClass("ModelMetrics",
  contains = "array"
)


ModelMetricsDiff <- setClass("ModelMetricsDiff",
  slots = c("model_names" = "character"),
  contains = "ModelMetrics"
)


PartialDependence <- function(object) {
  structure(object, class = c("PartialDependence", "data.frame"))
}


SummaryConfusion <- setClass("SummaryConfusion",
  slots = c("N" = "numeric", "Accuracy" = "numeric", "Majority" = "numeric",
            "Kappa" = "numeric"),
  contains = "matrix"
)


VarImp <- setClass("VarImp", contains = "data.frame")


setMethod("initialize", "VarImp",
  function(.Object, .Data, scale = FALSE, ...) {
    idx <- order(rowSums(.Data), decreasing = TRUE)
    idx <- idx * (rownames(.Data)[idx] != "(Intercept)")
    .Data <- .Data[idx, , drop = FALSE]
    if (scale) .Data <- 100 * (.Data - min(.Data)) / diff(range(.Data))
    callNextMethod(.Object, .Data, ...)
  }
)


setValidity("VarImp", function(object) {
  !(nrow(object) && is.null(rownames(object)))
})

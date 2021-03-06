#' Bagging with Classification Trees
#' 
#' Fits the Bagging algorithm proposed by Breiman in 1996 using classification
#' trees as single classifiers.
#'  
#' @param mfinal number of trees to use.
#' @param minsplit minimum number of observations that must exist in a node in
#' order for a split to be attempted.
#' @param minbucket minimum number of observations in any terminal node.
#' @param cp complexity parameter.
#' @param maxcompete number of competitor splits retained in the output.
#' @param maxsurrogate number of surrogate splits retained in the output.
#' @param usesurrogate how to use surrogates in the splitting process.
#' @param xval number of cross-validations.
#' @param surrogatestyle controls the selection of a best surrogate.
#' @param maxdepth maximum depth of any node of the final tree, with the root
#' node counted as depth 0.
#' 
#' @details
#' \describe{
#' \item{Response Types:}{\code{factor}}
#' }
#' 
#' Further model details can be found in the source link below.
#' 
#' @return \code{MLModel} class object.
#' 
#' @seealso \code{\link[adabag]{bagging}}, \code{\link{fit}},
#' \code{\link{resample}}, \code{\link{tune}}
#' 
#' @examples
#' fit(Species ~ ., data = iris, model = AdaBagModel(mfinal = 5))
#'
AdaBagModel <- function(mfinal = 100, minsplit = 20,
                        minbucket = round(minsplit/3), cp = 0.01, 
                        maxcompete = 4, maxsurrogate = 5, usesurrogate = 2,
                        xval = 10, surrogatestyle = 0, maxdepth = 30) {
  
  args <- params(environment())
  is_main <- names(args) %in% "mfinal"
  params <- args[is_main]
  params$control <- as.call(c(.(list), args[!is_main]))
  
  MLModel(
    name = "AdaBagModel",
    packages = "adabag",
    types = "factor",
    params = params,
    nvars = function(data) nvars(data, design = "terms"),
    fit = function(formula, data, weights, ...) {
      assert_equal_weights(weights)
      data <- model.frame(formula, data)
      formula[[2]] <- formula(data)[[2]]
      adabag::bagging(formula, data = data, ...)
    },
    predict = function(object, newdata, ...) {
      predict(object, newdata = newdata)$prob
    },
    varimp = function(object, ...) {
      object$importance
    }
  )
  
}

#' Run PHATE on an input data matrix
#'
#' PHATE is a data reduction method specifically designed for visualizing
#' **high** dimensional data in **low** dimensional spaces.
#'
#' @param data matrix (n_samples, n_dimensions)
#' 2 dimensional input data array with
#' n_samples samples and n_dimensions dimensions.
#' If `knn.dist.method` is 'precomputed', `data` is treated as a
#' (n_samples, n_samples) distance or affinity matrix
#' @param ndim int, optional, default: 2
#' number of dimensions in which the data will be embedded
#' @param k int, optional, default: 5
#' number of nearest neighbors on which to build kernel
#' @param alpha int, optional, default: 40
#' sets decay rate of kernel tails.
#' If NULL, alpha decaying kernel is not used
#' @param n.landmark int, optional, default: 2000
#' number of landmarks to use in fast PHATE
#' @param gamma float, optional, default: 1
#' Informational distance constant between -1 and 1.
#' `gamma=1` gives the PHATE log potential, `gamma=0` gives
#' a square root potential.
#' @param t int, optional, default: 'auto'
#' power to which the diffusion operator is powered
#' sets the level of diffusion
#' @param knn.dist.method string, optional, default: 'euclidean'.
#' recommended values: 'euclidean', 'cosine', 'precomputed'
#' Any metric from `scipy.spatial.distance` can be used
#' distance metric for building kNN graph. If 'precomputed',
#' `data` should be an n_samples x n_samples distance or
#' affinity matrix. Distance matrices are assumed to have zeros
#' down the diagonal, while affinity matrices are assumed to have
#' non-zero values down the diagonal. This is detected automatically using
#' `data[0,0]`. You can override this detection with
#' `knn.dist.method='precomputed_distance'` or
#' `knn.dist.method='precomputed_affinity'`.
#' @param init phate object, optional
#' object to use for initialization. Avoids recomputing
#' intermediate steps if parameters are the same.
#' @param mds.method string, optional, default: 'metric'
#' choose from 'classic', 'metric', and 'nonmetric'
#' which MDS algorithm is used for dimensionality reduction
#' @param mds.dist.method string, optional, default: 'euclidean'
#' recommended values: 'euclidean' and 'cosine'
#' @param t.max int, optional, default: 100.
#' Maximum value of t to test for automatic t selection.
#' @param npca int, optional, default: 100
#' Number of principal components to use for calculating
#' neighborhoods. For extremely large datasets, using
#' n_pca < 20 allows neighborhoods to be calculated in
#' log(n_samples) time.
#' @param plot.optimal.t boolean, optional, default: FALSE
#' If TRUE, produce a plot showing the Von Neumann Entropy
#' curve for automatic t selection.
#' @param verbose `int` or `boolean`, optional (default : 1)
#' If `TRUE` or `> 0`, print verbose updates.
#' @param n.jobs `int`, optional (default: 1)
#' The number of jobs to use for the computation.
#' If -1 all CPUs are used. If 1 is given, no parallel computing code is
#' used at all, which is useful for debugging.
#' For n_jobs below -1, (n.cpus + 1 + n.jobs) are used. Thus for
#' n_jobs = -2, all CPUs but one are used
#' @param seed int or `NULL`, random state (default: `NULL`)
#' @param potential.method Deprecated.
#' For log potential, use `gamma=1`. For sqrt potential, use `gamma=0`.
#' @param use.alpha Deprecated
#' To disable alpha decay, use `alpha=NULL`
#' @param n.svd Deprecated.
#' @param pca.method Deprecated.
#' @param g.kernel Deprecated.
#' @param diff.op Deprecated.
#' @param diff.op.t Deprecated.
#' @param landmark.transitions Deprecated.
#' @param dist.method Deprecated.
#'
#' @return "phate" object containing:
#'  * **embedding**: the PHATE embedding
#'  * **operator**: The PHATE operator (python phate.PHATE object)
#'  * **params**: Parameters passed to phate
#'
#' @examples
#' if (reticulate::py_module_available("phate")) {
#'
#' # Load data
#' # data(tree.data)
#' # We use a smaller tree to make examples run faster
#' data(tree.data.small)
#'
#' # Run PHATE
#' phate.tree <- phate(tree.data.small$data)
#' summary(phate.tree)
#' ## PHATE embedding
#' ## k = 5, alpha = 40, t = 58
#' ## Data: (3000, 100)
#' ## Embedding: (3000, 2)
#'
#' library(graphics)
#' # Plot the result with base graphics
#' plot(phate.tree, col=tree.data.small$branches)
#' # Plot the result with ggplot2
#' if (require(ggplot2)) {
#'   ggplot(phate.tree) +
#'     geom_point(aes(x=PHATE1, y=PHATE2, color=tree.data.small$branches))
#' }
#'
#' # Run PHATE again with different parameters
#' # We use the last run as initialization
#' phate.tree2 <- phate(tree.data.small$data, t=150, init=phate.tree)
#' # Extract the embedding matrix to use in downstream analysis
#' embedding <- as.matrix(phate.tree2)
#'
#' }
#' @export
phate <- function(data, ndim = 2, k = 5,
                  alpha = 40,
                  n.landmark=2000, gamma=1,
                  t = "auto", knn.dist.method = "euclidean",
                  init=NULL,
                  mds.method = "metric", mds.dist.method = "euclidean",
                  t.max=100, npca = 100, plot.optimal.t=FALSE,
                  verbose=1, n.jobs=1, seed=NULL,
                  potential.method = NULL,
                  # deprecated args, remove in v3
                  use.alpha=NULL,
                  n.svd = NULL,
                  pca.method = NULL,
                  g.kernel=NULL, diff.op = NULL, landmark.transitions=NULL,
                  diff.op.t = NULL, dist.method=NULL) {
  # check installation
  if (!reticulate::py_module_available(module = "phate")) {
    load_pyphate()
  }
  tryCatch(pyphate, error = function(e) load_pyphate())
  # check for deprecated arguments
  if (!is.null(dist.method)) {
    message("Argument dist.method is deprecated. Using knn.dist.method instead.")
    knn.dist.method <- dist.method
  }
  if (!is.null(potential.method)) {
    if (potential.method == 'log') {
      gamma <- 1
    } else if (potential.method == 'sqrt') {
      gamma <- 0
    } else {
      stop(paste0("potential.method ", potential.method, " not recognized. ",
                  "Please use -1 <= gamma <= 1 instead."))
    }
    message(paste0("Argument potential_method is deprecated. Setting gamma to ",
                   gamma, " to achieve ", potential.method, " transformation."))
  }
  if (!is.null(n.svd)) {
    message("Setting n.svd is currently not supported. Using n.svd=100")
  }
  if (!is.null(pca.method)) {
    message("Setting pca.method is deprecated. Using pca.method='random'")
  }
  if (!is.null(g.kernel)) {
    message(paste0("Setting g.kernel is deprecated. Using instead ",
                   "`knn.dist.method='precomputed'` and `data=g.kernel`"))
    data <- g.kernel
    knn.dist.method <- "precomputed"
  }
  if (!is.null(diff.op)) {
    stop(paste0("Setting diff.op is deprecated. Use `init` with a `phate` ",
                "object instead"))
  }
  if (!is.null(diff.op.t)) {
    stop(paste0("Setting diff.op.t is deprecated. Use `init` with a `phate` ",
                "object instead"))
  }
  if (!is.null(landmark.transitions)) {
    stop(paste0("Setting landmark.transitions is deprecated. Use `init` with a",
                " `phate` object instead"))
  }
  if (!is.null(use.alpha)) {
    stop(paste0("Setting use.alpha is deprecated. Use `alpha=NULL` instead"))
  }
  if (mds.method == "mmds") {
    message(paste0("Argument mds.method = 'mmds' is deprecated. ",
                   "Use mds.method = 'metric' instead."))
    mds.method <- "metric"
  } else if (mds.method == "cmds") {
    message(paste0("Argument mds.method = 'cmds' is deprecated. ",
                   "Use mds.method = 'classic' instead."))
    mds.method <- "classic"
  } else if (mds.method == "nmmds") {
    message(paste0("Argument mds.method = 'nmmds' is deprecated. ",
                   "Use mds.method = 'nonmetric' instead."))
    mds.method <- "nonmetric"
  } else if (!(mds.method %in% c("classic", "metric", "nonmetric"))) {
    message(paste0("mds.method ", mds.method, " not recognized. ",
                   "Choose from c('classic', 'metric, 'nonmetric'). ",
                   "Using 'metric'..."))
    mds.method <- "metric"
  }
  ndim <- as.integer(ndim)
  k <- as.integer(k)
  t.max <- as.integer(t.max)
  n.jobs <- as.integer(n.jobs)

  if (is.numeric(n.landmark)) {
    n.landmark <- as.integer(n.landmark)
  } else if (!is.null(n.landmark) && is.na(n.landmark)) {
    n.landmark <- NULL
  }
  if (is.numeric(npca)) {
    npca <- as.integer(npca)
  } else if (!is.null(npca) && is.na(npca)) {
    npca <- NULL
  }
  if (is.numeric(alpha)) {
    alpha <- as.double(alpha)
  } else if (!is.null(alpha) && is.na(alpha)) {
    alpha <- NULL
  }
  if (is.numeric(t)) {
    t <- as.integer(t)
  } else if (is.null(t) || is.na(t)) {
    t <- 'auto'
  }
  if (is.numeric(seed)) {
    seed <- as.integer(seed)
  } else if (!is.null(seed) && is.na(seed)) {
    seed <- NULL
  }
  if (is.numeric(verbose)) {
    verbose <- as.integer(verbose)
  }
  if (!methods::is(data, "Matrix")) {
    data <- as.matrix(data)
  }

  # store parameters
  params <- list("data" = data, "k" = k, "alpha" = alpha, "t" = t,
                 "n.landmark" = n.landmark, "gamma" = gamma,
                 "ndim" = ndim,
                 "npca" = npca, "mds.method" = mds.method,
                 "knn.dist.method" = knn.dist.method,
                 "mds.dist.method" = mds.dist.method)
  # use pre-initialized values if given
  operator <- NULL
  if (!is.null(init)) {
    if (!methods::is(init, "phate")) {
      warning("object passed to init is not a phate object")
    } else {
      operator <- init$operator
      operator$set_params(n_components = ndim,
                          k = k,
                          a = alpha,
                          t = t,
                          n_landmark = n.landmark,
                          gamma = gamma,
                          n_pca = npca,
                          mds = mds.method,
                          mds_dist = mds.dist.method,
                          knn_dist = knn.dist.method,
                          n_jobs = n.jobs,
                          random_state = seed,
                          verbose = verbose)
    }
  }
  if (is.null(operator)) {
    operator <- pyphate$PHATE(n_components = ndim,
                              k = k,
                              a = alpha,
                              t = t,
                              n_landmark = n.landmark,
                              gamma = gamma,
                              n_pca = npca,
                              mds = mds.method,
                              mds_dist = mds.dist.method,
                              knn_dist = knn.dist.method,
                              n_jobs = n.jobs,
                              random_state = seed,
                              verbose = verbose)
  }
  embedding <- operator$fit_transform(data,
                                      t_max = t.max)
  colnames(embedding) <- paste0("PHATE", 1:ncol(embedding))
  rownames(embedding) <- rownames(data)
  if (plot.optimal.t) {
    out <- operator$von_neumann_entropy(t_max = t.max)
    t <- out[[1]]
    h <- out[[2]]
    t.opt <- pyphate$vne$find_knee_point(h, t)
    graphics::plot(t, h,
                   type = "l",
                   xlab = "t", ylab = "Von Neumann Entropy",
                   main = paste0("Optimal t = ", t.opt))
    graphics::points(t.opt, h[which(t == t.opt)], pch = "*", cex = 3)
  }
  result <- list("embedding" = embedding, "operator" = operator,
                 "params" = params)
  class(result) <- c("phate", "list")
  return(result)
}

#' Plot a PHATE object in base R
#'
#' @param x A fitted PHATE object
#' @param ... Arguments for plot()
#' @examples
#' if (reticulate::py_module_available("phate")) {
#'
#' library(graphics)
#' # data(tree.data)
#' # We use a smaller tree to make examples run faster
#' data(tree.data.small)
#' phate.tree <- phate(tree.data.small$data)
#' plot(phate.tree, col=tree.data.small$branches)
#'
#' }
#' @rdname plot
#' @method plot phate
#' @export
plot.phate <- function(x, ...) {
  graphics::plot(x$embedding[, 1], x$embedding[, 2], type = "p",
                 xlab = "PHATE1", ylab = "PHATE2", ...)
}

#' Print a PHATE object
#'
#' This avoids spamming the user's console with a list of many large matrices
#'
#' @param x A fitted PHATE object
#' @param ... Arguments for print()
#' @examples
#' if (reticulate::py_module_available("phate")) {
#'
#' # data(tree.data)
#' # We use a smaller tree to make examples run faster
#' data(tree.data.small)
#' phate.tree <- phate(tree.data.small$data)
#' print(phate.tree)
#' ## PHATE embedding with elements
#' ## $embedding : (3000, 2)
#' ## $operator : Python PHATE operator
#' ## $params : list with elements (data, k, alpha, t, n.landmark, ndim,
#' ##                               gamma, npca, mds.method,
#' ##                               knn.dist.method, mds.dist.method)
#'
#' }
#' @rdname print
#' @method print phate
#' @export
print.phate <- function(x, ...) {
  result <- paste0("PHATE embedding with elements\n",
                   "  $embedding : (", nrow(x$embedding), ", ",
                   ncol(x$embedding), ")\n",
                   "  $operator : Python PHATE operator\n",
                   "  $params : list with elements (",
                   paste(names(x$params), collapse = ", "), ")")
  cat(result)
}

#' Summarize a PHATE object
#'
#' @param object A fitted PHATE object
#' @param ... Arguments for summary()
#' @examples
#' if (reticulate::py_module_available("phate")) {
#'
#' # data(tree.data)
#' # We use a smaller tree to make examples run faster
#' data(tree.data.small)
#' phate.tree <- phate(tree.data.small$data)
#' summary(phate.tree)
#' ## PHATE embedding
#' ## k = 5, alpha = 40, t = 58
#' ## Data: (3000, 100)
#' ## Embedding: (3000, 2)
#'
#' }
#' @rdname summary
#' @method summary phate
#' @export
summary.phate <- function(object, ...) {
  result <- paste0("PHATE embedding\n",
                   "k = ", object$params$k,
                   ", alpha = ", object$params$alpha,
                   ", t = ", object$params$t, "\n",
                   "Data: (", nrow(object$params$data),
                   ", ", ncol(object$params$data), ")\n",
                   "Embedding: (", nrow(object$embedding),
                   ", ", ncol(object$embedding), ")")
  cat(result)
}

#' Convert a PHATE object to a matrix
#'
#' Returns the embedding matrix. All components can be accessed
#' using phate$embedding, phate$diff.op, etc
#'
#' @param x A fitted PHATE object
#' @param ... Arguments for as.matrix()
#' @rdname as.matrix
#' @method as.matrix phate
#' @export
as.matrix.phate <- function(x, ...) {
  x$embedding
}
#' Convert a PHATE object to a data.frame
#'
#' Returns the embedding matrix with column names PHATE1 and PHATE2
#'
#' @param x A fitted PHATE object
#' @param ... Arguments for as.data.frame()
#' @rdname as.data.frame
#' @method as.data.frame phate
#' @export
as.data.frame.phate <- function(x, ...) {
  as.data.frame(as.matrix(x), ...)
}

#' Convert a PHATE object to a data.frame for ggplot
#'
#' Passes the embedding matrix to ggplot with column names PHATE1 and PHATE2
#' @importFrom ggplot2 ggplot
#' @param data A fitted PHATE object
#' @param ... Arguments for ggplot()
#' @examples
#' if (reticulate::py_module_available("phate") && require(ggplot2)) {
#'
#' # data(tree.data)
#' # We use a smaller tree to make examples run faster
#' data(tree.data.small)
#' phate.tree <- phate(tree.data.small$data)
#' ggplot(phate.tree, aes(x=PHATE1, y=PHATE2, color=tree.data.small$branches)) +
#'   geom_point()
#'
#' }
#' @rdname ggplot
#' @method ggplot phate
#' @export
ggplot.phate <- function(data, ...) {
  ggplot2::ggplot(as.data.frame(data), ...)
}

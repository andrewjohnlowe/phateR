# Return TRUE if x and y are equal or both NA
null_equal <- function(x, y) {
  if (is.null(x) && is.null(y)) {
    return(TRUE)
  } else if (is.null(x) || is.null(y)) {
    return(FALSE)
  } else {
    return(x == y)
  }
}

load_pyphate <- function(delay_load = FALSE) {
  # load
  if (is.null(pyphate)) {
    # first time load
    result <- try(pyphate <<- reticulate::import("phate", delay_load = delay_load))
  } else {
    # already loaded
    result <- try(reticulate::import("phate", delay_load = delay_load))
  }
  # check
  if (methods::is(result, "try-error")) {
    # failed load
    if ((!delay_load) && length(grep("ModuleNotFoundError: No module named 'phate'", result)) > 0 ||
        length(grep("ImportError: No module named phate", result)) > 0) {
      # not installed
      if (utils::menu(c("Yes", "No"), title="Install PHATE Python package with reticulate?") == 1) {
        install.phate()
      }
    } else if (length(grep("r\\-reticulate", reticulate::py_config()$python)) > 0) {
      # installed, but envs sometimes give weird results
      message("Consider removing the 'r-reticulate' environment by running:")
      if (grep("virtualenvs", reticulate::py_config()$python)) {
        message("reticulate::virtualenv_remove('r-reticulate')")
      } else {
        message("reticulate::conda_remove('r-reticulate')")
      }
    }
  } else if (!delay_load) {
    # successful load
    version <- strsplit(pyphate$`__version__`, '\\.')[[1]]
    major_version <- 0
    minor_version <- 2
    if (as.integer(version[1]) < major_version) {
      warning(paste0("Python PHATE version ", pyphate$`__version__`, " is out of date (recommended: ", 
                  major_version, ".", minor_version, "). Please update with pip or phateR::install.phate()."))
    } else if (as.integer(version[2]) < minor_version) {
      warning(paste0("Python PHATE version ", pyphate$`__version__`, " is out of date (recommended: ", 
                     major_version, ".", minor_version, "). Consider updating with pip or phateR::install.phate()."))
    }
  }
}

#' Install PHATE Python Package
#'
#' Install PHATE Python package into a virtualenv or conda env.
#'
#' On Linux and OS X the "virtualenv" method will be used by default
#' ("conda" will be used if virtualenv isn't available). On Windows,
#' the "conda" method is always used.
#'
#' @param envname Name of environment to install packages into
#' @param method Installation method. By default, "auto" automatically finds
#' a method that will work in the local environment. Change the default to
#' force a specific installation method. Note that the "virtualenv" method
#' is not available on Windows.
#' @param conda Path to conda executable (or "auto" to find conda using the PATH
#'  and other conventional install locations).
#' @param pip Install from pip, if possible.
#' @param ... Additional arguments passed to conda_install() or
#' virtualenv_install().
#'
#' @export
install.phate <- function(envname = "r-reticulate", method = "auto",
                          conda = "auto", pip=TRUE, ...) {
  tryCatch({
    message("Attempting to install PHATE Python package with reticulate")
    reticulate::py_install("phate",
      envname = envname, method = method,
      conda = conda, pip=pip, ...
    )
    message("Install complete. Please restart R and try again.")
  },
  error = function(e) {
    stop(paste0(
      "Cannot locate PHATE Python package, please install through pip ",
      "(e.g. pip install --user phate) and then restart R."
    ))
  }
  )
}

pyphate <- NULL

.onLoad <- function(libname, pkgname) {
  py_config <- reticulate::py_discover_config(required_module = "phate")
  load_pyphate(delay_load = TRUE)
}


<!-- README.md is generated from README.Rmd. Please edit that file -->
phater
======

This R package provides an implementation of the [PHATE dimensionality reduction and visualization method](https://www.biorxiv.org/content/early/2017/12/01/120378).

For a thorough overview of the PHATE visualization method, please see the [bioRxiv preprint](https://www.biorxiv.org/content/early/2017/12/01/120378)

For our Python and Matlab implementations, please see [KrishnaswamyLab/PHATE](https://github.com/KrishnaswamyLab/PHATE).

Installation
------------

You can install phater from github with:

``` r
# install.packages("devtools")
devtools::install_github("KrishnaswamyLab/phater")
```

Example
-------

This is a basic example running `phate` on a highly branched example dataset that is included with the package.

``` r
library(phater)
data(tree.data)
tree.branches <- tree.data$branches
tree.data <- tree.data[,1:60]

# runs phate
tree.phate <- phate(tree.data, 375, 15, 20, pca.method = 'none', mds.method = 'mmds')
#> [1] "No PCA performed"
#> [1] "MDS distance method: euclidean"
#> [1] "No PCA performed"
#> [1] "MDS method: mmds"
# plot embedding
palette(rainbow(10))
plot(tree.phate$embedding[,1], tree.phate$embedding[,2], col = tree.branches, xlab = "phate1", ylab = "phate2")
```

<img src="man/figures/README-example-1.png" width="100%" />

Issues
------

Please let us know of any issues at the [GitHub repo](https://github.com/KrishnaswamyLab/phater/issues)

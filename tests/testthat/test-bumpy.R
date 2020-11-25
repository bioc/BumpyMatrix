# This tests the basic BumpyMatrix functionality.
# library(testthat); library(BumpyMatrix); source("test-bumpy.R")

set.seed(99999000)
library(IRanges)
x <- NumericList(split(runif(50), factor(sample(20, 50, replace=TRUE), 1:20)))  
x <- unname(x)
mat <- BumpyMatrix(x, c(5,4))

test_that("BumpyMatrix constructor works as expected", {
    expect_s4_class(mat, "BumpyNumericMatrix")
    expect_null(rownames(mat))
    expect_null(colnames(mat))
    expect_identical(dim(mat), c(5L, 4L))

    lmat <- BumpyMatrix(x > 0.5, c(5, 4))
    expect_s4_class(lmat, "BumpyLogicalMatrix")

    ix <- relist(as.integer(unlist(x)), x)
    imat <- BumpyMatrix(ix, c(5, 4))
    expect_s4_class(imat, "BumpyIntegerMatrix")

    # Row names are correctly added.
    mat <- BumpyMatrix(x, c(5, 4), dimnames=list(LETTERS[1:5], letters[1:4]))
    expect_identical(rownames(mat), LETTERS[1:5])
    expect_identical(colnames(mat), letters[1:4])

    # Validity method fails correctly.
    expect_error(BumpyMatrix(ix, c(2, 4)), "product")
    expect_error(BumpyMatrix(ix, c(5, 4), dimnames=list("A", NULL)), "rownames.*should be NULL")
    expect_error(BumpyMatrix(ix, c(5, 4), dimnames=list(NULL, "B")), "colnames.*should be NULL")
})

test_that("BumpyMatrix dimnames setter works as expected", {
    rownames(mat) <- letters[1:5]
    expect_identical(rownames(mat), letters[1:5])

    colnames(mat) <- LETTERS[1:4]
    expect_identical(colnames(mat), LETTERS[1:4])

    dimnames(mat) <- NULL
    expect_identical(dimnames(mat), list(NULL, NULL))
})

test_that("BumpyMatrix utility methods work as expected", {
    expect_identical(undim(mat), x)
    expect_identical(unlist(mat), unlist(x))
})

test_that("BumpyMatrix basic subsetter works as expected", {
    # No drop.
    i <- c(3,2,4)
    j <- c(1, 3)
    sub <- mat[i, j]
    expect_identical(dim(sub), c(length(i), length(j)))
    expect_identical(undim(sub), x[as.vector(outer(i, (j - 1) * nrow(mat), "+"))])

    sub <- mat[i,]
    expect_identical(dim(sub), c(length(i), ncol(mat)))
    expect_identical(undim(sub), x[as.vector(outer(i, (0:3) * nrow(mat), "+"))])

    sub <- mat[,j]
    expect_identical(dim(sub), c(nrow(mat), length(j)))
    expect_identical(undim(sub), x[as.vector(outer(1:5, (j - 1) * nrow(mat), "+"))])

    # Make sure dim names come along for the ride.
    rn <- letters[1:5]
    cn <- LETTERS[1:4]
    dimnames(mat) <- list(rn, cn)
    sub <- mat[i,j]
    expect_identical(dimnames(sub), list(rn[i], cn[j]))

    # With a drop.
    sub <- mat[,1]
    expect_identical(unname(sub), unname(head(x, nrow(mat))))
    expect_identical(names(sub), rn)

    sub <- mat[2,]
    expect_identical(unname(sub), unname(x[2 + 0:3 * nrow(mat)]))
    expect_identical(names(sub), cn)

    # Turning off the drop.
    sub <- mat[,1,drop=FALSE]
    expect_s4_class(sub, "BumpyMatrix")

    # Zero-indexing works.
    expect_identical(dim(mat[0,]), c(0L, ncol(mat)))
    expect_identical(dim(mat[,0]), c(nrow(mat), 0L))
})

test_that("BumpyMatrix advanced subsetter works as expected", {
    lmat <- BumpyMatrix(x > 0.5, c(5, 4))
    out <- mat[lmat]
    ref <- BumpyMatrix(x[x > 0.5], c(5, 4))
    expect_identical(out, ref)
    expect_error(mat[lmat[,1:2]], "same dimensions")
})

test_that("BumpyMatrix subset replacement works as expected", {
    mod <- mat
    mod[,1] <- mod[,2,drop=FALSE]
    expect_identical(mod[,1], mod[,2])

    mod <- mat
    mod[1,] <- mod[2,,drop=FALSE]
    expect_identical(mod[1,], mod[2,])

    mod <- mat
    dimnames(mod) <- NULL
    mod[1:2,3:4] <- mod[4:5,2:3,drop=FALSE]
    expect_identical(mod[1:2,3:4], mod[4:5,2:3])
})

test_that("BumpyMatrix combining works as expected", {
    # rbind() works as expected.
    x2 <- NumericList(split(runif(10), factor(sample(8, 10, replace=TRUE), 1:8)))  
    x2 <- unname(x2)
    mat2 <- BumpyMatrix(x2, c(2,4))

    output <- rbind(mat, mat2)
    expect_identical(dim(output), c(7L, 4L))
    expect_identical(output[1,], mat[1,])
    expect_identical(output[6,], mat2[1,])
    expect_identical(output[,2], c(mat[,2], mat2[,2]))
    expect_identical(output[,4], c(mat[,4], mat2[,4]))

    # cbind() works as expected.
    x2 <- NumericList(split(runif(10), factor(sample(10, 10, replace=TRUE), 1:10)))  
    x2 <- unname(x2)
    mat2 <- BumpyMatrix(x2, c(5,2))

    output <- cbind(mat, mat2)
    expect_identical(dim(output), c(5L, 6L))
    expect_identical(output[,1], mat[,1])
    expect_identical(output[,5], mat2[,1])
    expect_identical(output[2,], c(mat[2,], mat2[2,]))
    expect_identical(output[4,], c(mat[4,], mat2[4,]))

    # Works with dimnames.
    dimnames(mat) <- list(letters[1:5], LETTERS[1:4])
    copy <- mat
    dimnames(copy) <- list(letters[5+1:5], LETTERS[4+1:4])
    expect_identical(dimnames(rbind(mat, copy)), list(letters[1:10], LETTERS[1:4]))
    expect_identical(dimnames(cbind(mat, copy)), list(letters[1:5], LETTERS[1:8]))

    # Errors out.
    expect_error(rbind(mat, mat[,1:2]), "same")
    expect_error(cbind(mat, mat[1:2,]), "same")
})

test_that("BumpyMatrix transposition works as expected", {
    tmat <- t(mat)
    expect_identical(mat[,2], tmat[2,])
    expect_identical(mat[4,], tmat[,4])

    # Works with some dimnames.
    dimnames(mat) <- list(letters[1:5], LETTERS[1:4])
    tmat <- t(mat)
    expect_identical(rownames(mat), colnames(tmat))
    expect_identical(colnames(mat), rownames(tmat))
})
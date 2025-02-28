#' @title Cross-validate temporal patterns
#' @name sits_kfold_validate
#' @author Rolf Simoes, \email{rolf.simoes@@inpe.br}
#' @author Gilberto Camara, \email{gilberto.camara@@inpe.br}
#'
#' @description Splits the set of time series into training and validation and
#' perform k-fold cross-validation.
#' Cross-validation is a technique for assessing how the results
#' of a statistical analysis will generalize to an independent data set.
#' It is mainly used in settings where the goal is prediction,
#' and one wants to estimate how accurately a predictive model will perform.
#' One round of cross-validation involves partitioning a sample of data
#' into complementary subsets, performing the analysis on one subset
#' (called the training set), and validating the analysis on the other subset
#' (called the validation set or testing set).
#'
#' The k-fold cross validation method involves splitting the dataset
#' into k-subsets. For each subset is held out while the model is trained
#' on all other subsets. This process is completed until accuracy
#' is determine for each instance in the dataset, and an overall
#' accuracy estimate is provided.
#'
#' This function returns the confusion matrix, and Kappa values.
#'
#' @param data            A sits tibble.
#' @param folds           Number of partitions to create.
#' @param ml_method       Machine learning method.
#' @param multicores      Number of cores for processing.
#' @return A tibble containing pairs of reference and predicted values.
#'
#' @examples
#' \donttest{
#' # read a set of samples
#' data(cerrado_2classes)
#' # two fold validation with random forest
#' acc <- sits_kfold_validate(cerrado_2classes,
#'     folds = 2,
#'     ml_method = sits_rfor(num_trees = 300)
#' )
#' }
#'
#' @export
#'
sits_kfold_validate <- function(data, folds = 5,
                                ml_method = sits_rfor(), multicores = 2) {

    # require package
    if (!requireNamespace("caret", quietly = TRUE)) {
        stop("Please install package caret.", call. = FALSE)
    }

    # backward compatibility
    data <- .sits_tibble_rename(data)

    # get the labels of the data
    labels <- sits_labels(data)

    # create a named vector with integers match the class labels
    n_labels <- length(labels)
    int_labels <- c(1:n_labels)
    names(int_labels) <- labels

    # is the data labelled?
    assertthat::assert_that(
        !("NoClass" %in% sits_labels(data)),
        msg = "sits_cross_validate: requires labelled set of time series"
    )

    # create partitions different splits of the input data
    data <- .sits_create_folds(data, folds = folds)

    # create prediction and reference vector
    pred_vec <- character()
    ref_vec <- character()
    # save original future plan
    if (multicores > 1) {
        oplan <- future::plan("multisession", workers = multicores)
    } else {
        oplan <- future::plan("sequential")
    }
    on.exit(future::plan(oplan), add = TRUE)

    # read the blocks and compute the probabilities
    conf_lst <- furrr::future_map(seq_len(folds), function(k) {

        # split data into training and test data sets
        data_train <- data[data$folds != k, ]
        data_test <- data[data$folds == k, ]

        # create a machine learning model
        ml_model <- sits_train(data_train, ml_method)

        # has normalization been applied to the data?
        stats <- environment(ml_model)$stats

        # obtain the distances after normalizing data by band
        if (!purrr::is_null(stats)) {
            distances <- .sits_distances(
                .sits_normalize_data(data_test, stats)
            )
        } else {
            distances <- .sits_distances(data_test)
        }

        # classify the test data
        prediction <- ml_model(distances)
        # extract the values
        values <- names(int_labels[max.col(prediction)])

        ref_vec <- c(ref_vec, data_test$label)
        pred_vec <- c(pred_vec, values)

        return(list(pred = pred_vec, ref = ref_vec))
    })

    pred <- unlist(lapply(conf_lst, function(x) x$pred))
    ref  <- unlist(lapply(conf_lst, function(x) x$ref))

    # call caret to provide assessment
    unique_ref <- unique(ref)
    pred_fac   <- factor(pred, levels = unique_ref)
    ref_fac    <- factor(ref, levels = unique_ref)

    # call caret package to the classification statistics
    assess <- caret::confusionMatrix(pred_fac, ref_fac)

    class(assess) <- c("sits_assessment", class(assess))

    return(assess)
}

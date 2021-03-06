


# in-memory direct functionality




#' @importFrom stats as.formula
NULL




#' @export
#' @rdname build_pivot_control
build_pivot_control.default <- function(table,
                                        columnToTakeKeysFrom,
                                        columnToTakeValuesFrom,
                                        ...,
                                        prefix = columnToTakeKeysFrom,
                                        sep = NULL,
                                        tmp_name_source = wrapr::mk_tmp_name_source("bpcd"),
                                        temporary = TRUE) {
  wrapr::stop_if_dot_args(substitute(list(...)), "cdata::build_pivot_control")
  if(!is.data.frame(table)) {
    stop("build_pivot_control.default table should be a data.frame")
  }
  controlTable <- data.frame(vals = unique(table[[columnToTakeKeysFrom]]),
                             stringsAsFactors = FALSE)
  colnames(controlTable) <- columnToTakeKeysFrom
  controlTable[[columnToTakeKeysFrom]] <- as.character(controlTable[[columnToTakeKeysFrom]])
  controlTable[[columnToTakeValuesFrom]] <- controlTable[[columnToTakeKeysFrom]]
  if(!is.null(sep)) {
    controlTable[[columnToTakeValuesFrom]] <- paste(prefix,
                                                    controlTable[[columnToTakeValuesFrom]],
                                                    sep=sep)
  }
  controlTable
}


#' Build a rowrecs_to_blocks() control table that specifies a un-pivot (or "shred").
#'
#' Some discussion and examples can be found here:
#' \url{https://winvector.github.io/FluidData/FluidData.html} and
#' here \url{https://github.com/WinVector/cdata}.
#'
#' @param nameForNewKeyColumn character name of column to write new keys in.
#' @param nameForNewValueColumn character name of column to write new values in.
#' @param columnsToTakeFrom character array names of columns to take values from.
#' @param ... not used, force later args to be by name
#' @return control table
#'
#' @seealso \code{\link{rowrecs_to_blocks}}
#'
#' @examples
#'
#' build_unpivot_control("measurmentType", "measurmentValue", c("c1", "c2"))
#'
#' @export
build_unpivot_control <- function(nameForNewKeyColumn,
                                  nameForNewValueColumn,
                                  columnsToTakeFrom,
                                  ...) {
  wrapr::stop_if_dot_args(substitute(list(...)), "cdata::build_unpivot_control")
  controlTable <- data.frame(x = as.character(columnsToTakeFrom),
                             y = as.character(columnsToTakeFrom),
                             stringsAsFactors = FALSE)
  colnames(controlTable) <- c(nameForNewKeyColumn, nameForNewValueColumn)
  controlTable
}




#' @export
#' @rdname rowrecs_to_blocks
rowrecs_to_blocks.default <- function(wideTable,
                                      controlTable,
                                      ...,
                                      checkNames = TRUE,
                                      checkKeys = FALSE,
                                      strict = FALSE,
                                      controlTableKeys = colnames(controlTable)[[1]],
                                      columnsToCopy = NULL,
                                      tmp_name_source = wrapr::mk_tmp_name_source("rrtobd"),
                                      temporary = TRUE,
                                      allow_rqdatatable = TRUE) {
  wrapr::stop_if_dot_args(substitute(list(...)), "cdata::rowrecs_to_blocks")
  if(!is.data.frame(wideTable)) {
    stop("cdata::rowrecs_to_blocks.default wideTable should be a data.frame")
  }

  check_rowrecs_to_blocks_args(wideTable_columns = colnames(wideTable),
                               controlTable = controlTable,
                               checkNames = checkNames,
                               strict = strict,
                               controlTableKeys = controlTableKeys,
                               columnsToCopy = columnsToCopy)

  rownames(wideTable) <- NULL
  controlTableValueColumns <- setdiff(colnames(controlTable), controlTableKeys)

  # check more
  if(checkKeys) {
    if(!check_cols_form_unique_keys(wideTable, columnsToCopy)) {
      stop("cdata::rowrecs_to_blocks columnsToCopy do not uniquely key the rows")
    }
  }

  # see if it is an obvious simple unpivot
  if(allow_rqdatatable &&
     (ncol(controlTable)==2) &&
     requireNamespace("rqdatatable", quietly = TRUE) &&
     (isTRUE(all.equal(controlTable[ ,1, drop = TRUE],
                       controlTable[ ,2, drop = TRUE]))) &&
     (controlTableKeys == colnames(controlTable)[[1]])) {
    res <- rqdatatable::layout_to_blocks_data_table(
      data = wideTable,
      nameForNewKeyColumn = colnames(controlTable)[[1]],
      nameForNewValueColumn = colnames(controlTable)[[2]],
      columnsToTakeFrom = controlTable[, 2, drop = TRUE],
      columnsToCopy = columnsToCopy)
    res <- data.frame(res)
    rownames(res) <- NULL
    return(res)
  }

  # do the work
  n_row_in <- nrow(wideTable)
  n_rep <- nrow(controlTable)
  n_row_res <- n_rep*n_row_in
  # build and start filling in result
  res <- data.frame(x = seq_len(n_row_in))
  res[['x']] <- NULL
  for(cn in columnsToCopy) {
    res[[cn]] <- wideTable[[cn]]
  }
  for(cn in controlTableKeys) {
    res[[cn]] <- NA_character_
  }
  for(cn in controlTableValueColumns) {
    wtn <- wideTable[[controlTable[1, cn, drop = TRUE]]]
    if(is.factor(wtn)) {
      wtn <- as.character(wtn)
    }
    res[[cn]] <- wtn
    res[[cn]][seq_len(n_row_in)] <- NA
  }
  # cross product with control table
  res <- res[sort(rep(seq_len(n_row_in), n_rep)), , drop = FALSE] # TODO: speedup hotspot
  rownames(res) <- NULL
  for(cn in controlTableKeys) {
    res[[cn]] <- rep(controlTable[[cn]], n_row_in)
  }
  # fill in values
  for(cn in controlTableValueColumns) {
    for(i in seq_len(n_rep)) {
      indxs <- i + n_rep*(0:(n_row_in-1))
      col <- controlTable[i, cn, drop = TRUE]
      wtni <- wideTable[[col]]
      if(is.factor(wtni)) {
        wtni <- as.character(wtni)
      }
      res[[cn]][indxs] <- wtni # TODO: speedup hotspot
    }
  }
  rownames(res) <- NULL
  res
}



#' @export
#' @rdname blocks_to_rowrecs
blocks_to_rowrecs.default <- function(tallTable,
                                      keyColumns,
                                      controlTable,
                                      ...,
                                      columnsToCopy = NULL,
                                      checkNames = TRUE,
                                      checkKeys = FALSE,
                                      strict = FALSE,
                                      controlTableKeys = colnames(controlTable)[[1]],
                                      tmp_name_source = wrapr::mk_tmp_name_source("btrd"),
                                      temporary = TRUE,
                                      allow_rqdatatable = FALSE) {
  wrapr::stop_if_dot_args(substitute(list(...)), "cdata::blocks_to_rowrecs")
  if(!is.data.frame(tallTable)) {
    stop("cdata::blocks_to_rowrecs.default tallTable should be a data.frame")
  }

  check_blocks_to_rowrecs_args(tallTable_columns = colnames(tallTable),
                               keyColumns = keyColumns,
                               controlTable = controlTable,
                               columnsToCopy = columnsToCopy,
                               checkNames = checkNames,
                               strict = strict,
                               controlTableKeys = controlTableKeys)

  rownames(tallTable) <- NULL
  clear_key_column <- FALSE
  if(length(keyColumns)<=0) {
    # avoid no-keys case
    tallTable$cdata_key_column <- 1
    keyColumns <- "cdata_key_column"
    clear_key_column <- TRUE
  }
  controlTableValueColumns <- setdiff(colnames(controlTable), controlTableKeys)

  # check more
  if(checkKeys) {
    # check keyColumns plus controltable keys key data
    if(!check_cols_form_unique_keys(tallTable, c(controlTableKeys, keyColumns))) {
      stop(paste("cdata::blocks_to_rowrecs: controlTableKeys plus keyColumns do not uniquely index data"))
    }
  }

  # see if it is an obvious simple unpivot
  if(allow_rqdatatable &&
     (ncol(controlTable)==2) &&
     requireNamespace("rqdatatable", quietly = TRUE) &&
     (isTRUE(all.equal(controlTable[ ,1, drop = TRUE],
                       controlTable[ ,2, drop = TRUE]))) &&
     (controlTableKeys == colnames(controlTable)[[1]])) {
    res <- rqdatatable::layout_to_rowrecs_data_table(
      data = tallTable,
      columnToTakeKeysFrom = colnames(controlTable)[[1]],
      columnToTakeValuesFrom= colnames(controlTable)[[2]],
      rowKeyColumns = keyColumns)
    res <- data.frame(res)
    rownames(res) <- NULL
    return(res)
  }

  # do the work
  # make simple grouping keys
  tallTable$cdata_group_key_col <- 1
  if(length(keyColumns)>=1) {
    cols <- as.list(tallTable[ , keyColumns, drop=FALSE])
    names(cols) <- NULL
    keys <- do.call("paste", c(cols, sep = " CDATA_SEP "))
    tallTable$cdata_group_key_col <- match(keys, keys)
    tallTable <- tallTable[order(tallTable$cdata_group_key_col), , drop = FALSE]
  }
  first_idxs <- match(unique(tallTable$cdata_group_key_col), tallTable$cdata_group_key_col)
  res <- tallTable[first_idxs,
                   c("cdata_group_key_col", keyColumns, columnsToCopy),
                   drop = FALSE]
  rownames(res) <- NULL
  n_res <- nrow(res)
  # fill in values
  tallTable$composite_meas_col <- do.call(paste,
                                          c(as.list(tallTable[, controlTableKeys, drop = FALSE]),
                                            list(sep = " CDATA_K_SEP ")))
  controlTable$composite_meas_col <- do.call(paste,
                                             c(as.list(controlTable[, controlTableKeys, drop = FALSE]),
                                               list(sep = " CDATA_K_SEP ")))
  n_rep <- nrow(controlTable)
  for(cn in controlTableValueColumns) {
    for(i in seq_len(n_rep)) {
      srccol <- controlTable$composite_meas_col[[i]]
      destcol <- controlTable[[cn]][i]
      indxs <- which(tallTable$composite_meas_col == srccol)  # TODO: speedup hotspot
      vals <- tallTable[[cn]][indxs]
      res[[destcol]] <- vals[[1]]
      res[[destcol]][seq_len(n_res)] <- NA
      posns <- match(res$cdata_group_key_col,
                     tallTable$cdata_group_key_col[indxs])
      lhs <- seq_len(n_res)
      lhs <- lhs[!is.na(posns)]
      posns <- posns[!is.na(posns)]
      res[[destcol]][lhs] <- vals[posns]
    }
  }
  res$cdata_group_key_col <- NULL
  if(clear_key_column) {
    res$cdata_key_column <- NULL
  }
  rownames(res) <- NULL
  res
}






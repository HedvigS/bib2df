#' @importFrom stringr str_match
#' @importFrom stringr str_extract
#' @importFrom dplyr bind_rows
#' @importFrom dplyr as_tibble
#' @importFrom stats complete.cases


bib2df_gather <- function(bib) {

  from <- which(str_extract(bib, "[:graph:]") == "@")
  to  <- c(from[-1] - 1, length(bib))
  if (!length(from)) {
    return(empty)
  }
  itemslist <- mapply(
    function(x, y) return(bib[x:y]),
    x = from,
    y = to - 1,
    SIMPLIFY = FALSE
    )
  keys <- lapply(itemslist,
                 function(x) {
                   str_extract(x[1], "(?<=\\{)[^,]+")
                 }
  )
  fields <- lapply(itemslist,
                   function(x) {
                     str_extract(x[1], "(?<=@)[^\\{]+")
                   }
  )
  fields <- lapply(fields, toupper)

  categories <- lapply(itemslist,
                       function(x) {
                         str_extract(x, "[[:alnum:]_-]+")
                       }
  )

  # categories <- lapply(categories, trimws)

  dupl <- sum(
    unlist(
      lapply(categories, function(x) sum(duplicated(x[!is.na(x)])))
    )
  )

  if (dupl > 0) {
    warning("There were issues with the syntax of the bibTeX.file.
            Some BibTeX entries may have been dropped.
            The result could be malformed.
            Review the .bib file and make sure every single entry starts
            with a '@' and that there are no duplicates entries (same key) or duplicate fields within an entry.")
  }

  values <- lapply(itemslist,
                   function(x) {
                     str_extract(x, "(?<==).*")
                   }
  )

  values <- lapply(values,
                   function(x) {
                     sapply(x, text_between_curly_brackets, simplify = TRUE, USE.NAMES = FALSE)
                   }
  )

  values <- lapply(values, trimws)
  items <- mapply(cbind, categories, values, SIMPLIFY = FALSE)
  items <- lapply(items,
                  function(x) {
                    x <- cbind(toupper(x[, 1]), x[, 2])
                  }
  )
  items <- lapply(items,
                  function(x) {
                    x[complete.cases(x), ]
                  }
  )
  items <- mapply(function(x, y) {
    rbind(x, c("CATEGORY", y))
    },
    x = items, y = fields, SIMPLIFY = FALSE)

  items <- lapply(items, t)
  items <- lapply(items,
                  function(x) {
                    colnames(x) <- x[1, ]
                    x <- x[-1, ]
                    return(x)
                  }
  )
  items <- lapply(items,
                  function(x) {
                    x <- t(x)
                    x <- data.frame(x, stringsAsFactors = FALSE)
                    return(x)
                  }
  )
  dat <- bind_rows(c(list(empty), items))
  dat <- as_tibble(dat)
  dat$BIBTEXKEY <- unlist(keys)
  dat
}

empty <- data.frame(
  CATEGORY = character(0L),
  BIBTEXKEY = character(0L),
  ADDRESS = character(0L),
  ANNOTE = character(0L),
  AUTHOR = character(0L),
  BOOKTITLE = character(0L),
  CHAPTER = character(0L),
  CROSSREF = character(0L),
  EDITION = character(0L),
  EDITOR = character(0L),
  HOWPUBLISHED = character(0L),
  INSTITUTION = character(0L),
  JOURNAL = character(0L),
  KEY = character(0L),
  MONTH = character(0L),
  NOTE = character(0L),
  NUMBER = character(0L),
  ORGANIZATION = character(0L),
  PAGES = character(0L),
  PUBLISHER = character(0L),
  SCHOOL = character(0L),
  SERIES = character(0L),
  TITLE = character(0L),
  TYPE = character(0L),
  VOLUME = character(0L),
  YEAR = character(0L),
  stringsAsFactors = FALSE
)

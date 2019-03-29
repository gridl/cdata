
test_operators <- function() {
  # ## TODO: switch to this one wrapr build_frame can handle this (wrapr 1.8.6).
  # d <- wrapr::build_frame(
  #   "date", "measure", "value" |
  #     as.Date("2019-03-01")   , "AUC"    , as.Date("2019-03-11")     |
  #     as.Date("2019-03-01")   , "R2"     , as.Date("2019-03-12")     |
  #     as.Date("2019-03-02")   , "AUC"    , as.Date("2019-03-13")     |
  #     as.Date("2019-03-02")   , "R2"     , as.Date("2019-03-14")     )
  d <- data.frame(date = c(as.Date("2019-03-01") , as.Date("2019-03-01"), as.Date("2019-03-02") , as.Date("2019-03-02") ),
                  measure = c("AUC", "R2", "AUC", "R2"),
                  value = c(as.Date("2019-03-11") , as.Date("2019-03-12"), as.Date("2019-03-13") , as.Date("2019-03-14") ),
                  stringsAsFactors = FALSE)

  record_spec <- rowrecs_to_blocks_spec(
    wrapr::qchar_frame(
      measure, value |
        AUC    , "AUC" |
        R2     , "R2"  ),
    recordKeys = "date")

  d %//% t(record_spec) %**% record_spec -> r
  RUnit::checkTrue("Date" %in% class(d$date))
  RUnit::checkTrue("Date" %in% class(d$value))
  RUnit::checkTrue(wrapr::check_equiv_frames(d, r))

  invisible(NULL)
}
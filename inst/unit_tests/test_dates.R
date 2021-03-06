
test_dates <- function() {

  d <- data.frame(row_id = 1:4)
  d$d1 <- as.Date("2019-03-11")
  d$d2 <- as.Date("2019-03-21")
  d$t1 <- as.POSIXct(1472562988, origin = "1960-01-01")
  d$t2 <- as.POSIXct(1472562988, origin = "1960-01-01", tz = "GMT")
  d$t3 <- as.POSIXlt(1472562988, origin = "1960-01-01", tz = "GMT")
  d$t4 <- as.POSIXlt(1472562988, origin = "1960-01-01", tz = "GMT")

  layout <- rowrecs_to_blocks_spec(
    wrapr::qchar_frame(
        "group", "d", "t", "z" |
        "1"   ,   d1,  t1, t3  |
        "2"   ,   d2,  t2, t4  ),
    recordKeys = "row_id")

  r <- d %.>% layout

  RUnit::checkTrue("Date" %in% class(r$d))
  RUnit::checkTrue("POSIXct" %in% class(r$t))
  RUnit::checkTrue("POSIXlt" %in% class(r$z))

  inv <- t(layout)
  b <- r %.>% inv

  RUnit::checkTrue("Date" %in% class(b$d1))
  RUnit::checkTrue("Date" %in% class(b$d2))
  RUnit::checkTrue("POSIXct" %in% class(b$t1))
  RUnit::checkTrue("POSIXct" %in% class(b$t2))
  RUnit::checkTrue("POSIXlt" %in% class(b$t3))
  RUnit::checkTrue("POSIXlt" %in% class(b$t4))

  # for mixed time zones
  # time and time zone will change on POSIXct, but POSIXlt get messed up.
  d <- data.frame(row_id = 1:4)
  d$d1 <- as.Date("2019-03-11")
  d$d2 <- as.Date("2019-03-21")
  d$t1 <- as.POSIXct(1472562988, origin = "1960-01-01", tz = "GMT")
  d$t2 <- as.POSIXct(1472562988, origin = "1960-01-01", tz = "GMT")
  d$t3 <- as.POSIXlt(1472562988, origin = "1960-01-01", tz = "GMT")
  d$t4 <- as.POSIXlt(1472562988, origin = "1960-01-01", tz = "GMT")

  RUnit::checkTrue(wrapr::check_equiv_frames(d, b))

  invisible(NULL)
}

private = list(
  read_output_lines = function(in_buf) {
    count <- in_buf$read_int()
    lines <- vector("list", count)
    for (i in seq_len(count)) {
      type <- in_buf$read_byte()  # OutputLineType enum
      cc <- in_buf$read_byte()    # CarriageControlType enum
      text <- in_buf$read_string()
      lines[[i]] <- list(type = type, cc = cc, text = text)
    }
    lines
  }
)
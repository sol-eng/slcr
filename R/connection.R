#' Base Connection Class
#'
#' @description Abstract base class for connections
#' @noRd
Connection <- R6::R6Class(
  "Connection",
  public = list(
    #' @description Send data through connection
    #' @param buff CDR buffer
    send = function(buff) {
      stop("send() must be implemented by subclass")
    },

    #' @description Receive data through connection
    #' @param buff CDR buffer
    recv = function(buff) {
      stop("recv() must be implemented by subclass")
    }
  )
)

#' Named Pipe Connection
#'
#' @description Connection using named pipes for IPC with SLC process
#' @noRd
NamedPipeConnection <- R6::R6Class(
  "NamedPipeConnection",
  inherit = Connection,
  private = list(
    input_pipe = NULL,
    output_pipe = NULL,
    input_con = NULL,
    output_con = NULL,

    # Finalizer
    finalize = function() {
      if (!is.null(private$input_con)) {
        try(close(private$input_con), silent = TRUE)
      }
      if (!is.null(private$output_con)) {
        try(close(private$output_con), silent = TRUE)
      }
    }
  ),

  public = list(
    #' @description Create named pipe connection
    #' @param input_pipe_name Path to input pipe
    #' @param output_pipe_name Path to output pipe
    initialize = function(input_pipe_name, output_pipe_name) {
      # Open pipes in the same order as the Python implementation
      # Output pipe first, then input pipe
      # Use r+b mode which opens for both read/write and doesn't block
      private$output_pipe <- output_pipe_name
      private$input_pipe <- input_pipe_name

      # Open for binary I/O in non-blocking mode
      # r+b opens for read/write which avoids blocking on FIFO open
      # Explicitly set raw=TRUE to suppress warnings about FIFOs
      private$output_con <- file(output_pipe_name, open = "r+b", raw = TRUE)

      private$input_con <- file(input_pipe_name, open = "r+b", raw = TRUE)
    },

    #' @description Send data through output pipe
    #' @param buff CDR buffer
    send = function(buff) {
      data <- buff$buffer()
      if (length(data) > 0) {
        writeBin(data, private$output_con)
        flush(private$output_con)
      }
      invisible(self)
    },

    #' @description Receive data through input pipe
    #' @param buff CDR buffer
    recv = function(buff) {
      # Read in a loop to handle partial reads, like the Python implementation
      # We need to be careful with buffering - R's readBin can block differently
      # than Python's unbuffered I/O
      while (buff$remaining() > 0) {
        remaining <- buff$remaining()

        # Try to read data - use a smaller chunk size to avoid blocking issues
        # Read one byte at a time if we're having issues, otherwise read in chunks
        chunk_size <- min(remaining, 8192) # Read in 8KB chunks or less
        data <- readBin(private$input_con, what = "raw", n = chunk_size)

        if (length(data) == 0) {
          # No data available - this shouldn't happen in blocking mode
          stop("Failed to read any bytes from pipe (connection may be closed)")
        }

        # Copy data into buffer (write_byte advances position automatically)
        for (i in seq_along(data)) {
          buff$write_byte(data[i])
        }
      }
      invisible(self)
    }
  )
)

#' Process Connection
#'
#' @description Connection using stdin/stdout of a subprocess
#' @noRd
ProcessConnection <- R6::R6Class(
  "ProcessConnection",
  inherit = Connection,
  private = list(
    process = NULL
  ),

  public = list(
    #' @description Create process connection
    #' @param process A processx process object
    initialize = function(process) {
      private$process <- process
    },

    #' @description Send data to process stdin
    #' @param buff CDR buffer
    send = function(buff) {
      data <- buff$buffer()
      if (length(data) > 0) {
        private$process$write_input(data)
      }
      invisible(self)
    },

    #' @description Receive data from process stdout
    #' @param buff CDR buffer
    recv = function(buff) {
      # Read in a loop to handle partial reads, like the Python implementation
      while (buff$remaining() > 0) {
        remaining <- buff$remaining()
        # Read whatever is available, up to remaining bytes
        data <- private$process$read_output_bytes(n = remaining)

        if (length(data) == 0) {
          # No data available - this shouldn't happen in blocking mode
          stop(
            "Failed to read any bytes from process (connection may be closed)"
          )
        }

        # Copy data into buffer (write_byte advances position automatically)
        for (i in seq_along(data)) {
          buff$write_byte(data[i])
        }
      }
      invisible(self)
    }
  )
)

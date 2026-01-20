#' CDR Buffer for Binary Wire Format
#'
#' @description
#' Buffer class for reading and writing the binary wire format used by the ORB.
#' This implements the Common Data Representation (CDR) protocol for marshalling
#' data between R and the SLC process.
#'
#' @export
CdrBuffer <- R6::R6Class(
  "CdrBuffer",
  private = list(
    bytes = NULL,
    pos = 0L,
    lim = 0L,
    cap = 0L,
    endian = "big",
    orb_ref = NULL,

    ensure_write = function(count) {
      if (count > self$remaining()) {
        required_cap <- self$capacity() + count
        new_cap <- self$capacity()
        while (new_cap < required_cap) {
          new_cap <- new_cap * 2L
        }
        self$reserve(new_cap)
      }
    },

    ensure_read = function(count) {
      if (count > self$remaining()) {
        stop(sprintf(
          "Required %d bytes for read but only %d bytes remain",
          count,
          self$remaining()
        ))
      }
    }
  ),

  public = list(
    #' @description Create a new CDR buffer
    #' @param orb The ORB instance
    #' @param initial_capacity Initial buffer capacity in bytes
    initialize = function(orb, initial_capacity = 4096L) {
      if (initial_capacity <= 0) {
        stop("Initial capacity must be > 0")
      }
      private$bytes <- raw(initial_capacity)
      private$cap <- initial_capacity
      private$lim <- initial_capacity
      private$pos <- 0L
      private$orb_ref <- orb
    },

    #' @description Clear the buffer ready for read
    clear = function() {
      private$pos <- 0L
      private$lim <- private$cap
      invisible(self)
    },

    #' @description Flip buffer from write to read mode
    flip = function() {
      private$lim <- private$pos
      private$pos <- 0L
      invisible(self)
    },

    #' @description Get current position
    position = function() {
      private$pos
    },

    #' @description Set position
    #' @param pos New position
    set_position = function(pos) {
      if (pos > private$lim) {
        stop(sprintf(
          "Position %d must be less than limit %d",
          pos,
          private$lim
        ))
      }
      private$pos <- as.integer(pos)
      invisible(self)
    },

    #' @description Get current limit
    limit = function() {
      private$lim
    },

    #' @description Set limit
    #' @param limit New limit
    set_limit = function(limit) {
      if (limit > private$cap) {
        stop(sprintf(
          "Limit %d must be less than capacity %d",
          limit,
          private$cap
        ))
      }
      private$lim <- as.integer(limit)
      if (private$pos > limit) {
        private$pos <- limit
      }
      invisible(self)
    },

    #' @description Get buffer capacity
    capacity = function() {
      private$cap
    },

    #' @description Reserve capacity
    #' @param new_cap New capacity
    reserve = function(new_cap) {
      if (new_cap > private$cap) {
        old_bytes <- private$bytes
        old_cap <- private$cap
        private$cap <- as.integer(new_cap)
        private$bytes <- raw(private$cap)
        private$bytes[1:old_cap] <- old_bytes
      }
      invisible(self)
    },

    #' @description Get remaining bytes
    remaining = function() {
      private$lim - private$pos
    },

    #' @description Get buffer as raw vector
    buffer = function() {
      if (private$pos >= private$lim) {
        return(raw(0))
      }
      private$bytes[(private$pos + 1):private$lim]
    },

    #' @description Write a boolean
    #' @param b Boolean value
    write_boolean = function(b) {
      private$ensure_write(1L)
      private$bytes[private$pos + 1L] <- as.raw(as.integer(b))
      private$pos <- private$pos + 1L
      invisible(self)
    },

    #' @description Write a byte
    #' @param b Byte value (0-255)
    write_byte = function(b) {
      private$ensure_write(1L)
      private$bytes[private$pos + 1L] <- as.raw(b)
      private$pos <- private$pos + 1L
      invisible(self)
    },

    #' @description Write a short (2 bytes)
    #' @param s Short integer value
    write_short = function(s) {
      private$ensure_write(2L)
      writeBin(
        as.integer(s),
        con = raw(),
        size = 2L,
        endian = private$endian
      ) -> bytes
      private$bytes[(private$pos + 1L):(private$pos + 2L)] <- bytes
      private$pos <- private$pos + 2L
      invisible(self)
    },

    #' @description Write an integer (4 bytes)
    #' @param i Integer value
    write_int = function(i) {
      private$ensure_write(4L)
      writeBin(
        as.integer(i),
        con = raw(),
        size = 4L,
        endian = private$endian
      ) -> bytes
      private$bytes[(private$pos + 1L):(private$pos + 4L)] <- bytes
      private$pos <- private$pos + 4L
      invisible(self)
    },

    #' @description Write a long (8 bytes)
    #' @param l Long integer value
    write_long = function(l) {
      private$ensure_write(8L)
      # R doesn't have true 64-bit integers, use numeric
      writeBin(
        as.numeric(l),
        con = raw(),
        size = 8L,
        endian = private$endian
      ) -> bytes
      private$bytes[(private$pos + 1L):(private$pos + 8L)] <- bytes
      private$pos <- private$pos + 8L
      invisible(self)
    },

    #' @description Write a float (4 bytes)
    #' @param f Float value
    write_float = function(f) {
      private$ensure_write(4L)
      writeBin(
        as.numeric(f),
        con = raw(),
        size = 4L,
        endian = private$endian
      ) -> bytes
      private$bytes[(private$pos + 1L):(private$pos + 4L)] <- bytes
      private$pos <- private$pos + 4L
      invisible(self)
    },

    #' @description Write a double (8 bytes)
    #' @param d Double value
    write_double = function(d) {
      private$ensure_write(8L)
      writeBin(
        as.numeric(d),
        con = raw(),
        size = 8L,
        endian = private$endian
      ) -> bytes
      private$bytes[(private$pos + 1L):(private$pos + 8L)] <- bytes
      private$pos <- private$pos + 8L
      invisible(self)
    },

    #' @description Write a string
    #' @param s String value
    write_string = function(s) {
      if (is.null(s) || length(s) == 0 || s == "") {
        self$write_int(0L)
      } else {
        utf8_bytes <- charToRaw(enc2utf8(s))
        len <- length(utf8_bytes)
        self$write_int(len)
        private$ensure_write(len)
        private$bytes[(private$pos + 1L):(private$pos + len)] <- utf8_bytes
        private$pos <- private$pos + len
      }
      invisible(self)
    },

    #' @description Write an object reference
    #' @param obj Object instance
    write_object = function(obj) {
      if (is.null(obj)) {
        self$write_string("")
      } else {
        self$write_string(obj$identity())
      }
      invisible(self)
    },

    #' @description Read a boolean
    #' @return Boolean value
    read_boolean = function() {
      private$ensure_read(1L)
      result <- as.logical(private$bytes[private$pos + 1L])
      private$pos <- private$pos + 1L
      result
    },

    #' @description Read a byte
    #' @return Byte value
    read_byte = function() {
      private$ensure_read(1L)
      result <- as.integer(private$bytes[private$pos + 1L])
      private$pos <- private$pos + 1L
      result
    },

    #' @description Read a short
    #' @return Short integer value
    read_short = function() {
      private$ensure_read(2L)
      bytes <- private$bytes[(private$pos + 1L):(private$pos + 2L)]
      result <- readBin(
        bytes,
        what = "integer",
        n = 1L,
        size = 2L,
        endian = private$endian
      )
      private$pos <- private$pos + 2L
      result
    },

    #' @description Read an integer
    #' @return Integer value
    read_int = function() {
      private$ensure_read(4L)
      bytes <- private$bytes[(private$pos + 1L):(private$pos + 4L)]
      result <- readBin(
        bytes,
        what = "integer",
        n = 1L,
        size = 4L,
        endian = private$endian
      )
      private$pos <- private$pos + 4L
      result
    },

    #' @description Read a long
    #' @return Long integer value (as numeric)
    read_long = function() {
      private$ensure_read(8L)
      bytes <- private$bytes[(private$pos + 1L):(private$pos + 8L)]
      result <- readBin(
        bytes,
        what = "integer",
        n = 1L,
        size = 8L,
        endian = private$endian
      )
      private$pos <- private$pos + 8L
      result
    },

    #' @description Read a float
    #' @return Float value
    read_float = function() {
      private$ensure_read(4L)
      bytes <- private$bytes[(private$pos + 1L):(private$pos + 4L)]
      result <- readBin(
        bytes,
        what = "numeric",
        n = 1L,
        size = 4L,
        endian = private$endian
      )
      private$pos <- private$pos + 4L
      result
    },

    #' @description Read a double
    #' @return Double value
    read_double = function() {
      private$ensure_read(8L)
      bytes <- private$bytes[(private$pos + 1L):(private$pos + 8L)]
      result <- readBin(
        bytes,
        what = "numeric",
        n = 1L,
        size = 8L,
        endian = private$endian
      )
      private$pos <- private$pos + 8L
      result
    },

    #' @description Read a string
    #' @return String value
    read_string = function() {
      utf8_len <- self$read_int()
      if (utf8_len == 0) {
        return("")
      }
      private$ensure_read(utf8_len)
      utf8_bytes <- private$bytes[(private$pos + 1L):(private$pos + utf8_len)]
      private$pos <- private$pos + utf8_len
      rawToChar(utf8_bytes)
    },

    #' @description Read an object reference
    #' @param type Object class
    #' @return Object instance or NULL
    read_object = function(type) {
      id <- self$read_string()
      if (is.null(id) || id == "") {
        return(NULL)
      }
      type$new(private$orb_ref, id)
    }
  )
)

#' Message Header for ORB Protocol
#'
#' @export
MessageHeader <- R6::R6Class("MessageHeader",
  public = list(
    eye_catcher = 0L,
    protocol_major = 0L,
    protocol_minor = 0L,
    message_type = 0L,
    flags = 0L,
    message_length = 0L,
    
    #' @description Read header from buffer
    #' @param buff CDR buffer
    read = function(buff) {
      self$eye_catcher <- buff$read_int()
      self$protocol_major <- buff$read_byte()
      self$protocol_minor <- buff$read_byte()
      self$message_type <- buff$read_byte()
      self$flags <- buff$read_byte()
      self$message_length <- buff$read_int()
      invisible(self)
    },
    
    #' @description Write header to buffer
    #' @param buff CDR buffer
    write = function(buff) {
      buff$write_int(self$eye_catcher)
      buff$write_byte(self$protocol_major)
      buff$write_byte(self$protocol_minor)
      buff$write_byte(self$message_type)
      buff$write_byte(self$flags)
      buff$write_int(self$message_length)
      invisible(self)
    }
  )
)

# Message header constants
MessageHeader$SIZE <- 12L
MessageHeader$EYECATCHER <- 0x57524D49L
MessageHeader$CURRENT_PROTOCOL_MAJOR <- 2L
MessageHeader$CURRENT_PROTOCOL_MINOR <- 1L
MessageHeader$MSGTYPE_REQUEST <- 1L
MessageHeader$MSGTYPE_REPLY <- 2L
MessageHeader$MSGTYPE_ONEWAY <- 3L
MessageHeader$MSGTYPE_SHUTDOWN <- 4L
MessageHeader$MSGTYPE_VALIDATE <- 5L

#' Reply Header for ORB Protocol
#'
#' @export
ReplyHeader <- R6::R6Class("ReplyHeader",
  public = list(
    request_id = 0L,
    reply_status = 0L,
    
    #' @description Read reply header from buffer
    #' @param buff CDR buffer
    read = function(buff) {
      self$request_id <- buff$read_int()
      self$reply_status <- buff$read_byte()
      invisible(self)
    },
    
    #' @description Write reply header to buffer
    #' @param buff CDR buffer
    write = function(buff) {
      buff$write_int(self$request_id)
      buff$write_byte(self$reply_status)
      invisible(self)
    }
  )
)

ReplyHeader$SIZE <- 5L

#' Reply Status Constants
#'
#' @export
ReplyStatus <- list(
  NO_EXCEPTION = 0L,
  USER_EXCEPTION = 1L,
  SYSTEM_EXCEPTION = 2L
)

#' Request Header for ORB Protocol
#'
#' @export
RequestHeader <- R6::R6Class("RequestHeader",
  public = list(
    request_id = 0L,
    target_object = "",
    future = "",
    operation = "",
    flags = 0L,
    
    #' @description Read request header from buffer
    #' @param buff CDR buffer
    read = function(buff) {
      self$request_id <- buff$read_int()
      self$target_object <- buff$read_string()
      self$future <- buff$read_string()
      self$operation <- buff$read_string()
      self$flags <- buff$read_byte()
      invisible(self)
    },
    
    #' @description Write request header to buffer
    #' @param buff CDR buffer
    write = function(buff) {
      buff$write_int(self$request_id)
      buff$write_string(self$target_object)
      buff$write_string(self$future)
      buff$write_string(self$operation)
      buff$write_byte(self$flags)
      invisible(self)
    }
  )
)

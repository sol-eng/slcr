#' Buffer Pool for ORB
#'
#' @description Manages a pool of reusable CDR buffers
#' @keywords internal
BufferPool <- R6::R6Class(
  "BufferPool",
  private = list(
    orb_ref = NULL,
    buffer_size = 0L,
    pool = NULL,
    outstanding = 0L
  ),

  public = list(
    #' @description Create buffer pool
    #' @param orb ORB instance
    #' @param buffer_size Size of each buffer
    initialize = function(orb, buffer_size = 65536L) {
      private$orb_ref <- orb
      private$buffer_size <- buffer_size
      private$pool <- list()
      private$outstanding <- 0L
    },

    #' @description Acquire a buffer from the pool
    #' @return CDR buffer
    acquire_buf = function() {
      if (length(private$pool) > 0) {
        buf <- private$pool[[1]]
        private$pool[[1]] <- NULL
        private$pool <- Filter(Negate(is.null), private$pool)
      } else {
        buf <- CdrBuffer$new(private$orb_ref, private$buffer_size)
      }
      private$outstanding <- private$outstanding + 1L
      buf
    },

    #' @description Release a buffer back to the pool
    #' @param buf Buffer to release
    release_buf = function(buf) {
      private$outstanding <- private$outstanding - 1L
      private$pool <- c(private$pool, list(buf))
      invisible(self)
    },

    #' @description Get count of outstanding buffers
    #' @return Integer count
    outstanding_buffer_count = function() {
      private$outstanding
    }
  )
)

#' Object Request Broker (ORB)
#'
#' @description Main ORB class for managing communication with SLC
#' @export
Orb <- R6::R6Class(
  "Orb",
  private = list(
    conn = NULL,
    oa = NULL,
    buffer_pool = NULL,
    waiters = NULL,
    waiters_lock = NULL,
    receive_lock = NULL,
    next_request_id = 0L,
    receive_threads = NULL,
    shutdown_requested = FALSE,
    process_handle = NULL,

    # Send validation message
    send_validation_message = function() {
      hdr <- MessageHeader$new()
      hdr$eye_catcher <- MessageHeader$EYECATCHER
      hdr$protocol_major <- MessageHeader$CURRENT_PROTOCOL_MAJOR
      hdr$protocol_minor <- MessageHeader$CURRENT_PROTOCOL_MINOR
      hdr$message_type <- MessageHeader$MSGTYPE_VALIDATE
      hdr$flags <- 0L
      hdr$message_length <- 0L

      b <- self$acquire_buf()
      tryCatch(
        {
          b$clear()
          hdr$write(b)
          b$flip()
          self$send(b)
        },
        finally = {
          self$release_buf(b)
        }
      )
    },

    # Receive validation message
    # Receive validation message
    receive_validation_message = function() {
      requestbuf <- self$acquire_buf()
      tryCatch(
        {
          requestbuf$clear()
          requestbuf$set_limit(MessageHeader$SIZE)

          self$recv(requestbuf)

          requestbuf$flip()

          msghdr <- MessageHeader$new()
          msghdr$read(requestbuf)

          if (msghdr$eye_catcher != MessageHeader$EYECATCHER) {
            stop("Unexpected eyecatcher in message")
          }
          if (msghdr$protocol_major != MessageHeader$CURRENT_PROTOCOL_MAJOR) {
            stop("Incompatible major protocol number")
          }
        },
        finally = {
          self$release_buf(requestbuf)
        }
      )
    },

    # Receive message body
    receive_body = function(hdr, msgbuf) {
      msgbuf$clear()
      msgbuf$reserve(hdr$message_length)
      msgbuf$set_limit(hdr$message_length)
      self$recv(msgbuf)
      msgbuf$flip()
    },

    # Send shutdown message
    send_shutdown_message = function() {
      hdr <- MessageHeader$new()
      hdr$eye_catcher <- MessageHeader$EYECATCHER
      hdr$protocol_major <- MessageHeader$CURRENT_PROTOCOL_MAJOR
      hdr$protocol_minor <- MessageHeader$CURRENT_PROTOCOL_MINOR
      hdr$message_type <- MessageHeader$MSGTYPE_SHUTDOWN
      hdr$flags <- 0L
      hdr$message_length <- 0L

      b <- self$acquire_buf()
      tryCatch(
        {
          b$clear()
          hdr$write(b)
          b$flip()
          self$send(b)
        },
        finally = {
          self$release_buf(b)
        }
      )
    },

    # Process request message
    process_request = function(hdr) {
      requestbuf <- self$acquire_buf()
      tryCatch(
        {
          private$receive_body(hdr, requestbuf)

          requesthdr <- RequestHeader$new()
          requesthdr$read(requestbuf)

          replybuf <- self$acquire_buf()
          tryCatch(
            {
              replybuf$clear()
              replybuf$set_position(MessageHeader$SIZE + ReplyHeader$SIZE)

              replyhdr <- ReplyHeader$new()
              replyhdr$request_id <- requesthdr$request_id
              replyhdr$reply_status <- private$oa$dispatch(
                requesthdr$target_object,
                requesthdr$operation,
                requestbuf,
                replybuf
              )

              replybuf$flip()

              hdr$eye_catcher <- MessageHeader$EYECATCHER
              hdr$protocol_major <- MessageHeader$CURRENT_PROTOCOL_MAJOR
              hdr$protocol_minor <- MessageHeader$CURRENT_PROTOCOL_MINOR
              hdr$message_type <- MessageHeader$MSGTYPE_REPLY
              hdr$flags <- 0L
              hdr$message_length <- replybuf$limit() - MessageHeader$SIZE
              hdr$write(replybuf)

              replyhdr$write(replybuf)
              replybuf$set_position(0L)

              self$send(replybuf)
            },
            finally = {
              self$release_buf(replybuf)
            }
          )
        },
        finally = {
          self$release_buf(requestbuf)
        }
      )
    },

    # Process reply message
    process_reply = function(hdr) {
      replybuf <- self$acquire_buf()
      private$receive_body(hdr, replybuf)

      replyhdr <- ReplyHeader$new()
      replyhdr$read(replybuf)

      # Find waiter
      request_id_str <- as.character(replyhdr$request_id)
      waiter <- private$waiters[[request_id_str]]
      if (!is.null(waiter)) {
        # Modify the waiter in the environment directly
        waiter$buffer <- replybuf
        waiter$header <- replyhdr
        waiter$ready <- TRUE
        # Store it back in the environment
        private$waiters[[request_id_str]] <- waiter
      } else {
        # No waiter found, release buffer
        self$release_buf(replybuf)
      }
    },

    wait_for_and_perform_work = function() {
      if (private$shutdown_requested) {
        return(invisible(NULL))
      }

      # Check if process is still alive before trying to receive
      if (
        !is.null(private$process_handle) && !private$process_handle$is_alive()
      ) {
        stderr_output <- tryCatch(
          private$process_handle$read_error(),
          error = function(e) ""
        )
        stop(sprintf(
          "SLC process died while waiting for message. stderr: %s",
          stderr_output
        ))
      }

      requestbuf <- self$acquire_buf()
      tryCatch(
        {
          requestbuf$clear()
          requestbuf$set_limit(MessageHeader$SIZE)
          self$recv(requestbuf)
          requestbuf$flip()

          msghdr <- MessageHeader$new()
          msghdr$read(requestbuf)

          if (msghdr$eye_catcher != MessageHeader$EYECATCHER) {
            stop("Unexpected eyecatcher in message")
          }

          if (msghdr$message_type == MessageHeader$MSGTYPE_REQUEST) {
            private$process_request(msghdr)
          } else if (msghdr$message_type == MessageHeader$MSGTYPE_REPLY) {
            private$process_reply(msghdr)
          } else if (msghdr$message_type == MessageHeader$MSGTYPE_SHUTDOWN) {
            if (!private$shutdown_requested) {
              private$send_shutdown_message()
            }
            private$shutdown_requested <- TRUE
          }
        },
        finally = {
          self$release_buf(requestbuf)
        }
      )
    }
  ),

  public = list(
    #' @description Create ORB instance
    #' @param conn Connection object
    #' @param process_handle Optional process handle for liveness checking
    initialize = function(conn, process_handle = NULL) {
      private$conn <- conn
      private$oa <- ObjectAdapter$new(self)
      private$buffer_pool <- BufferPool$new(self, 65536L)
      private$waiters <- new.env(parent = emptyenv())
      private$next_request_id <- 0L
      private$shutdown_requested <- FALSE
      private$process_handle <- process_handle

      # Receive validation message
      private$receive_validation_message()
    },

    #' @description Get object adapter
    #' @return ObjectAdapter instance
    object_adapter = function() {
      private$oa
    },

    #' @description Convert string to object reference
    #' @param id Object ID string
    #' @return Object reference
    string_to_object = function(id) {
      OrbObject$new(self, id)
    },

    #' @description Shutdown the ORB
    shutdown = function() {
      if (!private$shutdown_requested) {
        private$shutdown_requested <- TRUE
        private$send_shutdown_message()
      }
      invisible(self)
    },

    #' @description Wait for reply to a request
    #' @param waiter Waiter object
    #' @param request_id Request ID
    #' @return List with buffer and header
    wait_for_reply = function(waiter, request_id) {
      # Convert to string once at the start
      request_id_str <- as.character(request_id)

      # Create waiter entry
      waiter_entry <- list(
        request_id = request_id,
        buffer = NULL,
        header = NULL,
        ready = FALSE
      )

      private$waiters[[request_id_str]] <- waiter_entry

      tryCatch(
        {
          # Poll for reply
          max_attempts <- 1000
          attempt <- 0
          while (attempt < max_attempts) {
            # Check the waiter in the environment, not the local copy
            current_waiter <- private$waiters[[request_id_str]]
            if (!is.null(current_waiter) && current_waiter$ready) {
              break
            }
            private$wait_for_and_perform_work()
            attempt <- attempt + 1
          }

          # Get final waiter state
          final_waiter <- private$waiters[[request_id_str]]
          if (is.null(final_waiter) || !final_waiter$ready) {
            stop("Timeout waiting for reply")
          }

          list(buffer = final_waiter$buffer, header = final_waiter$header)
        },
        finally = {
          # Remove the waiter from the environment
          # Use the pre-computed string to avoid any coercion issues
          tryCatch(
            {
              # Check if the key exists in the environment using the correct method
              if (!is.null(private$waiters[[request_id_str]])) {
                rm(list = request_id_str, envir = private$waiters)
              }
            },
            error = function(e) {
              # Silently ignore cleanup errors
              NULL
            }
          )
        }
      )
    },

    #' @description Acquire a buffer
    #' @return CDR buffer
    acquire_buf = function() {
      private$buffer_pool$acquire_buf()
    },

    #' @description Release a buffer
    #' @param buf Buffer to release
    release_buf = function(buf) {
      private$buffer_pool$release_buf(buf)
      invisible(self)
    },

    #' @description Send data
    #' @param buf Buffer to send
    send = function(buf) {
      private$conn$send(buf)
      invisible(self)
    },

    #' @description Receive data
    #' @param buf Buffer to receive into
    recv = function(buf) {
      private$conn$recv(buf)
      invisible(self)
    },

    #' @description Generate request ID
    #' @return Integer request ID
    generate_request_id = function() {
      id <- private$next_request_id
      private$next_request_id <- private$next_request_id + 1L
      id
    }
  )
)

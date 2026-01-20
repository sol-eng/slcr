#' ORB Object Reference
#'
#' @description Represents a reference to a remote object in the ORB
#' @export
OrbObject <- R6::R6Class("OrbObject",
  private = list(
    orb_ref = NULL,
    object_id = ""
  ),
  
  public = list(
    #' @description Create object reference
    #' @param orb The ORB instance
    #' @param id Object identity string
    initialize = function(orb, id) {
      private$orb_ref <- orb
      private$object_id <- id
    },
    
    #' @description Get the ORB
    #' @return ORB instance
    orb = function() {
      private$orb_ref
    },
    
    #' @description Get object identity
    #' @return Identity string
    identity = function() {
      private$object_id
    },
    
    #' @description Check if object is of given type
    #' @param type Type string
    #' @return Boolean
    is_a = function(type) {
      request_buf <- self$request("is_a")
      request_buf$write_string(type)
      reply_buf <- self$invoke(request_buf)
      tryCatch({
        reply_buf$read_boolean()
      }, finally = {
        self$release_buf(reply_buf)
      })
    },
    
    #' @description Create a request buffer
    #' @param operation Operation name
    #' @return CDR buffer
    request = function(operation) {
      msgbuf <- private$orb_ref$acquire_buf()
      msgbuf$clear()
      msgbuf$set_position(MessageHeader$SIZE)
      
      # Write request header manually for efficiency
      request_id <- private$orb_ref$generate_request_id()
      msgbuf$write_int(request_id)
      msgbuf$write_string(self$identity())
      msgbuf$write_string("")  # future
      msgbuf$write_string(operation)
      msgbuf$write_byte(0L)  # flags
      
      msgbuf
    },
    
    #' @description Invoke a oneway operation
    #' @param msgbuf Message buffer
    invoke_oneway = function(msgbuf) {
      tryCatch({
        msgbuf$flip()
        
        hdr <- MessageHeader$new()
        hdr$eye_catcher <- MessageHeader$EYECATCHER
        hdr$protocol_major <- MessageHeader$CURRENT_PROTOCOL_MAJOR
        hdr$protocol_minor <- MessageHeader$CURRENT_PROTOCOL_MINOR
        hdr$message_type <- MessageHeader$MSGTYPE_ONEWAY
        hdr$flags <- 0L
        hdr$message_length <- msgbuf$limit() - MessageHeader$SIZE
        
        hdr$write(msgbuf)
        msgbuf$set_position(0L)
        
        private$orb_ref$send(msgbuf)
      }, finally = {
        private$orb_ref$release_buf(msgbuf)
      })
      invisible(self)
    },
    
    #' @description Invoke an operation and wait for reply
    #' @param msgbuf Message buffer
    #' @return Reply buffer
    invoke = function(msgbuf) {
      tryCatch({
        msgbuf$flip()
        
        hdr <- MessageHeader$new()
        hdr$eye_catcher <- MessageHeader$EYECATCHER
        hdr$protocol_major <- MessageHeader$CURRENT_PROTOCOL_MAJOR
        hdr$protocol_minor <- MessageHeader$CURRENT_PROTOCOL_MINOR
        hdr$message_type <- MessageHeader$MSGTYPE_REQUEST
        hdr$flags <- 0L
        hdr$message_length <- msgbuf$limit() - MessageHeader$SIZE
        
        hdr$write(msgbuf)
        request_id <- msgbuf$read_int()
        msgbuf$set_position(0L)
        
        private$orb_ref$send(msgbuf)
        private$orb_ref$release_buf(msgbuf)
        msgbuf <- NULL
        
        result <- private$orb_ref$wait_for_reply(self, request_id)
        replybuf <- result$buffer
        replyhdr <- result$header
        
        if (replyhdr$reply_status == ReplyStatus$USER_EXCEPTION) {
          exception_type <- replybuf$read_string()
          # Try to read additional reason/details from the buffer
          reason <- if (replybuf$remaining() > 0) replybuf$read_string() else ""
          if (nchar(reason) > 0) {
            error_msg <- sprintf("%s: %s", exception_type, reason)
          } else {
            error_msg <- sprintf("Application exception: %s", exception_type)
          }
          private$orb_ref$release_buf(replybuf)
          stop(error_msg, call. = FALSE)
        } else if (replyhdr$reply_status == ReplyStatus$SYSTEM_EXCEPTION) {
          exception_type <- replybuf$read_string()
          msg <- if (replybuf$remaining() > 0) replybuf$read_string() else ""
          private$orb_ref$release_buf(replybuf)
          exc <- SystemException$new(sprintf("%s: %s", exception_type, msg))
          stop(exc$message, call. = FALSE)
        }
        
        replybuf
      }, error = function(e) {
        if (!is.null(msgbuf)) {
          private$orb_ref$release_buf(msgbuf)
        }
        stop(e)
      })
    },
    
    #' @description Release a buffer
    #' @param buff Buffer to release
    release_buf = function(buff) {
      private$orb_ref$release_buf(buff)
      invisible(self)
    }
  )
)

#' Object Adapter
#'
#' @description Manages servant objects in the ORB
#' @export
ObjectAdapter <- R6::R6Class("ObjectAdapter",
  private = list(
    orb_ref = NULL,
    active_servants = NULL
  ),
  
  public = list(
    #' @description Create object adapter
    #' @param orb The ORB instance
    initialize = function(orb) {
      private$orb_ref <- orb
      private$active_servants <- new.env(parent = emptyenv())
    },
    
    #' @description Add a servant with specific ID
    #' @param servant Servant object
    #' @param object_id Object ID
    #' @return Object reference
    add = function(servant, object_id) {
      if (exists(object_id, envir = private$active_servants)) {
        stop(AlreadyRegisteredException$new(object_id))
      }
      assign(object_id, servant, envir = private$active_servants)
      OrbObject$new(private$orb_ref, object_id)
    },
    
    #' @description Add a servant with UUID
    #' @param servant Servant object
    #' @return Object reference
    add_with_uuid = function(servant) {
      object_id <- uuid::UUIDgenerate()
      self$add(servant, object_id)
    },
    
    #' @description Remove a servant
    #' @param object_id Object ID or servant
    remove = function(object_id) {
      if (!exists(object_id, envir = private$active_servants)) {
        stop(ObjectNotExistException$new(object_id))
      }
      rm(list = object_id, envir = private$active_servants)
      invisible(self)
    },
    
    #' @description Get servant by ID
    #' @param object_id Object ID
    #' @return Servant object
    id_to_servant = function(object_id) {
      if (!exists(object_id, envir = private$active_servants)) {
        stop(ObjectNotExistException$new(object_id))
      }
      get(object_id, envir = private$active_servants)
    },
    
    #' @description Dispatch a method call
    #' @param object_id Target object ID
    #' @param operation Operation name
    #' @param msgbuf Message buffer
    #' @param replybuf Reply buffer
    #' @return Reply status
    dispatch = function(object_id, operation, msgbuf, replybuf) {
      tryCatch({
        servant <- self$id_to_servant(object_id)
        servant$dispatch(operation, msgbuf, replybuf)
      }, error = function(e) {
        if (inherits(e, "SystemException")) {
          replybuf$write_string(e$type_id())
          return(ReplyStatus$SYSTEM_EXCEPTION)
        }
        stop(e)
      })
    }
  )
)

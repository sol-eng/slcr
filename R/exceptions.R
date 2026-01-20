#' Base Exception Classes for ORB
#'
#' @export
OrbException <- R6::R6Class(
  "OrbException",
  public = list(
    message = "",

    initialize = function(message = "") {
      self$message <- message
    },

    print = function() {
      cat(sprintf("<%s>: %s\n", class(self)[1], self$message))
      invisible(self)
    }
  )
)

#' System Exception
#'
#' @export
SystemException <- R6::R6Class(
  "SystemException",
  inherit = OrbException,
  public = list(
    type_id = function() {
      "SystemException"
    }
  )
)

#' Application Exception
#'
#' @export
ApplicationException <- R6::R6Class(
  "ApplicationException",
  inherit = OrbException,
  public = list(
    exception_id = "",
    msgbuf = NULL,

    initialize = function(exception_id, msgbuf) {
      self$exception_id <- exception_id
      self$msgbuf <- msgbuf
      super$initialize(sprintf("Application exception: %s", exception_id))
    }
  )
)

#' Unknown Exception
#'
#' @export
UnknownException <- R6::R6Class(
  "UnknownException",
  inherit = SystemException,
  public = list(
    type_id = function() {
      "UnknownException"
    }
  )
)

#' Bad Operation Exception
#'
#' @export
BadOperationException <- R6::R6Class(
  "BadOperationException",
  inherit = SystemException,
  public = list(
    type_id = function() {
      "BadOperationException"
    }
  )
)

#' Already Registered Exception
#'
#' @export
AlreadyRegisteredException <- R6::R6Class(
  "AlreadyRegisteredException",
  inherit = SystemException,
  public = list(
    type_id = function() {
      "AlreadyRegisteredException"
    }
  )
)

#' Object Not Exist Exception
#'
#' @export
ObjectNotExistException <- R6::R6Class(
  "ObjectNotExistException",
  inherit = SystemException,
  public = list(
    type_id = function() {
      "ObjectNotExistException"
    }
  )
)

#' Servant Not Active Exception
#'
#' @export
ServantNotActiveException <- R6::R6Class(
  "ServantNotActiveException",
  inherit = SystemException,
  public = list(
    type_id = function() {
      "ServantNotActiveException"
    }
  )
)

#' User Exception
#'
#' @export
UserException <- R6::R6Class("UserException", inherit = OrbException)

#' SLC Error
#'
#' @export
SlcError <- R6::R6Class("SlcError", inherit = OrbException)

#' Internal Error
#'
#' @export
InternalError <- R6::R6Class("InternalError", inherit = SlcError)

#' User Error
#'
#' @export
UserError <- R6::R6Class("UserError", inherit = SlcError)

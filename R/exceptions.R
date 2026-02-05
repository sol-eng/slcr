#' Base Exception Classes for ORB
#'
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
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
#' @noRd
UserException <- R6::R6Class("UserException", inherit = OrbException)

#' SLC Error
#'
#' @noRd
SlcError <- R6::R6Class(
  "SlcError",
  inherit = OrbException,
  public = list(
    reason = NULL,

    initialize = function(reason = "An error has occurred.") {
      self$reason <- reason
      super$initialize(reason)
    }
  )
)

#' Internal Error
#'
#' @noRd
InternalError <- R6::R6Class(
  "InternalError",
  inherit = SlcError,
  public = list(
    initialize = function(reason = "An internal error has occurred.") {
      super$initialize(reason)
    }
  )
)

#' User Error
#'
#' @noRd
UserError <- R6::R6Class(
  "UserError",
  inherit = SlcError,
  public = list(
    initialize = function(reason = "An error has occurred.") {
      super$initialize(reason)
    }
  )
)

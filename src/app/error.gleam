import wisp.{type Response}

pub type AppError {
  AppDecodeError
  AppQueryError
  AppBuildModelError
}

pub fn error_to_response(error: AppError) -> Response {
  case error {
    AppDecodeError | AppBuildModelError -> wisp.unprocessable_entity()
    AppQueryError -> wisp.bad_request()
  }
}

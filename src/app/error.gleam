import wisp.{type Response}

pub type AppError {
  AppDecodeError
  AppQueryError
  AppBuildModelError
  AppNotFoundError
  AppNotUniqueError
}

pub fn error_to_response(error: AppError) -> Response {
  case error {
    AppDecodeError | AppBuildModelError -> wisp.unprocessable_entity()
    AppQueryError | AppNotUniqueError -> wisp.bad_request()
    AppNotFoundError -> wisp.not_found()
  }
}

pub fn process_result(
  result: Result(t, AppError),
  next: fn(t) -> Response,
) -> Response {
  case result {
    Ok(t) -> next(t)
    Error(err) -> error_to_response(err)
  }
}

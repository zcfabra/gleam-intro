import gleam/string_builder
import wisp.{type Response}

pub type AppError {
  AppDecodeError(message: String)
  AppQueryError(message: String)
  AppBuildModelError(message: String)
  AppNotFoundError(message: String)
  AppNotUniqueError(message: String)
}

pub fn error_to_response(error: AppError) -> Response {
  case error {
    AppDecodeError(msg) | AppBuildModelError(msg) -> with_msg(msg, 422)
    AppQueryError(msg) | AppNotUniqueError(msg) -> with_msg(msg, 400)
    AppNotFoundError(msg) -> with_msg(msg, 404)
  }
}

pub fn with_msg(message: String, code: Int) -> Response {
  wisp.json_response(string_builder.from_string(message), code)
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

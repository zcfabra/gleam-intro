import app/error.{type AppError}
import gleam/list
import gleam/regex
import gleam/pgo
import gleam/result

pub fn validate_row_singleton(returned: pgo.Returned(t)) -> Result(t, AppError) {
  case returned.count {
    0 -> Error(error.AppNotFoundError("Resource not found"))
    1 ->
      list.first(returned.rows)
      |> result.replace_error(error.AppNotFoundError("Resource not found"))
    _ -> Error(error.AppNotUniqueError("Could not find a unique resource"))
  }
}

pub fn validate_uuid(candidate: String) -> Result(String, AppError) {
  let assert Ok(re) =
    regex.from_string(
      "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    )
  case regex.check(re, candidate) {
    True -> Ok(candidate)
    False -> Error(error.AppDecodeError("Invalid Id"))
  }
}

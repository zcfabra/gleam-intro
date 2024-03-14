import app/error.{type AppError}
import gleam/list
import gleam/pgo
import gleam/result

pub fn validate_row_singleton(returned: pgo.Returned(t)) -> Result(t, AppError) {
  case returned.count {
    0 -> Error(error.AppNotFoundError)
    1 ->
      list.first(returned.rows)
      |> result.replace_error(error.AppNotFoundError)
    _ -> Error(error.AppNotUniqueError)
  }
}

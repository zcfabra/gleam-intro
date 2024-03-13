import wisp.{type Request, type Response}
import gleam/string_builder
import gleam/http.{Get, Post}
import app/web
import app/user

/// The HTTP request handler- your application!
/// 
pub fn handle_request(req: Request) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- web.middleware(req)

  // pattern match to assign handler functions to various routes -- COOL! 
  case wisp.path_segments(req) {
    // Matches '/'
    [] -> home_page(req)
    ["ping"] -> ping(req)
    ["create", "user"] -> create_user(req)
    _ -> wisp.not_found()
  }
}

fn create_user(req: Request) -> Response {
  use <- wisp.require_method(req, Get)
  use json <- wisp.require_json(req)
  let result = {
    use user_data <- try(user.decode(json))
    use inserted_row <- try(user.insert(ctx.db, user_data))
    Ok(user.row_to_json(inserted_row))
  }

  case result {
    Ok(user_json) -> wisp.json_response(user_json, 200)
    Error(_) -> wisp.unprocessable_entity()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)
  let response_msg = string_builder.from_string("Hi There")
  wisp.ok()
  |> wisp.html_body(response_msg)
}

fn ping(req: Request) -> Response {
  use <- wisp.require_method(req, Get)
  let response_msg = string_builder.from_string("PONG")
  wisp.ok()
  |> wisp.html_body(response_msg)
}

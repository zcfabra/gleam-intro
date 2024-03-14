import wisp.{type Request, type Response}
import gleam/string_builder
import gleam/http.{Get, Post}
import gleam/result.{try}
import gleam/pgo
import app/web
import app/user

type Context {
  Context(db: pgo.Connection)
}

/// The HTTP request handler- your application!
/// 
pub fn handle_request(req: Request) -> Response {
  // Apply the middleware stack for this request/response.
  use _req <- web.middleware(req)
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "my_database",
        pool_size: 15,
      ),
    )
  let ctx = Context(db: db)

  // pattern match to assign handler functions to various routes -- COOL! 
  case wisp.path_segments(req) {
    // Matches '/'
    [] -> home_page(req)
    ["ping"] -> ping(req)
    ["create", "user"] -> create_user(req)
    _ -> wisp.not_found()
  }
}

fn create_user(req: Request, ctx: Context) -> Response {
  let result = {
    use <- wisp.require_method(req, Get)
    use json <- wisp.require_json(req)
    use user_insert <- try(user.decode(json))
    use rec <- try(user.insert(user_insert, ctx.db))
    use user_model <- try(user.row_to_model(rec))
  }

  case result {
    Ok(user_json) -> wisp.json_response(user_json, 200)
    Error(err) -> error_to_response(err)
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

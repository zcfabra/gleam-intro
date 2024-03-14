import wisp.{type Request, type Response}
import gleam/string_builder
import gleam/http.{Get}
import gleam/option.{Some}
import gleam/result.{try}
import gleam/pgo
import gleam/io
import app/web
import app/user
import app/utils
import app/error

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
        password: Some("postgres"),
        database: "grill",
        pool_size: 15,
      ),
    )
  let ctx = Context(db: db)

  // pattern match to assign handler functions to various routes -- COOL! 
  case wisp.path_segments(req) {
    // Matches '/'
    [] -> home_page(req)
    ["ping"] -> ping(req)
    ["create", "user"] -> create_user(req, ctx)
    ["user", user_id] -> get_user(req, user_id, ctx)
    _ -> wisp.not_found()
  }
}

fn get_user(req: Request, user_id: String, ctx: Context) -> Response {
  io.debug(user_id)
  use <- wisp.require_method(req, Get)

  let result = {
    user.get_user(user_id, ctx.db)
    |> try(utils.validate_row_singleton)
    |> try(user.row_to_model)
  }
  io.debug(result)
  io.debug("C")
  case result {
    Ok(res) ->
      user.jsonify(res)
      |> string_builder.from_string
      |> wisp.json_response(200)
    Error(err) -> error.error_to_response(err)
  }
}

fn create_user(req: Request, ctx: Context) -> Response {
  use <- wisp.require_method(req, Get)
  use json <- wisp.require_json(req)

  let result =
    user.decode(json)
    |> try(user.insert(_, ctx.db))
    |> try(utils.validate_row_singleton)
    |> try(user.row_to_model)

  case result {
    Ok(_) -> wisp.ok()
    Error(err) -> error.error_to_response(err)
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

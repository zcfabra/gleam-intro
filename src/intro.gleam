import app/router
import gleam/erlang/process
import gleam/pgo
import mist
import wisp
import gleam/option.{Some}
import app/web

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

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
  let ctx = web.Context(db: db)
  let assert Ok(_) =
    wisp.mist_handler(router.handle_request(_, ctx), secret_key_base)
    |> mist.new()
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}

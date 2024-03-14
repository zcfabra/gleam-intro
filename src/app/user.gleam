import gleam/result
import gleam/pgo
import gleam/io
import gleam/json
import gleam/dynamic.{type Dynamic}
import app/error.{type AppError}

pub type CreateUser {
  CreateUser(name: String, email: String)
}

pub type UserModel {
  UserModel(name: String, email: String, user_id: String)
}

// [1]: https://hexdocs.pm/gleam_stdlib/gleam/dynamic.html
// fn decode_person(json: Dynamic) -> Result(Person, dynamic.DecodeErrors) {
//   let decoder =
//     dynamic.decode2(
//       Person,
//       dynamic.field("name", dynamic.string),
//       dynamic.field("is-cool", dynamic.bool),
//     )
//   decoder(json)
// }

pub fn decode(json: Dynamic) -> Result(CreateUser, AppError) {
  let decoder =
    dynamic.decode2(
      CreateUser,
      dynamic.field("name", dynamic.string),
      dynamic.field("email", dynamic.string),
    )
  decoder(json)
  |> result.replace_error(error.AppDecodeError)
}

pub fn insert(
  user: CreateUser,
  db,
) -> Result(pgo.Returned(#(String, String, String)), AppError) {
  let query =
    "
    INSERT INTO individual.user (name, email, user_id)
    VALUES ($1, $2, uuid_generate_v4())
    RETURNING name, email, user_id;
    "
  let return_type =
    dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string)

  pgo.execute(
    query,
    db,
    [pgo.text(user.name), pgo.text(user.email)],
    return_type,
  )
  |> result.replace_error(error.AppQueryError)
}

pub fn row_to_model(
  row: #(String, String, String),
) -> Result(UserModel, AppError) {
  io.debug(row)
  dynamic.from(row)
  |> dynamic.decode3(
    UserModel,
    dynamic.element(0, dynamic.string),
    dynamic.element(0, dynamic.string),
    dynamic.element(2, dynamic.string),
  )
  |> result.replace_error(error.AppBuildModelError)
  // |> result.replace_error(error.AppBuildModelError)
}

pub fn get_user(
  user_id: String,
  db,
) -> Result(pgo.Returned(#(String, String, String)), AppError) {
  let query =
    "
    SELECT user_id::TEXT, name, email 
    FROM individual.user_account
    WHERE name = $1;
    "
  let return_type =
    dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string)

  pgo.execute(query, db, [pgo.text(user_id)], return_type)
  |> result.replace_error(error.AppQueryError)
}

pub fn jsonify(user_model: UserModel) -> String {
  json.to_string(
    json.object([
      #("user_id", json.string(user_model.user_id)),
      #("name", json.string(user_model.name)),
      #("email", json.string(user_model.email)),
    ]),
  )
}

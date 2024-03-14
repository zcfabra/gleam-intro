import gleam/result
import gleam/pgo
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
  row: pgo.Returned(#(String, String, String)),
) -> Result(UserModel, AppError) {
  dynamic.from(row)
  |> dynamic.decode3(UserModel, dynamic.string, dynamic.string, dynamic.string)
  |> result.replace_error(error.AppBuildModelError)
}

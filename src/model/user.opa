//
// model/user.opa
//
//
// @author: Tim Coppieters
// @date: 01/2013


type user = { int id, string name }
type user_and_chan = { user user, client_room_channel chan }
type user_and_cursor_info = { user user, cursor_info cursor_info }

// info about the user its cursor, none if user is not editing a document
type cursor_info = option({string doc_name, pos cursor})

module User {

  function user_and_cursor_to_html(user, cursor_info) {
    <span class=user_name>{user.name} </span> <+>
    <br/> <+>
    cursor_info_to_html(cursor_info)
  }

  function cursor_info_to_html(cursor_info) {
    content = Option.switch(function({~doc_name, ~cursor}) {
        "{doc_name}  ({cursor.row}, {cursor.column})"
      }, "Not in a document", cursor_info)

    <span class=user_document_info>
       {content}
    </span>
  }

  function users_and_cursor_to_html(users) {
    List.map(function({~user, ~cursor_info}) {
      <li id={"user-" + Int.to_string(user.id)}>
        {user_and_cursor_to_html(user, cursor_info)}
      </li>
    }, users)
  }
  
}
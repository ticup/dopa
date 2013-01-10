import stdlib.system

database dopa {
  // a map of unique string names to string of text
  stringmap(string) /documents
}
// Sessions are how you manage 'variables' in OPA-style:
// http://blog.opalang.org/2011/09/sessions-handling-state-communication.html

// user
type user = { int id, string name }
type user_and_chan = { user user, client_room_channel chan }

// client_rooms_channel
type client_rooms_channel = channel(client_rooms_msg)
type client_rooms_msg = 
  { list(room_prot) rooms } or
  { room_client room, room_channel room_channel } or
  { string error }

// rooms
type rooms_channel = channel(rooms_msg)
type rooms_msg =
  { user listen, client_rooms_channel client_rooms_chan } or
  { user stoplisten } or
  { string create, string password } or
  { int get, string password, client_rooms_channel client_rooms_chan } or
  { user remove }
type room_prot = { int id, string name, bool password }
type room_client = { int id, string name, option(string) password }



// client_room_channel
type client_room_channel = channel(client_room_msg)
type client_room_msg = 
  { list(user) users } or
  { list(doc_client) documents } or
  { message message } or
  { document_channel doc_chan } or
  { string error }

// room
//type room = { int id, string name, option(string) password, intmap(user_and_chan) userMap }
type room_channel = channel(room_msg)
type room_msg =
  { user join, client_room_channel chan } or
  { message message } or
  { user leave } or
  { int createdocument, string name } or
  { int joindocument, user user, client_room_channel client_room_chan }

type userMap = intmap({~user, client_room_channel chan, option(int) doc_id})
type docMap = intmap({string name, document_channel chan})

// messages
type source = { system } or { user user }
type message = { source source, string text, Date.date date }



// document
type client_document_channel = channel(client_document_msg)
type client_document_msg =
  { string saved } or 
  { string text } or
  { string insert, pos pos } or
  { string remove, pos start, pos end } or
  { string removelines, pos start, pos end } or
  { list(string) insertlines, pos start }

type document_channel = channel(document_msg)
type document_msg =
  { user join, client_document_channel client_doc_chan } or
  { int leave } or
  { string insert, pos pos, client_document_channel client_doc_chan } or
  { string remove, pos start, pos end, client_document_channel client_doc_chan } or
  { string removelines, pos start, pos end, client_document_channel client_doc_chan } or
  { list(string) insertlines, pos start, client_document_channel client_doc_chan } or
  { string save, client_document_channel client_doc_chan } or
  { stop }

type pos = { int row, int column }
type document = { string name, string text }
type doc = { int id, string name, document_channel doc_chan }
type doc_client = { int id, string name }

module Model {

  // rooms
  recursive private rooms_channel rooms = Session.make({roomMap: IntMap.empty, listenerMap: IntMap.empty}, rooms_channel_handler)
  
  private function rooms_channel_handler({~roomMap, ~listenerMap}, rooms_msg) {
    
    function list(room_prot) map_to_sorted_list(roomMap) {
      roomMap
        |> IntMap.To.val_list(_)
        |> List.map(function({~id, ~name, ~password, ...}) { {~id, ~name, password: Option.is_some(password)} }, _)
        |> List.sort_by(function(r){ r.name }, _)
    }

    function notifyAll(roomMap, listenerMap) {
      
    
      function notify(chan) {
        Session.send(chan, {rooms: map_to_sorted_list(roomMap)})
      }
      List.iter(notify, IntMap.To.val_list(listenerMap))
    }


    match (rooms_msg) {
      case {listen: user, ~client_rooms_chan} :
        newListeners = IntMap.add(user.id, client_rooms_chan, listenerMap)
        Session.send(client_rooms_chan, {rooms: map_to_sorted_list(roomMap)})
        {set: {~roomMap, listenerMap: newListeners}}

      case {stoplisten: user} :
        newListeners = IntMap.remove(user.id, listenerMap)
        {set: {~roomMap, listenerMap: newListeners}}

      case {create: name, ~password} :
        // todo, check if id already exists
        id = Random.int(Limits.max_int)
        room_channel = create_room_channel(id, name)
        pwd = if (password == "") { {none} }
              else { {some: password} }
        room = {~id, ~name, password: pwd, ~room_channel}
        newRooms = IntMap.add(id, room, roomMap)
        notifyAll(newRooms, listenerMap)
        {set: {roomMap: newRooms, ~listenerMap}}

      case {get: id, ~password, ~client_rooms_chan} :
        room = IntMap.get(id, roomMap)
        match (room) {
          case {some: {~id, ~name, password: {some:pwd}, ~room_channel}} :
            if (password == pwd) {
              Session.send(client_rooms_chan, {room: {~id, ~name, password: {some: pwd}}, ~room_channel})
            } else {
              Session.send(client_rooms_chan, {error: "Incorrect password"})
            }
          case {some: {~id, ~name, password: {none}, ~room_channel}} :
            Session.send(client_rooms_chan, {room: {~id, ~name, password: {none}}, ~room_channel})
          case {none} :
            Session.send(client_rooms_chan, {error: Int.to_string(id) + " does not exist"})
        }
        {unchanged}

      case {remove: {~id, ...}} :
        newRooms = IntMap.remove(id, roomMap)
        notifyAll(newRooms, listenerMap)
        {set: {roomMap: newRooms, ~listenerMap}}
    }
  }

  function subscribe_for_rooms(user, client_rooms_chan) {
    Session.send(rooms, {listen: user, ~client_rooms_chan})
  }

  function unsubscribe_for_rooms(user) {
    Session.send(rooms, {stoplisten: user})
  }

  function create_room(name, password) {
    Session.send(rooms, {create: name, ~password})
  }

  function get_room_chan(id, password, client_rooms_chan) {
    Session.send(rooms, {get: id, ~password, ~client_rooms_chan})
  }



  function join_room(room_chan, user, client_room_chan) {
    Session.send(room_chan, {join: user, chan: client_room_chan})
  }

  function leave_room(room_chan, user) {
    Session.send(room_chan, {leave: user})
  }

  function send_message(room_channel, message) {
    Session.send(room_channel, message)
  }

  function create_document(room_channel, id, name) {
    Session.send(room_channel, {createdocument: id, ~name})
  }

  function get_doc_chan(room_channel, doc_id, user, client_room_chan) {
    Session.send(room_channel, {joindocument: doc_id, ~user, ~client_room_chan})
  }




  function subscribe_document(doc_chan, user, client_doc_chan) {
    Session.send(doc_chan, {join: user, ~client_doc_chan})
  }

  function unsubscribe_document(doc_chan, user_id) {
    Session.send(doc_chan, {leave: user_id})
  }

  // function send_content(doc_chan, text) {
  //   Session.send(doc_chan, {~text})
  // }

  function save_content(doc_chan, name, client_doc_chan) {
    Session.send(doc_chan, {save: name, ~client_doc_chan})
  }

  function insert_text(doc_chan, text, pos, client_doc_chan) {
    Session.send(doc_chan, {insert: text, ~pos, ~client_doc_chan})
  }

  function remove_text(doc_chan, text, start, end, client_doc_chan) {
    Session.send(doc_chan, {remove: text, ~start, ~end, ~client_doc_chan})
  }

  function remove_lines(doc_chan, start, end, client_doc_chan) {
    Session.send(doc_chan, {removelines: "", ~start, ~end, ~client_doc_chan})
  }

  function insert_lines(doc_chan, lines, start, client_doc_chan) {
    Session.send(doc_chan, {insertlines: lines, ~start, ~client_doc_chan})
  }

  

  // room
  private function create_room_channel(id, name) {
    Session.make({~id, ~name, userMap: IntMap.empty, docMap: IntMap.empty}, room_channel_handler)
  }

  // a room has an id, a name and 2 maps
  // - userMap: maps the id of the users to: {user, client_room_channel, doc_id}
  // - docMap: maps the id of the documents to: {name, document_channel}
  private function room_channel_handler({~id, ~name, ~userMap, ~docMap}, room_msg) {

    function notifyAll(message, userMap) {
      List.iter(function({~user, ~chan, ~doc_id}) {
        Session.send(chan, message)
      }, IntMap.To.val_list(userMap))
    }

    function broadCastUsers(userMap) {
      userList = userMap
        |> IntMap.To.val_list(_)
        |> List.map(function({~user, ~chan, ~doc_id}) { {id: user.id, name: user.name} }, _)
        |> List.sort_by(function(u){ u.name }, _)

      notifyAll({users: userList}, userMap)
    }

    function docmap_to_list(docMap) {
      docMap
        |> IntMap.To.assoc_list(_)
        |> List.map(function((id, {~name, ~doc_chan})) { {~id, ~name} }, _)
        |> List.sort_by(function(d){ d.name }, _)
    }

    function broadCastDocuments(docMap) {
      notifyAll({documents: docmap_to_list(docMap)}, userMap)
    }

    match (room_msg) {
      case {join: user, ~chan} :
        newUsers = IntMap.add(user.id, {~user, ~chan, doc_id: none}, userMap)
        message = {
          source: {system},
          text : "{user.name} joined the room",
          date : Date.now(),
        }
        broadCastUsers(newUsers)
        Session.send(chan, {documents: docmap_to_list(docMap)})
        notifyAll({~message}, newUsers)
        {set: {~id, ~name, userMap: newUsers, ~docMap}}

      case {leave: user} :
        {~user, ~chan, ~doc_id} = Option.get(IntMap.get(user.id, userMap))
        newUsers = IntMap.remove(user.id, userMap)
        if (IntMap.is_empty(newUsers)) {
          // remove this room from rooms
          Session.send(rooms, {remove: {~id, ~name}})
          // stop all document sessions of this room
          Map.iter(function(_, {~name, ~doc_chan}) {
            Session.send(doc_chan, {stop})
          }, docMap)
          // stop this room session
          {stop}
        } else {
          message = {
            source: {system},
            text : "{user.name} left the room",
            date : Date.now(),
          }
          notifyAll({~message}, newUsers)
          broadCastUsers(newUsers)

          // if listening to document, remove listener
          Option.map(function (id) {
            unsubscribe_document(Option.get(IntMap.get(id, docMap)).doc_chan, user.id)
            doc_id
          }, doc_id)

          {set: {~id, ~name, userMap: newUsers, ~docMap}}
        }

      case {~message} :
        notifyAll({~message}, userMap)
        {unchanged}

      case {createdocument: docId, ~name} :
        doc_chan = create_document_channel(docId, name)
        newDocs = IntMap.add(docId, {~name, ~doc_chan}, docMap)
        broadCastDocuments(newDocs)
        {set: {~id, ~name, docMap: newDocs, ~userMap}}

      case {joindocument: new_doc_id, ~user, ~client_room_chan} :
        // set the doc_id of the user to new doc_id
        newUsers = IntMap.replace(user.id, function ({~user, ~chan, ~doc_id}) {
          // remove listener from old document if exists
          Option.map(function (d_id) {
            unsubscribe_document(Option.get(IntMap.get(d_id, docMap)).doc_chan, user.id)
          }, doc_id)

          doc = IntMap.get(new_doc_id, docMap)
          match (doc) {
            case {some: {~name, ~doc_chan}} :
              Session.send(client_room_chan, {~doc_chan})
            case {none} :
              Session.send(chan, {error: Int.to_string(id) + " does not exist"})
          }
          // set new doc id
          {~user, ~chan, doc_id: {some: new_doc_id}}
        }, userMap)
        {set: {~id, ~name, userMap: newUsers, ~docMap}}
    }
  }


  


  // document
  private function create_document_channel(id, name) {
    Session.make({~id, ~name, lines: [["s", "t", "a", "r", "t"]], listeners: IntMap.empty}, document_channel_handler)
  }

  private function document_channel_handler({~id, ~name, ~lines, ~listeners}, message) {
    // notify all helper function, sends given message to all channels of a list
    function notifyAll(message, listeners, chan_sender) {
      IntMap.iter(function(id, chan) {
        if (chan != chan_sender)
          Session.send(chan, message)
      }, listeners)
    }
    
    function lines_to_string(lines) {
      String.of_list(function(lst){ List.to_string_using("", "", "", lst) }, "\n", lines)
    }

    match(message) {

      case {join: user, ~client_doc_chan} :
        newListeners = IntMap.add(user.id, client_doc_chan, listeners)
        Session.send(client_doc_chan, {text: lines_to_string(lines)})
        {set: {~id, ~name, ~lines, listeners: newListeners}}

      case {leave: id} :
        newListeners = IntMap.remove(id, listeners)
        {set: {~id, ~name, ~lines, listeners: newListeners}}

      case {save: name, ~client_doc_chan} :
        /dopa/documents[name] <- lines_to_string(lines)
        Session.send(client_doc_chan, {saved: name})
        {unchanged}

      case {insert: "\n", ~pos, ~client_doc_chan} :
        // get the involved row
        (line, otherlines) = List.extract(pos.row, lines)
        // split the row at the involved col
        (s, e) = List.split_at(Option.get(line), pos.column)
        // merge the rows back into the lines
        newlines = List.insert_at(s, pos.row, List.insert_at(e, pos.row, otherlines))
        // notify all clients to do the same
        notifyAll({insert: "\n", ~pos}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~listeners}}

      case {~insert, ~pos, ~client_doc_chan} :
        // convert given string to insert into list of string characters
        list(string) chars = String.explode("", insert)
        // get the involved row
        (line, otherlines) = List.extract(pos.row, lines)
        // split the row at the involved col
        (s, e) = List.split_at(Option.get(line), pos.column)
        // make a new row, merging the chars at the correct position
        newline = List.append(s, List.append(chars, e))
        // merge the row back into the lines
        newlines = List.insert_at(newline, pos.row, otherlines)
        // notify all clients to do the same
        notifyAll({~insert, ~pos}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~listeners}}

      case {~remove, ~start, ~end, ~client_doc_chan} :
        // get the start row
        (toplines, otherlines) = List.split_at(lines, start.row)
        // split the row until where it is retained
        (s, _) = List.split_at(List.head(otherlines), start.column)

        // get the end row
        (_, bottomlines) = List.split_at(lines, end.row)
        // split the row from where is retained
        (_, d) = List.split_at(List.head(bottomlines), end.column)
        // merge the retained parts
        mergeline = List.append(s, d)
        // merge the row back with the retained lines
        newlines = List.append(toplines, mergeline +> List.tail(bottomlines))
        // notify all clients to do the same
        notifyAll({~remove, ~start, ~end}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~listeners}}

      case {~removelines, ~start, ~end, ~client_doc_chan} :
        (s, _) = List.split_at(lines, start.row)
        (_, e) = List.split_at(lines, end.row)
        newlines = List.append(s, e)
        notifyAll({~removelines, ~start, ~end}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~listeners}}

      case {~insertlines, ~start, ~client_doc_chan} :
        (s, e) = List.split_at(lines, start.row)
        insert = List.map(function(str) { String.explode("", str) }, insertlines)
        newlines = List.append(s, List.append(insert, e))
        notifyAll({~insertlines, ~start}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~listeners}}

      case {stop} :
        Debug.jlog("stopping document")
        {stop}

      default :
        {unchanged}
    }
  }

   //case {connection:(user, _)} :
  //       message = {
  //         source: {system},
  //         text : "{user.name} joined the room",
  //         date : Date.now(),
  //       }
  //       message_update(message)
  //     case {disconnection:user} :
  //       message = {
  //         source: {system},
  //         text : "{user.name} left the room",
  //         date : Date.now(),
  //       }

  // Users
  // private users_channel users = Session.make(IntMap.empty, users_channel_handler)
  // private function users_channel_handler(userMap, message) {
  
  //     function notifyAll(userMap) {
  //       userList = userMap
  //         |> IntMap.To.val_list(_)
  //         |> List.map(function({~user ...}) { user }, _)
  //         |> List.sort_by(function(u){ u.name }, _)

  //       function notify({~user, ~chan}) {
  //         Session.send(chan, ~{users: userList})
  //       }

  //       List.iter(notify, IntMap.To.val_list(userMap))
  //     }

  //   match (message) {
  //     case {add: chan, ~user}:
  //       newUsers = IntMap.add(user.id, {~user, ~chan}, userMap)
  //       notifyAll(newUsers)
  //       {set: newUsers}

  //     case {remove: user}:
  //       newUsers = IntMap.remove(user.id, userMap)
  //       notifyAll(newUsers)
  //       {set: newUsers}

  //     default:
  //       {unchanged}
  //   }
  // }

  // function remove_user(user) {
  //   Session.send(users, {remove: user})
  // }

  // function subscribe_for_users(user, client_chan) {
  //   Session.send(users, {add: client_chan, user:user})
  // }

  // function user_list() {
  //   usrs = Session.get(users)
  //   IntMap.To.val_list(usrs)

  // }
}

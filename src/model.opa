import stdlib.system

database dopa {
  // // database declarations go here
  message /messages[{date}]
  user /users[{id}]
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
  { message message } 

// room
//type room = { int id, string name, option(string) password, intmap(user_and_chan) userMap }
type room_channel = channel(room_msg)
type room_msg =
  { user join, client_room_channel chan } or
  { message message } or
  { user leave } or
  { int createdocument, string name } or
  { int joindocument, user user, client_document_channel client_doc_chan }

type userMap = intmap({~user, client_room_channel chan, option(int) doc_id})
type docMap = intmap({string name, document_channel chan})

// messages
type source = { system } or { user user }
type message = { source source, string text, Date.date date }



// document
type client_document_channel = channel(client_document_msg)
type client_document_msg =
  { document_channel doc_chan } or
  { string error }

type document_channel = channel(document_msg)
type document_msg =
  { user join, client_document_channel client_doc_chan } or
  { int leave } or
  { stop }

type doc = { int id, string name, document_channel doc_chan }
type doc_client = { int id, string name }

module Model {


  function new_author() {
    Random.string(8)
  }

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

  function join_room(room_chan, user, client_chan) {
    Session.send(room_chan, {join: user, chan: client_chan})
  }

  function leave_room(room_chan, user) {
    Session.send(room_chan, {leave: user})
  }

  function send_message(room_channel, message) {
    Session.send(room_channel, message)
  }

  function get_document(room_channel, id, client_doc_channel) {
    Session.send(room_channel, {getdocument: id, ~client_doc_channel})
  }

  function create_document(room_channel, id, name) {
    Session.send(room_channel, {createdocument: id, ~name})
  }

  // function join_document(doc_chan, client_doc_channel) {
  //   Session.send(doc_chan, {join: client_doc_channel})
  // }

  function join_document(room_channel, doc_id, user, client_doc_chan) {
    Session.send(room_channel, {joindocument: doc_id, ~user, ~client_doc_chan})
  }


  private function subscribe_document(doc_chan, user, client_doc_chan) {
    Session.send(doc_chan, {join: user, ~client_doc_chan})
  }

  private function unsubscribe_document(doc_chan, user_id) {
    Session.send(doc_chan, {leave: user_id})
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

    function broadCastDocuments(docMap) {
      docList = docMap
        |> IntMap.To.assoc_list(_)
        |> List.map(function((id, {~name, ~doc_chan})) { {~id, ~name} }, _)
        |> List.sort_by(function(d){ d.name }, _)

      notifyAll({documents: docList}, userMap)
    }

    match (room_msg) {
      case {join: user, ~chan} :
        newUsers = IntMap.add(user.id, {~user, ~chan, doc_id: none}, userMap)
        broadCastUsers(newUsers)
        message = {
          source: {system},
          text : "{user.name} joined the room",
          date : Date.now(),
        }
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

      case {joindocument: id, ~user, ~client_doc_chan} :
        // set the doc_id of the user to new doc_id
        IntMap.replace(user.id, function ({~user, ~chan, ~doc_id}) {
          // remove listener from old document if exists
          Option.map(function (d_id) {
            unsubscribe_document(Option.get(IntMap.get(d_id, docMap)).doc_chan, user.id)
          }, doc_id)
          // set new doc id
          {~user, ~chan, doc_id: {some: id}}
        }, userMap)

        doc = IntMap.get(id, docMap)
        match (doc) {
          case {some: {~name, ~doc_chan}} :
            subscribe_document(doc_chan, user, client_doc_chan)
            Session.send(client_doc_chan, {~doc_chan})
          case {none} :
            Session.send(client_doc_chan, {error: Int.to_string(id) + " does not exist"})
        }
        {unchanged}
    }
  }


  // document
  private function create_document_channel(id, name) {
    Session.make({~id, ~name, listeners: IntMap.empty}, document_channel_handler)
  }

  private function document_channel_handler({~id, ~name, ~listeners}, message) {
    match(message) {

      case {join: user, ~client_doc_chan} :
        newListeners = IntMap.add(user.id, client_doc_chan, listeners)
        {set: {~id, ~name, listeners: newListeners}}

      case {leave: id} :
        newListeners = IntMap.remove(id, listeners)
        {set: {~id, ~name, listeners: newListeners}}

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
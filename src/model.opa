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
type client_rooms_msg = { list(room_prot) rooms }

// client_room_channel
type client_room_channel = channel(client_room_msg)
type client_room_msg = 
  { list(user) users } or
  { room_client room, room_channel room_channel } or
  { message message } or
  { string error }

// rooms
type rooms_channel = channel(rooms_msg)
type rooms_msg =
  { user listen, client_rooms_channel client_rooms_chan } or
  { user stoplisten } or
  { int create, string name, string password } or
  { int get, string password, client_room_channel client_room_chan } or
  { user remove }
type room_prot = { int id, string name, bool password }
type room_client = { int id, string name, option(string) password }


// room
//type room = { int id, string name, option(string) password, intmap(user_and_chan) userMap }
type room_channel = channel(room_msg)
type room_msg =
  { user join, client_room_channel chan } or
  { message message } or
  { user leave }


// messages
type source = { system } or { user user }
type message = { source source, string text, Date.date date }



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

      case {create: id, ~name, ~password} :
        room_channel = Session.make({~id, ~name, userMap: IntMap.empty}, room_channel_handler)
        pwd = if (password == "") { {none} }
              else { {some: password} }
        room = {~id, ~name, password: pwd, ~room_channel}
        newRooms = IntMap.add(id, room, roomMap)
        notifyAll(newRooms, listenerMap)
        {set: {roomMap: newRooms, ~listenerMap}}

      case {get: id, ~password, ~client_room_chan} :
        room = IntMap.get(id, roomMap)
        match (room) {
          case {some: {~id, ~name, password: {some:pwd}, ~room_channel}} :
            if (password == pwd) {
              Session.send(client_room_chan, {room: {~id, ~name, password: {some: pwd}}, ~room_channel})
            } else {
              Session.send(client_room_chan, {error: "Incorrect password"})
            }
          case {some: {~id, ~name, password: {none}, ~room_channel}} :
            Session.send(client_room_chan, {room: {~id, ~name, password: {none}}, ~room_channel})
          case {none} :
            Session.send(client_room_chan, {error: Int.to_string(id) + " does not exist"})
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

  function create_room({~id, ~name, ~password}) {
    Session.send(rooms, {create: id, ~name, ~password})
  }

  function get_room_chan(id, password, client_room_chan) {
    Session.send(rooms, {get: id, ~password, ~client_room_chan})
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
  // room
  private function room_channel_handler({~id, ~name, ~userMap}, room_msg) {

    function notifyAll(message, userMap) {
      List.iter(function({~user, ~chan}) {
        Session.send(chan, message)
      }, IntMap.To.val_list(userMap))
    }

    function broadCastUsers(userMap) {
      userList = userMap
        |> IntMap.To.val_list(_)
        |> List.map(function({~user, ...}) { {id: user.id, name: user.name} }, _)
        |> List.sort_by(function(u){ u.name }, _)

      notifyAll({users: userList}, userMap)
    }

    match (room_msg) {
      case {join: user, ~chan} :
        newUsers = IntMap.add(user.id, {~user, ~chan}, userMap)
        broadCastUsers(newUsers)
        message = {
          source: {system},
          text : "{user.name} joined the room",
          date : Date.now(),
        }
        notifyAll({~message}, newUsers)
        {set: {~id, ~name, userMap: newUsers}}

      case {leave: user} :
        newUsers = IntMap.remove(user.id, userMap)
        broadCastUsers(newUsers)
        message = {
          source: {system},
          text : "{user.name} left the room",
          date : Date.now(),
        }
        notifyAll({~message}, newUsers)
        if (IntMap.is_empty(newUsers)) {
          Session.send(rooms, {remove: {~id, ~name}})
          {stop}
        } else {
          {set: {~id, ~name, userMap: newUsers}}
        }

      case {~message} :
        notifyAll({~message}, userMap)
        {unchanged}

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

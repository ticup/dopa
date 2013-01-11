import stdlib.system
//
// model/rooms.opa
// rooms, room and document are three models that each represent a network of Sessions.
// Each model has a server Session and such server session manages multiple client Sessions (listeners) for that session.
// By doing so, the server Session can send its updated state to the clients in real-time.
// Networks are not so useful here because it happens that we need to broadcast an update to all clients, except one.
//
// @author: Tim Coppieters
// @date: 01/2013


// Sessions are how you manage 'variables' in OPA-style:
// http://blog.opalang.org/2011/09/sessions-handling-state-communication.html

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



module Rooms {

  // ROOMS API //
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

  // ROOMS HELPERS //
  // transforms the roomMap into a list of room_prot records, which can be used to send to the client
  function list(room_prot) map_to_sorted_list(roomMap) {
    roomMap
      |> IntMap.To.val_list(_)
      |> List.map(function({~id, ~name, ~password, ...}) { {~id, ~name, password: Option.is_some(password)} }, _)
      |> List.sort_by(function(r){ r.name }, _)
  }

  // broadcast the rooms list to all listeners
  function notifyAll(roomMap, listenerMap) {
    function notify(chan) {
      Session.send(chan, {rooms: map_to_sorted_list(roomMap)})
    }
    List.iter(notify, IntMap.To.val_list(listenerMap))
  }

  // ROOMS CHANNEL
  //
  // a rooms_channel has following state:
  // - roomMap: a map of room id's to the room:
  //      - int id
  //      - string name
  //      - string password
  //      - room_channel room_channel
  // - listenerMap: a map of user id's to the user's client_rooms_channel

  recursive private rooms_channel rooms = Session.make({roomMap: IntMap.empty, listenerMap: IntMap.empty}, rooms_channel_handler)
  
  private function rooms_channel_handler({~roomMap, ~listenerMap}, rooms_msg) {
    match (rooms_msg) {
      // a new user joins the rooms channel:
      //  - add him as listener
      //  - send a list of all rooms to the client_room_channel
      case {listen: user, ~client_rooms_chan} :
        newListeners = IntMap.add(user.id, client_rooms_chan, listenerMap)
        Session.send(client_rooms_chan, {rooms: map_to_sorted_list(roomMap)})
        {set: {~roomMap, listenerMap: newListeners}}

      // the user leaves the rooms channel:
      //  - remove him as a listener
      case {stoplisten: user} :
        newListeners = IntMap.remove(user.id, listenerMap)
        {set: {~roomMap, listenerMap: newListeners}}

      // create a new room:
      //  - create a room_channel and room record
      //  - add it to the roomMap
      //  - broadcast new rooms list to all listeners
      case {create: name, ~password} :
        id = Util.createId(roomMap)
        room_channel = Room.create_room_channel(id, name, rooms)
        pwd = if (password == "") { {none} }
              else { {some: password} }
        room = {~id, ~name, password: pwd, ~room_channel}
        newRooms = IntMap.add(id, room, roomMap)
        notifyAll(newRooms, listenerMap)
        {set: {roomMap: newRooms, ~listenerMap}}

      // send the room_channel that belongs to the room with given id
      // to the client_rooms_channel if the password is correct,
      // oterwise send an error.
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

      // - remove the room with given id from docMap
      // - broadcast new rooms list to all listeners
      case {remove: {~id, ...}} :
        newRooms = IntMap.remove(id, roomMap)
        notifyAll(newRooms, listenerMap)
        {set: {roomMap: newRooms, ~listenerMap}}
    }
  }
}

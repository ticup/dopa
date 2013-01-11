//
// view/rooms.opa
//
//
// @author: Tim Coppieters
// @date: 01/2013



import ace
import jquery-ui

module ViewRooms {
  
  function enter_rooms(user) {

    function join_room(client_chan, room, _) {
      password = if (room.password) {
        Client.prompt("Please enter password for {room.name}", "")
      } else { {some: ""} }
      
      Option.map(function(pwd) {
        // will send the room_channel to our session if succesfully logged in.
        Rooms.get_room_chan(room.id, pwd, client_chan)
      }, password)
      void
    }

    // handler for rooms (syncs the room list in realtime)
    recursive client_rooms_channel client_chan = Session.make_callback(rooms_handler)

    and function rooms_handler(message) {
      match (message) {
        case {~rooms} :
          rooms_html =
            List.map(function(room) {
              <div class=line>
                <a onclick={join_room(client_chan, room, _)}>
                  {room.name}
                </a>
              </div>
            }, rooms)
          #room_list = <div class=stats><div>Rooms: {List.length(rooms_html)}</div></div> <+>
                        <div class=list>{rooms_html}</div>

        case {room: room, ~room_channel} :
          // No longer interested in updates from rooms session
          Rooms.unsubscribe_for_rooms(user)
          ViewRoom.enter_room(user, room, room_channel)

        case {~error} :
          Client.alert(error)
      }
    }
    
    function init_rooms(_) {
      // assign with model to get updates for the rooms list
      Rooms.subscribe_for_rooms(user, client_chan)

      // unsubscribe for rooms session when we join a room
      // (no longer interested in rooms updates)
      Dom.bind_beforeunload_confirmation(function(_) {
        Rooms.unsubscribe_for_rooms(user)
        none
      })
    }

    function create_room(_) {
      name = Dom.get_value(#new_room_name_entry)
      ViewUtil.requires_value(function(name) {
        password = Dom.get_value(#new_room_pwd_entry)
        Rooms.create_room(name, password)
      }, name, "Please enter a name for your room")
    }

    #main =
      <div id=#content
           onready={init_rooms(_)} >
          <h4>Click a room to join or create a new one</h4>
          <div id=#room_list/>
          <div id=#create_room_bar>
            <input id=#new_room_name_entry
                   type="text"
                   placeholder="Room Name"
                   autofocus="autofocus"
                   onnewline={create_room(_)} />
            <input id=#new_room_pwd_entry
                   type="password"
                   placeholder="Room Password"
                   onnewline={create_room(_)} />
            <button class="btn primary"
                    onclick={create_room(_)}>Create</button>
          </div>
        </div>

  }
}
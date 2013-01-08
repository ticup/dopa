import stdlib.web.client

module View {

   // View code goes here

  function build_page(content) {
    <div class="navbar navbar-fixed-top">
      <div class=navbar-inner>
        <div id=#navbar class=container>
          <a class=brand href="">dopa</>
           <button class="btn primary"
                   onclick={function(_) {Dom.toggle(#chat)}} >
            Chat 
           </button>
        </div>
      </div>
    </div>
    <div id=#main class=container-fluid>
      {content}
    </div>
  }


  // function chat_html(author) {
  //   <div id=#conversation class=container-fluid
  //     onready={function(_) { Model.register_message_callback(user_update)}}/>

  //   <div id=#footer class="navbar navbar-fixed-bottom">
  //     <div class=container>
  //       <div class=input-append>
  //         <input id=#entry class=input-xxlarge type=text
  //           onnewline={function(_) { broadcast(author) }}>
  //         <button class="btn btn-primary" type=button
  //           onclick={function(_) { broadcast(author) }}>Post</>
  //       </div>
  //     </div>
  //   </div>
  // }

  // function observe_network_client(msg) {
  //   match (msg) {
  //     case {~message} :
  //       message_update(message)
  //     case {connection:(user, _)} :
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
  //       message_update(message)
  //     default : void
  //   }
  // }

  // Init the client from the server
  // function init_client(user) {
  //   chan = Session.make_callback(show_user)
  //   Model.subscribe_for_rooms(user, chan)
  //   // Model.broadcast({connection:(user, client_channel)})
  //   // obs = Model.make_observer(observe_network_client)


  //   // Observe disconnection
  //   // note this does not suffice, should use channel to.
  //   Dom.bind_beforeunload_confirmation(function(_) {
  //     // Model.broadcast({disconnection:user})
  //     Model.remove_user(user)
  //     //Model.remove_observer(obs)
  //     none
  //   })
  // }

  function source_to_html(source) {
    match(source) {
      case {system} :
        <span class="system" />
      case {~user} :
        <span class="user">{user.name}</span>
    }
  }

  function message_update(message msg) {
    date = Date.to_formatted_string(Date.default_printer, msg.date)
    time = Date.to_string_time_only(msg.date)
    line = <div class="line">
              <span class="date" title="{date}">{time}</span>
              {source_to_html(msg.source)}
              <div class="message">{msg.text}</>
            </div>
    #conversation =+ line
    Dom.scroll_to_bottom(#conversation)
  }

  function show_users(users) {
    users_html =
      List.map(function(user) {
        <li>{user.name}</li>
      }, users)
    #users = <>Users: {List.length(users_html)}</>
    #user_list = <ul>{users_html}</ul>
    void
  }


  function enter_room(user, room) {

    // will be called when the server sends us his room_channel
    function show_room(id, name, room_channel, client_channel) {



      function send_message() {
        text = Dom.get_value(#entry);
        message = {source:{~user}, ~text, date:Date.now()}
        Model.send_message(room_channel, {~message})
        // /dopa/messages[date==message.date] <- message
        // Model.broadcast({~message});
        Dom.clear_value(#entry);
      }

      function init_room(_) {
        // join the room channel
        Model.join_room(room_channel, user, client_channel)

        // leave before quiting
        Dom.bind_beforeunload_confirmation(function(_) {
          Model.leave_room(room_channel, user)
          none
        })
      }

      #main =
      <div id=#chat
           onready={init_room(_)}>
        <div id=#sidebar>
          <h4>Users online</h4>
          <div id=#user_list/>
          </div>
          <div id=#content
               onready={function(_){}}>
          <div id=#stats><div id=#users/><div id=#uptime/><div id=#memory/></div>
          <div id=#conversation/>
          <div id=#chatbar>
            <input id=#entry
                   autofocus="autofocus"
                   onready={function(_){Dom.give_focus(#entry)}}
                   onnewline={function(_){send_message()}}
                   x-webkit-speech="x-webkit-speech"/>
          </div>
        </div>
      </div>
    }

    // make client session for room channel and request room channel
    recursive client_room_channel client_channel = Session.make_callback(handle_room)

    // handle incoming messages for client_room_channel
    and function handle_room(client_room_msg message) {
      match(message) {
        case {room: {~id, ~name, ~password}, ~room_channel} :
          show_room(id, name, room_channel, client_channel)

        case {~users} :
          show_users(users) 

        case {~message} :
          message_update(message)

        case {~error} :
          Client.alert("Incorrect password, please try again")
      }
    }

    Model.get_room_chan(room.id, room.password, client_channel)
  }


  function enter_rooms(user) {

    function join_room(room, _) {
      password = Dom.get_value(#join_room_password_entry)
      enter_room(user, {id: room.id, name: room.name, password: password})
    }

    function show_rooms({~rooms}) {
      rooms_html =
        List.map(function(room) {
          <li>
            <a id=#{"room-" + Int.to_string(room.id)}
               onclick={join_room(room, _)}>
              {room.name}
            </a>
          </li>
        }, rooms)
      #room_list = <>Rooms: {List.length(rooms_html)}</> <+>
                    <div class=line>{rooms_html}</div>
    }
    
    function init_rooms(_) {
      client_rooms_channel chan = Session.make_callback(show_rooms)
      Model.subscribe_for_rooms(user, chan)

      Dom.bind_beforeunload_confirmation(function(_) {
        Model.unsubscribe_for_rooms(user)
        none
      })
    }

    function create_room(_) {
      name = Dom.get_value(#new_room_name_entry)
      password = Dom.get_value(#new_room_pwd_entry)
      // todo, check if id already exists
      id = Random.int(Limits.max_int)

      room = {~id, ~name, ~password}
      
      Model.create_room(room)

      Model.unsubscribe_for_rooms(user)

      enter_room(user, room)
    }

    #main =
      <div id=#content
           onready={init_rooms(_)} >
          <h4>Rooms</h4>
          <div id=#room_list/>
          <div id=#join_room_bar>
            <input id=#join_room_password_entry
                   type="password"
                   placeholder="Enter Room Password and click Room"
                   autofocus="autofocus"
                   onready={function(_){Dom.give_focus(#join_room_password_entry)}} />
          </div>
          <div id=#create_room_bar>
            <input id=#new_room_name_entry
                   type="text"
                   placeholder="New Room Name"
                   autofocus="autofocus" />
            <input id=#new_room_pwd_entry
                   type="password"
                   placeholder="New Room Password"
                   onnewline={create_room(_)} />
            <button class="btn primary"
                    onclick={create_room(_)}>Create</button>
          </div>
        </div>

  }

  // login
  function login(_) {
    name = Dom.get_value(#name)
    user = {
      id: Random.int(Limits.max_int),
      name: name
    }
    enter_rooms(user)
  }

  // Start page
  function start() {
    html = build_page(
      <h4>A collaborative programming editor built in Opa.</h4>
      <div id=#login class="form-inline">
        <input id=#name
               type="text"
               placeholder="Name"
               autofocus="autofocus"
               onready={function(_){Dom.give_focus(#name)}}
               onnewline={login}/>
        <button class="btn primary"
                onclick={login}>Join</button>
      </div>
    )
    Resource.page("Dopa - Collaboratively writing code", html)
  }

}

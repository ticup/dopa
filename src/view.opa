import stdlib.web.client
import stdlib.widgets.textarea
import stdlib.widgets.core
import ace

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
           <div id=#create_document_container/>
           <div id=#document_tabs/>
        </div>
      </div>
    </div>
    <div id=#main>
      {content}
    </div>
    <div id=#document/>
    <div id=#chat/>
    
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

  function show_document(user, room, room_chan, doc_chan) {

    // create editor
    #document = <div id=#editor/>
    inst = Editor.edit("editor")

    function insert_text(text, pos) {
      Editor.insert_value(inst, pos, text)
      void
    }

    function remove_text(text, start, end) {
      Editor.remove_value(inst, start, end)
      void
    }

    function set_text(text) {
      Editor.set_value(inst, text)
      void
    }

    function remove_lines(start, end) {
      Editor.remove_lines(inst, start, end)
      void
    }

    // function send_content(_) {
    //   text = Dom.get_value(#document_content)
    //   Model.send_content(doc_chan, text)
    // }

    function save_document(client_doc_chan, _) {
      name = Dom.get_value(#save_document_name_entry)
      Model.save_content(doc_chan, name, client_doc_chan)
    }

    function document_handler(message) {
      match (message) {

        case {~text} :
          set_text(text)

        case {saved: name} :
          Client.alert("The document was saved under: " + name)
          void

        case {~insert, ~pos} :
          Debug.jlog(insert + " into " + Debug.dump(pos))
          Editor.insert_value(inst, pos, insert)
          void

        case {~remove, ~start, ~end} :
          Debug.jlog(remove + Debug.dump(start) + " until " + Debug.dump(end))
          Editor.remove_value(inst, start, end)
          void

        case {~removelines, ~start, ~end} :
          Debug.jlog(removelines + Debug.dump(start) + " until " + Debug.dump(end))
          Editor.remove_lines(inst, start, {row: end.row - 1, column: end.column})
          void

        case {~insertlines, ~start} :
          Editor.insert_lines(inst, start, insertlines)
          void
      }
    }

    client_document_channel client_doc_chan = Session.make_callback(document_handler)
    // start listening to the doc_chan
    Model.subscribe_document(doc_chan, user, client_doc_chan)

    // WTextarea.config config =  { WTextarea.verbose_config with
    //   disabled_editor_style: WStyler.make_style(css {
    //       width: 500px; height: 500px;
    //       border: thin solid gray; overflow: auto; cursor: text;
    //       padding: 2px;
    //     }),

    //   enabled_editor_style: WStyler.make_style(css {
    //       width: 500px; height: 500px;
    //       border: thin solid #18D; overflow: auto; cursor: text;
    //       padding: 2px;
    //     }),

    //   on_text: function (str, pos, cont) {
    //     Debug.jlog("FOOOOOO")
    //     Debug.jlog(str)
    //     Debug.jlog(Debug.dump(pos))
    //     cont()
    //   },
    // }

    // textarea = WTextarea.edit(config, "document", "Let's start programming!")
    //#main = WCore.make([], [], "document_wrapper", textarea)
    #document =+ <div id=#save_document>
                  <input id=#save_document_name_entry
                         type="text"
                         placeholder="Enter Name" />
                  <button class="btn primary"
                          onclick={save_document(client_doc_chan,_)} >
                    Save
                  </button>
                </div>
    // Editor.set_theme(inst, "ace/theme/monokai")
    Editor.set_mode(inst, "ace/mode/javascript")
    Editor.on_change_cursor(inst, function(pos) {
      // cursor updates are sent to the room channel
      Model.change_cursor(room_chan, user, pos)
    })

    Editor.on_change(inst, function(e) {
      // document updates are sent to the document channel
      match(e) {
        case {action: "insertText", ~text, ~start, ~end} :
          Model.insert_text(doc_chan, text, start, client_doc_chan)

        case {action: "removeText", ~text, ~start, ~end} :
          Model.remove_text(doc_chan, text, start, end, client_doc_chan)


        case {action: "removeLines", ~text, ~start, ~end} :
          Model.remove_lines(doc_chan, start, end, client_doc_chan)


        case {action: "insertLines", ~lines, ~start, ~end} :
          Model.insert_lines(doc_chan, lines, start, client_doc_chan)

        default :
          void
      }
      Debug.jlog(Debug.dump(e))})
    void
  }

  function enter_room(user, room, room_channel) {

    function show_document_tabs(client_room_chan, documents) {

      function enter_document(document, _) {
        // will send the room chan to handler
        Model.get_doc_chan(room_channel, document.id, user, client_room_chan)
        void
      }

      #document_tabs = List.map(function(doc) {
          <button class="btn primary"
                  onclick={enter_document(doc,_)}>{doc.name}</button>
        }, documents)
      void
    }

    function send_message(_) {
      text = Dom.get_value(#entry);
      message = {source:{~user}, ~text, date:Date.now()}
      Model.send_message(room_channel, {~message})
      // /dopa/messages[date==message.date] <- message
      // Model.broadcast({~message});
      Dom.clear_value(#entry);
    }

    function create_document(_) {
      id = Random.int(Limits.max_int)
      name = Dom.get_value(#create_document_name_entry)
      Model.create_document(room_channel, id, name)
    }

    // make client session for room channel and request room channel
    recursive client_room_channel client_channel = Session.make_callback(handle_room)

    // handle incoming messages for client_room_channel
    and function handle_room(client_room_msg message) {
      match(message) {

        case {~users} :
          show_users(users)

        case {~documents} :
          show_document_tabs(client_channel, documents)

        case {~message} :
          message_update(message)

        case {~doc_chan} :
         show_document(user, room, room_channel, doc_chan)

        case {~error} :
          Client.alert(error)
          void
 
      }
    }

    function init_room(_) {

      // subscribe for the room_channel
      Model.join_room(room_channel, user, client_channel)

      // leave before quiting, this also unsubscribes for possible document sessions!
      Dom.bind_beforeunload_confirmation(function(_) {
        Model.leave_room(room_channel, user)
        none
      })

      #create_document_container =
        <input id=#create_document_name_entry
               type="text"
               placeholder="New Document Name"
               onnewline={create_document(_)}/>
        <button class="btn primary"
                onclick={create_document(_)} >
          New Document
        </button>

    }
    Dom.transform([
      #main = <div id=#document_container />,
      #chat =
        <div id=#sidebar
             onready={init_room(_)} >
          <h4>Users online</h4>
          <div id=#user_list/>
          </div>
          <div id=#chat_content
               onready={function(_){}}>
          <div id=#stats><div id=#users/><div id=#uptime/><div id=#memory/></div>
          <div id=#conversation/>
          <div id=#chatbar>
            <input id=#entry
                   autofocus="autofocus"
                   onready={function(_){Dom.give_focus(#entry)}}
                   onnewline={send_message(_)}
                   x-webkit-speech="x-webkit-speech"/>
          </div>
        </div>
    ])
    Dom.show(#chat)
  }


  function enter_rooms(user) {

    function join_room(client_chan, room, _) {
      password = Dom.get_value(#join_room_password_entry)
      // will send the room_channel to our session if succesfully logged in.
      Model.get_room_chan(room.id, password, client_chan)

    }

    // handler for rooms (syncs the room list in realtime)
    recursive client_rooms_channel client_chan = Session.make_callback(rooms_handler)

    and function rooms_handler(message) {
      match (message) {
        case {~rooms} :
          rooms_html =
            List.map(function(room) {
              <li>
                <a onclick={join_room(client_chan, room, _)}>
                  {room.name}
                </a>
              </li>
            }, rooms)
          #room_list = <>Rooms: {List.length(rooms_html)}</> <+>
                        <div class=line>{rooms_html}</div>

        case {room: room, ~room_channel} :
          // No longer interested in updates from rooms session
          Model.unsubscribe_for_rooms(user)
          enter_room(user, room, room_channel)
          

        case {~error} :
          Client.alert(error)
      }
    }
    
    function init_rooms(_) {
      // assign with model to get updates for the rooms list
      Model.subscribe_for_rooms(user, client_chan)

      // unsubscribe for rooms session when we join a room
      // (no longer interested in rooms updates)
      Dom.bind_beforeunload_confirmation(function(_) {
        Model.unsubscribe_for_rooms(user)
        none
      })
    }

    function create_room(_) {
      name = Dom.get_value(#new_room_name_entry)
      password = Dom.get_value(#new_room_pwd_entry)

      Model.create_room(name, password)
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
                   autofocus="autofocus"
                   onnewline={create_room(_)} />
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

import stdlib.web.client
import stdlib.widgets.textarea
import stdlib.widgets.core
import ace
import jquery-ui



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
           <div id=#document_actions_container/>
           <div id=#document_tabs/>
        </div>
      </div>
    </div>
    <div id=#main>
      {content}
    </div>
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

  function requires_value(cont, value, text) {
    if (value == "") {
      Client.alert(text)
    } else {
      cont(value);
    }
    void
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

  // show the complete list of users and their cursor position
  function show_users(users) {
    users_html =
      List.map(function(user) {
        <li id={"user-" + Int.to_string(user.id)}>
          {user_and_doc_to_html(user, user.doc_info)}
        </li>
      }, users)
    #users = <>Users: {List.length(users_html)}</>
    #user_list = <ul>{users_html}</ul>
    void
  }

  

  // update a single user, only to be executed after show_users was executed!
  function show_user(user, doc_info) {
    #{"user-" + Int.to_string(user.id)} = {user_and_doc_to_html(user, doc_info)}
      
  }

  function user_and_doc_to_html(user, doc_info) {
    <span class=user_name>{user.name} </span> <+>
    <br/> <+>
    doc_info_to_html(doc_info)
  }

  function doc_info_to_html(doc_info) {
    content = Option.switch(function({~doc_name, ~cursor}) {
        "{doc_name}  ({cursor.row}, {cursor.column})"
      }, "Not in a document", doc_info)

    <span class=user_document_info>
       {content}
    </span>
  }

  function show_document(user, room, doc, room_chan, doc_chan) {

    // create editor
    #document = <div id=#editor class=editor/>
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

    function save_document(client_doc_chan, _) {
      name = Dom.get_value(#save_document_name_entry)
      requires_value(function(name) {
        Model.save_content(doc_chan, name, client_doc_chan)
      }, name, "Please enter a name for your document")
    }

    function get_doc_settings(client_doc_chan, _) {
      Model.get_doc_settings(room_chan, doc.id, client_doc_chan)
      void
    }

    function save_doc_settings() {
      interval = Int.of_string_opt(Dom.get_value(#document_interval_setting))
      Option.lazy_switch(function(interval) {
        Model.set_doc_settings(room_chan, doc.id, interval)
        Widgets.close("#document_settings")
      }, function() {
        Client.alert("That's not a number, you silly!")
      }, interval)        
    }

    function show_doc_settings(doc, interval) {
      #document_settings =  <label> Save Interval </label> <+>
                            <input id=#document_interval_setting
                                  type="text"
                                  placeholder="{interval}"
                                  autofocus="autofocus">
                            </input>
      Widgets.dialog("#document_settings", "Document settings for {doc.name}")
      Widgets.option("#document_settings", "width", 300)
      Widgets.option("#document_settings", "height", 200)
      Widgets.buttons("#document_settings", [{text: "Save", click: function(){save_doc_settings()}},
                                             {text: "Cancel", click: function(){Widgets.close("#document_settings")}}])
    }

   function show_rollback_vote(client_doc_chan, rollbackvote) {
      function deny_rollback() {
        Model.deny_rollback_state(doc_chan)
        Widgets.close("#document_rollback_vote")
      }

      function accept_rollback() {
        Model.accept_rollback_state(doc_chan)
        Widgets.close("#document_rollback_vote")
      }

      #document_rollback_vote = <div id=#document_rollback_vote_preview class=editor/>
      prev = Editor.edit("document_rollback_vote_preview")
      Editor.set_value(prev, rollbackvote.text)
      Widgets.dialog("#document_rollback_vote", "Rollback to {Date.to_string(rollbackvote.date)} ?")
      Widgets.option("#document_rollback_vote", "width", 450)
      Widgets.option("#document_rollback_vote", "height", 600)
      Widgets.buttons("#document_rollback_vote",
        [{text: "Accept", click: function(){ accept_rollback() }},
         {text: "Deny", click: function() { deny_rollback() }}
        ])
      Widgets.on("#document_rollback_vote", "close", function() { deny_rollback() })
      void
    }

    function show_rollback_commit({~date, ~text}) {
      Client.alert("Your document has been rolled back to {Date.to_string(date)}")
      Editor.set_value(inst, text)
    }

    function start_rollback_state(client_doc_chan, date,_) {
      Model.start_rollback_state(doc_chan, date, client_doc_chan)
      void
    }

    function show_rollback_denied(date) {
      Client.alert("The rollback for {Date.to_string(date)} was denied.")
    }

    function get_states(client_doc_chan, _) {
      Model.get_states(doc_chan, client_doc_chan)
    }

    function show_states(client_doc_chan, states) {

      function preview_state(text,_) {
        prev = Editor.edit("document_state_preview")
        Editor.set_value(prev, text)
        void
      }

      documents_html =
        List.fold(function({~date, ~text}, html) {
          html <+>
            <div class=document_state_line>
              <span class=document_state_name>
                {Date.to_string(date)}
              </span>
              <button class="btn secondary"
                      onclick={preview_state(text,_)}>
                View
              </button>
              <button class="btn secondary"
                      onclick={start_rollback_state(client_doc_chan, date,_)}>
                Rollback
              </button>
            </div>
        }, states, <></>)
      #document_states = <div id=document_state_list class=document_import_list>{documents_html}</div> <+>
                         <div id=document_state_preview class="document_import_preview editor"/>
      Widgets.dialog("#document_states", "Initiate rollback to a previous state")
      Widgets.option("#document_states", "width", 800)
      Widgets.option("#document_states", "height", 600)
      void
    }

    recursive client_document_channel client_doc_chan = Session.make_callback(document_handler)
    and function document_handler(client_document_msg message) {
      match (message) {

        case {~text} :
          set_text(text)

        case {saved: name} :
          Client.alert("The document {name} was successfully saved on the server")
          void

        case {~insert, ~pos} :
          Editor.insert_value(inst, pos, insert)
          void

        case {~remove, ~start, ~end} :
          Editor.remove_value(inst, start, end)
          void

        case {~removelines, ~start, ~end} :
          Editor.remove_lines(inst, start, {row: end.row - 1, column: end.column})
          void

        case {~insertlines, ~start} :
          Editor.insert_lines(inst, start, insertlines)
          void

        case {~docinfo, ~interval} :
          show_doc_settings(doc, interval)
          void

        case {~states} :
          show_states(client_doc_chan, states)
          void

        case {~rollbackvote} :
          show_rollback_vote(client_doc_chan, rollbackvote)

        case {~rollback} :
          show_rollback_commit(rollback)

        case {rollback_denied: date} :
          show_rollback_denied(date)
      }
    }

    // Note: an init function is necessary, because the compiler will only know the
    // client_doc_chan variable in a function (because of its recursive definition), not directly in 
    // in the body.
    function init_document(_) {

      // insert document actions: save, settings and saved states buttons
      #document_actions =
        <input id=#save_document_name_entry
               type="text"
               placeholder="Enter Document Name" />
        <button class="btn primary"
                onclick={save_document(client_doc_chan,_)} >
          Save
        </button>
        <br/>
        <button class="btn primary"
                onclick={get_doc_settings(client_doc_chan, _)} >
          Settings
        </button>
        <button class="btn primary"
                onclick={get_states(client_doc_chan, _)} >
          Saved States
        </button>

      // Set up the Editor
      // Editor.set_theme(inst, "ace/theme/monokai")
      Editor.set_mode(inst, "ace/mode/javascript")

      // When the cursor in the Editor changes, propagate this to the 
      // room channel.
      Editor.on_change_cursor(inst, function(pos) {
        // cursor updates are sent to the room channel
        Model.change_cursor(room_chan, user, pos)
      })

      // Listen for changes on the editor and pass them to document channel
      Editor.on_change(inst, function(e) {
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
      })
      // start listening to the doc_chan
      Model.subscribe_document(doc_chan, user, client_doc_chan)
    }


    

    #document =+ <div id=#document_actions
                      onready={init_document(_)} >
                </div>
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
      name = Dom.get_value(#create_document_name_entry)
      Model.create_document(room_channel, name)
    }

    function import_documents(client_room_chan,_) {
      Model.get_saved_documents(room_channel, client_room_chan)
    }

    function show_import_documents(client_room_chan, documents) {

      function preview_document(text,_) {
        prev = Editor.edit("document_import_preview")
        Editor.set_value(prev, text)
      }

      function import_document(name,_) {
        Model.import_document(room_channel, name)
      }

      function delete_document(name,_) {
        Model.delete_saved_document(room_channel, name, client_room_chan)
      }

      documents_html =
        Map.fold(function(name, text, html) {
          html <+>
            <div class=document_import_line>
              <span class=document_import_name>
                {name}
              </span>
              <button class="btn secondary"
                      onclick={preview_document(text,_)}>
                View
              </button>
              <button class="btn secondary"
                      onclick={import_document(name,_)}>
                Import
              </button>
              <button class="btn secondary"
                      onclick={delete_document(name,_)}>
                Delete
              </button>
            </div>
        }, documents, <></>)
      #document_import = <div id=#document_import_list class=document_import_list>{documents_html}</div> <+>
                         <div id=#document_import_preview class="document_import_preview editor"/>
      Widgets.dialog("#document_import", "Import a document into the room")
      Widgets.option("#document_import", "width", 800)
      Widgets.option("#document_import", "height", 600)
      void
    }

    // make client session for room channel and request room channel
    recursive client_room_channel client_channel = Session.make_callback(handle_room)

    // handle incoming messages for client_room_channel
    and function handle_room(client_room_msg message) {
      match(message) {

        case {~users} :
          show_users(users)
          void

        case {~user, ~doc_info} :
          show_user(user, doc_info)
          void

        case {~documents} :
          show_document_tabs(client_channel, documents)
          void

        case {~message} :
          message_update(message)
          void

        case {~import} :
          show_import_documents(client_channel, import)
          void

        case {~doc, ~doc_chan} :
          show_document(user, room, doc, room_channel, doc_chan)
          void

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

      #document_actions_container =
        <input id=#create_document_name_entry
               type="text"
               placeholder="New Document Name"
               onnewline={create_document(_)}/>
        <button class="btn primary"
                onclick={create_document(_)} >
          Create Document
        </button>
        <button class="btn primary"
                onclick={import_documents(client_channel,_)} >
          Import Document
        </button>

    }
    Dom.transform([
      #main = <div id=#document_container>
                <div id=#document/>
                <div id=#document_import/>
                <div id=#document_states/>
                <div id=#document_settings/>
                <div id=#document_rollback_vote/>
              </div>,
      #chat =
        <div id=#sidebar
             onready={init_room(_)} >
          <h4>Users online</h4>
          <div id=#user_list/>
          </div>
          <div id=#chat_content
               onready={function(_){}}>
          <div class=stats><div id=#users/><div id=#uptime/><div id=#memory/></div>
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
      password = if (room.password) {
        Client.prompt("Please enter password for {room.name}", "")
      } else { {some: ""} }
      
      Option.map(function(pwd) {
        // will send the room_channel to our session if succesfully logged in.
        Model.get_room_chan(room.id, pwd, client_chan)
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
              <div class=list>
                <a onclick={join_room(client_chan, room, _)}>
                  {room.name}
                </a>
              </div>
            }, rooms)
          #room_list = <div class=stats><div>Rooms: {List.length(rooms_html)}</div></div> <+>
                        <div>{rooms_html}</div>

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
      requires_value(function(name) {
        password = Dom.get_value(#new_room_pwd_entry)
        Model.create_room(name, password)
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

  // login
  function login(_) {
    name = Dom.get_value(#name)
    requires_value(function(name) {
      user = {
      id: Random.int(Limits.max_int),
      name: name
      }
      enter_rooms(user)
    }, name, "Please enter a nickname to proceed")
  }

  // Start page
  function start() {
    html = build_page(
      <h4>A collaborative programming editor built in Opa.</h4>
      <div id=#login class="form-inline">
        <input id=#name
               type="text"
               placeholder="Enter Nickname"
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

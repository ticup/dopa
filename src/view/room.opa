//
// view/room.opa
//
//
// @author: Tim Coppieters
// @date: 01/2013



module ViewRoom {

  function enter_room(user, room, room_channel) {

    // DOCUMENTS TABS //
    function show_document_tabs(client_room_chan, documents) {

      function enter_document(document, _) {
        // Room will then send its room_channel to the client_room_chan
        Room.get_doc_chan(room_channel, document.id, user, client_room_chan)
        void
      }

      #document_tabs = List.map(function(doc) {
          <button class="btn primary"
                  onclick={enter_document(doc,_)}>{doc.name}</button>
        }, documents)
      void
    }

    // ACTIONS //
    function send_message(_) {
      text = Dom.get_value(#entry);
      message = {source:{~user}, ~text, date:Date.now()}
      Room.send_message(room_channel, {~message})
      // /dopa/messages[date==message.date] <- message
      // Model.broadcast({~message});
      Dom.clear_value(#entry);
    }

    function create_document(_) {
      name = Dom.get_value(#create_document_name_entry)
      Room.create_document(room_channel, name)
    }

    function import_documents(client_room_chan,_) {
      Room.get_saved_documents(room_channel, client_room_chan)
    }

    function show_import_documents(client_room_chan, documents) {

      function preview_document(text,_) {
        prev = Editor.edit("document_import_preview")
        Editor.set_value(prev, text)
      }

      function import_document(name,_) {
        Room.import_document(room_channel, name)
      }

      function delete_document(name,_) {
        Room.delete_saved_document(room_channel, name, client_room_chan)
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


    // CLIENT ROOM CHANNEL //
    recursive client_room_channel client_channel = Session.make_callback(handle_room)

    // handle incoming messages for client_room_channel
    and function handle_room(client_room_msg message) {
      match(message) {

        case {~users} :
          #users = <>Users: {List.length(users)}</>
          #user_list = <ul>{User.users_and_cursor_to_html(users)}</ul>
          void

        case {~user, ~cursor_info} :
          #{"user-" + Int.to_string(user.id)} = {User.user_and_cursor_to_html(user, cursor_info)}
          void

        case {~documents} :
          show_document_tabs(client_channel, documents)
          void

        case {~message} :
          #conversation =+ Message.to_html(message)
          Dom.scroll_to_bottom(#conversation)
          void

        case {~import} :
          show_import_documents(client_channel, import)
          void

        case {~doc, ~doc_chan} :
          ViewDocument.show_document(user, room, doc, room_channel, doc_chan)
          void

        case {~error} :
          Client.alert(error)
          void
 
      }
    }

    
    function init_room(_) {

      // subscribe for the room_channel
      Room.join_room(room_channel, user, client_channel)

      // leave before quiting, this also unsubscribes for possible document sessions!
      Dom.bind_beforeunload_confirmation(function(_) {
        Room.leave_room(room_channel, user)
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
      #navbar =+ <button class="btn primary"
                      onclick={function(_) {Dom.toggle(#chat)}} >
                    Chat 
                 </button> <+>
                 <div id=#document_actions_container/> <+>
                 <div id=#document_tabs/>,
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
}
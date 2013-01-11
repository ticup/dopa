//
// view/document.opa
//
// Provides a view to edit, save and perform rollbacks of a document,
// provided that you consist of a user, room, doc, room_channel and document_channel.
//
// @author: Tim Coppieters
// @date: 01/2013


module ViewDocument {
  
  function show_document(user, room, doc, room_chan, doc_chan) {

    // create editor (create up front so actions can use it)
    #document = <div id=#editor class=editor/>
    inst = Editor.edit("editor")




    // ACTIONS //
    function save_document(client_doc_chan, _) {
      name = Dom.get_value(#save_document_name_entry)
      ViewUtil.requires_value(function(name) {
        Room.save_content(doc_chan, name, client_doc_chan)
      }, name, "Please enter a name for your document")
    }

    function get_doc_settings(client_doc_chan, _) {
      Document.get_doc_settings(doc_chan, client_doc_chan)
      void
    }

    function save_doc_settings() {
      interval = Int.of_string_opt(Dom.get_value(#document_interval_setting))
      Option.lazy_switch(function(interval) {
        Document.set_doc_settings(doc_chan, interval)
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
        Document.deny_rollback_state(doc_chan)
        Widgets.close("#document_rollback_vote")
      }

      function accept_rollback() {
        Document.accept_rollback_state(doc_chan)
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
      Document.start_rollback_state(doc_chan, date, client_doc_chan)
      void
    }

    function show_rollback_denied(date) {
      Client.alert("The rollback for {Date.to_string(date)} was denied.")
    }

    function get_states(client_doc_chan, _) {
      Document.get_states(doc_chan, client_doc_chan)
    }

    function show_states(client_doc_chan, states) {

      function preview_state(text,_) {
        prev = Editor.edit("document_state_preview")
        Editor.set_value(prev, text)
        void
      }

      states_html = State.states_to_html(states, preview_state, start_rollback_state, client_doc_chan)
      #document_states = <div id=document_state_list class=document_import_list>{states_html}</div> <+>
                         <div id=document_state_preview class="document_import_preview editor"/>
      Widgets.dialog("#document_states", "Initiate rollback to a previous state")
      Widgets.option("#document_states", "width", 800)
      Widgets.option("#document_states", "height", 600)
      void
    }




    // DOCUMENT HANDLER //
    // set up client_document_handler to retrieve info from server
    recursive client_document_channel client_doc_chan = Session.make_callback(document_handler)
    and function document_handler(client_document_msg message) {
      match (message) {

        case {~text} :
          Editor.set_value(inst, text)

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

        case {~doc_settings, ~interval} :
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
    // client_doc_chan variable in a function (because of its recursive definition)
    // and not directly in the body.
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
        Room.change_cursor(room_chan, user, pos)
      })

      // Listen for changes on the editor and pass them to document channel
      Editor.on_change(inst, function(e) {
        match(e) {
          case {action: "insertText", ~text, ~start, ~end} :
            Document.insert_text(doc_chan, text, start, client_doc_chan)

          case {action: "removeText", ~text, ~start, ~end} :
            Document.remove_text(doc_chan, text, start, end, client_doc_chan)


          case {action: "removeLines", ~text, ~start, ~end} :
            Document.remove_lines(doc_chan, start, end, client_doc_chan)


          case {action: "insertLines", ~lines, ~start, ~end} :
            Document.insert_lines(doc_chan, lines, start, client_doc_chan)

          default :
            void
        }
      })

      // start listening to the doc_chan
      Document.subscribe_document(doc_chan, user, client_doc_chan)
    }


    
    #document =+ <div id=#document_actions
                      onready={init_document(_)} >
                 </div>
  }
}
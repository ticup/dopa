//
// model/state.opa
//
// Represents a state in time of a Document
//
// @author: Tim Coppieters
// @date: 01/2013


// previous state record of the document
type state = { Date.date date, string text }

module State {
  
  function states_to_html(states, preview_state, rollback, client_doc_chan) {
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
                  onclick={rollback(client_doc_chan, date,_)}>
            Rollback
          </button>
        </div>
    }, states, <></>)
  }
}
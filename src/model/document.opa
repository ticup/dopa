//
// model/document.opa
//
// The model of a document. 
// A room wraps a document_channel which manages the state of a document and
// has listeners (client_document_channel) to which it broadcasts changes of
// the document.
//
// @author: Tim Coppieters
// @date: 01/2013


// Note: the real work-horse of this module is the document_channel_handler function
// all the rest is just typing, helper functions and api.

// DOCUMENT DATA //
// document record
type document = { int id, string name }
// position in the document
type pos = { int row, int column }

// client-side channel to receive info about the document
type client_document_channel = channel(client_document_msg)
type client_document_msg =
  // the document was successfully saved
  { string saved } or 
  // the whole text for the document
  { string text } or
  // manipulations on the document
  { string insert, pos pos } or
  { string remove, pos start, pos end } or
  { string removelines, pos start, pos end } or
  { list(string) insertlines, pos start } or
  // provides the list of states of the document
  { list(state) states } or
  // a rollback vote was started
  { state rollbackvote } or
  // a rollback vote is finished and given state is commited as current state
  { state rollback } or
  // a rollback vote is finished and it was denied
  { Date.date rollback_denied } or
  // provide the document settings (currently only interval of state saver)
  { string doc_settings, int interval }


// document_channel
type document_channel = channel(document_msg)
type document_msg =
  // sets the state saver timer, only used for initialization
  { {(->void) start, (->void) stop, (int->void) change} timer } or
  // send document settings (state save interval) to given client channel
  { client_document_channel get_doc_settings } or
  // set document settings (set the interval to given int)
  { int set_doc_settings } or
  // given user joins the document
  { user join, client_document_channel client_doc_chan } or
  // given user id leaves the document
  { int leave } or
  // document manipulation
  { string insert, pos pos, client_document_channel client_doc_chan } or
  { string remove, pos start, pos end, client_document_channel client_doc_chan } or
  { string removelines, pos start, pos end, client_document_channel client_doc_chan } or
  { list(string) insertlines, pos start, client_document_channel client_doc_chan } or
  // persistently save the given document
  { string save, client_document_channel client_doc_chan } or
  // save the current state of the document
  { savestate } or
  // provide given client_doc_channel with a list of all states
  { client_document_channel states } or
  // start a rollback to state with given date
  { Date.date start_rollback, client_document_channel client_doc_chan } or
  // add an accept vote for current rollback vote
  { vote_accept } or
  // add a deny vote for current rollback vote
  { vote_deny } or
  // stop this channel
  { stop }



module Document {

  // DOCUMENT API //
  function subscribe_document(doc_chan, user, client_doc_chan) {
    Session.send(doc_chan, {join: user, ~client_doc_chan})
  }
  function unsubscribe_document(doc_chan, user_id) {
    Session.send(doc_chan, {leave: user_id})
  }

  function get_doc_settings(doc_chan, client_doc_chan) {
    Session.send(doc_chan, {get_doc_settings: client_doc_chan})
  }
  function set_doc_settings(doc_chan, interval) {
    Session.send(doc_chan, {set_doc_settings: interval})
  }

  function insert_text(doc_chan, text, pos, client_doc_chan) {
    Session.send(doc_chan, {insert: text, ~pos, ~client_doc_chan})
  }
  function remove_text(doc_chan, text, start, end, client_doc_chan) {
    Session.send(doc_chan, {remove: text, ~start, ~end, ~client_doc_chan})
  }
  function remove_lines(doc_chan, start, end, client_doc_chan) {
    Session.send(doc_chan, {removelines: "", ~start, ~end, ~client_doc_chan})
  }
  function insert_lines(doc_chan, lines, start, client_doc_chan) {
    Session.send(doc_chan, {insertlines: lines, ~start, ~client_doc_chan})
  }

  function get_states(doc_chan, client_doc_chan) {
    Session.send(doc_chan, {states: client_doc_chan})
  }
  function start_rollback_state(doc_chan, date, client_doc_chan) {
    Session.send(doc_chan, {start_rollback: date, ~client_doc_chan})
  }
  function accept_rollback_state(doc_chan) {
    Session.send(doc_chan, {vote_accept})
  }
  function deny_rollback_state(doc_chan) {
    Session.send(doc_chan, {vote_deny})
  }



  // DOCUMENT HELPERS //
  function create_timer(interval, doc_chan) {
    timer = Scheduler.make_timer(interval, function() {
      save_state(doc_chan)
    })
    timer.start()
    timer
  }
  function save_state(doc_chan) {
    Session.send(doc_chan, {savestate})
  }

  // sends given message to all listeners
  function notifyAll(message, listeners) {
    IntMap.iter(function(id, chan) {
        Session.send(chan, message)
    }, listeners)
  }
  
   // sends given message to all listeners except for given channel
  function notifyAllBut(message, listeners, chan_sender) {
    IntMap.iter(function(id, chan) {
      if (chan != chan_sender)
        Session.send(chan, message)
    }, listeners)
  }

  // converts the lines representation of the document of the server to a pure text representation
  function lines_to_string(lines) {
    String.of_list(function(lst){ List.to_string_using("", "", "", lst) }, "\n", lines)
  }

  // converts a server state record to a client state record
  function to_client_state({~date, ~lines}) {
    {~date, text: lines_to_string(lines)}
  }

  // DOCUMENT CHANNEL
  function create_document_channel(id, name, text) {
    lines = if (text == "") { [[]] }
            else { List.map(function(row) { String.explode("", row) }, String.explode("\n", text)) }
    interval = 20000
    chan = Session.make({~id,
                          ~name,
                          ~lines,
                          ~interval,
                          timer: Scheduler.make_timer(interval, function() {void}),    // dummy timer
                          states: [],
                          rollback: {counts: {accept: 0, deny: 0},
                                     state: none},
                          listeners: IntMap.empty},
                        document_channel_handler)
    timer = create_timer(interval, chan)
    Session.send(chan, {~timer})
    chan
  }

  // A document has the following info:
  //  - int id
  //  - string name
  //  - list(list(<one character string>)) lines
  //    which represents the current state of a document (list of rows, where a row is a list of one-length strings)
  //  - int interval : the current inerval set for the state saver timer
  //  - Scheduler.timer timer : the timer that regularly saves states of the document
  //  - list(state) states : previously saved states by the timer
  //  - { { int accepts, int denies }, option(state) state } rollback
  //     which holds the info about the current rollback vote
  //  - list(client_document_channel) listeners 

  private function document_channel_handler({~id, ~name, ~lines, ~interval, ~timer, ~states, ~rollback, ~listeners}, message) {
    match(message) {

      // set given timer (only for initialization)
      case {~timer} :
        {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, ~rollback, ~listeners}}

      // send the document settings to given client_doc_chan
      case {get_doc_settings: client_doc_chan} :
        Session.send(client_doc_chan, {doc_settings: name, ~interval})
        {unchanged}

      // change the document settings (change the state saver interval)
      case {set_doc_settings: interval} :
        timer.change(interval)
        {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, ~rollback, ~listeners}}


      // a user joins the document: add him as a listener
      case {join: user, ~client_doc_chan} :
        newListeners = IntMap.add(user.id, client_doc_chan, listeners)
        Session.send(client_doc_chan, {text: lines_to_string(lines)})
        {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, ~rollback, listeners: newListeners}}

      // a user leaves the document: remove him as a listener
      case {leave: id} :
        newListeners = IntMap.remove(id, listeners)
        {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, ~rollback, listeners: newListeners}}


      // persistently save the current state of the document
      case {save: name, ~client_doc_chan} :
        Documents.set(name, lines_to_string(lines))
        Session.send(client_doc_chan, {saved: name})
        {unchanged}

      // document manipulations
      // these are events that the Ace editor emits mapped onto our "lines" document structure
      case {insert: "\n", ~pos, ~client_doc_chan} :
        // get the involved row
        (line, otherlines) = List.extract(pos.row, lines)
        // split the row at the involved col
        (s, e) = List.split_at(Option.get(line), pos.column)
        // merge the rows back into the lines
        newlines = List.insert_at(s, pos.row, List.insert_at(e, pos.row, otherlines))
        // notify all clients to do the same
        notifyAllBut({insert: "\n", ~pos}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~interval, ~timer, ~states, ~rollback, ~listeners}}

      case {~insert, ~pos, ~client_doc_chan} :
        // convert given string to insert into list of string characters
        list(string) chars = String.explode("", insert)
        // get the involved row
        (line, otherlines) = List.extract(pos.row, lines)
        // split the row at the involved col
        (s, e) = List.split_at(Option.get(line), pos.column)
        // make a new row, merging the chars at the correct position
        newline = List.append(s, List.append(chars, e))
        // merge the row back into the lines
        newlines = List.insert_at(newline, pos.row, otherlines)
        // notify all clients to do the same
        notifyAllBut({~insert, ~pos}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~interval, ~timer, ~states, ~rollback, ~listeners}}

      case {~remove, ~start, ~end, ~client_doc_chan} :
        // get the start row
        (toplines, otherlines) = List.split_at(lines, start.row)
        // split the row until where it is retained
        (s, _) = List.split_at(List.head(otherlines), start.column)

        // get the end row
        (_, bottomlines) = List.split_at(lines, end.row)
        // split the row from where is retained
        (_, d) = List.split_at(List.head(bottomlines), end.column)
        // merge the retained parts
        mergeline = List.append(s, d)
        // merge the row back with the retained lines
        newlines = List.append(toplines, mergeline +> List.tail(bottomlines))
        // notify all clients to do the same
        notifyAllBut({~remove, ~start, ~end}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~interval, ~timer, ~states, ~rollback, ~listeners}}

      case {~removelines, ~start, ~end, ~client_doc_chan} :
        (s, _) = List.split_at(lines, start.row)
        (_, e) = List.split_at(lines, end.row)
        newlines = List.append(s, e)
        notifyAllBut({~removelines, ~start, ~end}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~interval, ~timer, ~states, ~rollback, ~listeners}}

      case {~insertlines, ~start, ~client_doc_chan} :
        (s, e) = List.split_at(lines, start.row)
        insert = List.map(function(str) { String.explode("", str) }, insertlines)
        newlines = List.append(s, List.append(insert, e))
        notifyAllBut({~insertlines, ~start}, listeners, client_doc_chan)
        {set: {~id, ~name, lines: newlines, ~interval, ~timer, ~states, ~rollback, ~listeners}}

      // add the current state to the list of states
      case {savestate} :
        state = {date: Date.now(), ~lines}
        {set: {~id, ~name, ~lines, ~interval, ~timer, states: [state|states], ~rollback, ~listeners}}

      // send the list of states to given client_document_channel
      case {states: client_doc_chan} :
        textstates = List.map(function(state) {
          to_client_state(state)
        }, states)
        Session.send(client_doc_chan, {states: textstates})
        {unchanged}

      // start vote for a rollback to state of given date
      case {start_rollback: rollback_date, ~client_doc_chan} :
        state = Option.get(List.find(function({~date, ~lines}) {rollback_date == date}, states))
        // If there is only 2 listener, do rollback instantly
        if (IntMap.size(listeners) < 3) {
          notifyAll({rollback: to_client_state(state)}, listeners)
          {set: {~id, ~name, lines: state.lines, ~interval, ~timer, ~states, rollback: {counts: {accept: 0, deny: 0},
                                                                                        state: none},
                                                                            ~listeners}}
        // otherwise, set rollback and set accept to 1 (initiator counts as an accept vote)
        } else {
          notifyAllBut({rollbackvote: to_client_state(state)}, listeners, client_doc_chan)
          {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, rollback: {counts: {accept: 1, deny: 0},
                                                         state: {some: state}},
                                                        ~listeners}}
        }

      // add an accept for the rollback vote
      case {vote_accept} :
        counts = {accept: rollback.counts.accept + 1, deny: rollback.counts.deny}
        // if we got 50% on board, perform rollback
        if (counts.accept >= IntMap.size(listeners)/2) {
          state = Option.get(rollback.state)
          notifyAll({rollback: to_client_state(state)}, listeners)
          {set: {~id, ~name, lines: state.lines, ~interval, ~timer, ~states, rollback: {counts: {accept: 0, deny: 0}, state: none}, ~listeners}}
        // otherwise just add a count
        } else {
          {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, rollback: {~counts, state: rollback.state}, ~listeners}}
        }

      // add a deny for the rollback vote
      case {vote_deny} :
        counts = {accept: rollback.counts.accept, deny: rollback.counts.deny + 1}
        // if more than 50% voted deny for the rollback, deny
        if (counts.deny > IntMap.size(listeners)/2) {
          state = Option.get(rollback.state)
          notifyAll({rollback_denied: state.date}, listeners)
          {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, rollback: {counts: {accept: 0, deny: 0}, state: none}, ~listeners}}
        // otherwise just add a count
        } else {
          {set: {~id, ~name, ~lines, ~interval, ~timer, ~states, rollback: {~counts, state: rollback.state}, ~listeners}}
        }

      // stop this channel
      case {stop} :
        Debug.jlog("stopping document")
        {stop}
    }
  }
}
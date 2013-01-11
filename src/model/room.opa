//
// model/room.opa
//
// The model of a room. 
// A room wraps a room_channel which manages multiple document_channels (document.opa) and a chat room.
// Besides document_channels it also manages client_room_channels, to which it sends updates
// about the state of the room (which documents are in it) and the chat room.
//
// @author: Tim Coppieters
// @date: 01/2013


// Note: the real work-horse of this module is the room_channel_handler function
// all the rest is just typing, helper functions and api.


// ROOM DATA //
type room_prot = { int id, string name, bool password }
type room_client = { int id, string name, option(string) password }

// client_room_channel:
// a client channel that the room_channel uses to talk to.
type client_room_channel = channel(client_room_msg)
type client_room_msg =
  // all the info to display a user list
  { list(user_and_cursor_info) users } or
  // all the info for one user in the user list (for efficient updating)
  user_and_cursor_info or
  // all the info to display a document list
  { list(document) documents } or
  // a message for the chat
  { message message } or
  // the given document its document_channel
  { document doc, document_channel doc_chan } or
  // a stringmap of unique names to text of documents that can be imported
  { stringmap(string) import } or
  // an error (the view has requested something impossible)
  { string error }

// room_channel:
// Manages users (listeners) and documents and will notify the users of all changes made to any of those two.
type room_channel = channel(room_msg)
type room_msg =
  // add a user as listener with his client channel to this room
  { user join, client_room_channel chan } or
  // remove given user as a listener for this room
  { user leave } or
  // send chat message to all listeners
  { message message } or
  // update user's position
  { pos cursor, user user} or
  // create given document and
  { string create_document } or
  // a user requests to join a given document
  // -> this will return the document_channel to the client_room_chan so it can communicate with the document
  { int join_document, user user, client_room_channel client_room_chan } or
  // import document with given name into the room
  { string import_document } or
  // delete the saved document with given name
  { string delete_saved_document, client_room_channel client_room_chan } or
  // send the saved documents to given client channel
  { client_room_channel get_saved_documents }


module Room {

  // ROOM API //
 function join_room(room_chan, user, client_room_chan) {
    Session.send(room_chan, {join: user, chan: client_room_chan})
  }
  function leave_room(room_chan, user) {
    Session.send(room_chan, {leave: user})
  }
  function send_message(room_channel, message) {
    Session.send(room_channel, message)
  }
  function change_cursor(room_channel, user, pos) {
    Session.send(room_channel, {cursor: pos, ~user})
  }
  function create_document(room_channel, name) {
    Session.send(room_channel, {create_document: name})
  }
  function get_doc_chan(room_channel, doc_id, user, client_room_chan) {
    Session.send(room_channel, {join_document: doc_id, ~user, ~client_room_chan})
  }
  function import_document(room_channel, name) {
    Session.send(room_channel, {import_document: name})
  }

  // NOTE: mongo requests must go through a server Session, otherwise the ACE plugin doesn't work!!
  // therefore we have decided to let the client documents requests be done to the room
  function save_content(doc_chan, name, client_doc_chan) {
    Session.send(doc_chan, {save: name, ~client_doc_chan})
  }
  function get_saved_documents(room_chan, client_room_chan) {
    Session.send(room_chan, {get_saved_documents: client_room_chan})
  }
  function delete_saved_document(room_chan, name, client_room_chan) {
    Session.send(room_chan, {delete_saved_document: name, ~client_room_chan})
  }

  

  
  // ROOM_CHANNEL HELPERS //
  //
  // note: when we say "listeners" we mean the client_room_channels of the userMap
  // those are the channels that need to receive updates of the room_channel.

  // sends given message to all listeners
  function notifyAll(message, userMap) {
    List.iter(function({~user, ~cursor, ~chan, ~doc_id}) {
      Session.send(chan, message)
    }, IntMap.To.val_list(userMap))
  }

  // sends all users to all listeners
  function broadCastUsers(userMap, docMap) {
    userList = userMap
      |> IntMap.To.val_list(_)
      |> List.map(function({~user, ~cursor, ~chan, ~doc_id}) {
          cursor_info = Option.map(function (d_id) { 
            { ~name, ... } = Option.get(Map.get(d_id, docMap))
            { doc_name: name, ~cursor }
          }, doc_id)
          {~user, ~cursor_info}
        }, _)
      |> List.sort_by(function({~user, ...}){ user.name }, _)

    notifyAll({users: userList}, userMap)
  }

  // transforms a docMap into a List which can be used to send to clients
  function docmap_to_list(docMap) {
    docMap
      |> IntMap.To.assoc_list(_)
      |> List.map(function((id, {~name, ... })) { {~id, ~name} }, _)
      |> List.sort_by(function(d){ d.name }, _)
  }

  // send all documents to all listeners
  function broadCastDocuments(docMap, userMap) {
    notifyAll({documents: docmap_to_list(docMap)}, userMap)
  }

  // send the cursor update of given user to all listeners
  function broadCastUser(user, doc_id, cursor, userMap, docMap) {
    cursor_info = Option.map(function (d_id) { 
                { ~name, ... } = Option.get(Map.get(d_id, docMap))
                { doc_name: name, ~cursor }
              }, doc_id)
    notifyAll({~user, ~cursor_info}, userMap)
  }

  // - create a new document for the room
  // - broadcast the new documents list to all listeners
  // - return a set to add it to the room_channel
  function create_and_add_document(id, name, doc_name, text, docMap, userMap) {
    docId = Util.createId(docMap)
    doc_chan = Document.create_document_channel(docId, doc_name, text)
    newDocs = IntMap.add(docId, {name:doc_name, ~doc_chan}, docMap)
    broadCastDocuments(newDocs, userMap)
    {set: {~id, ~name, docMap: newDocs, ~userMap}}
  }



  // ROOM_CHANNEL //
  function create_room_channel(id, name, rooms) {
    Session.make({~id, ~name, userMap: IntMap.empty, docMap: IntMap.empty}, room_channel_handler(rooms, _, _))
  }

  // a room has an id, a name and 2 maps
  // - userMap: maps the id of the users to:
  //      {user user,
  //       position cursor,
  //       client_room_channel client_room_channel,
  //       int doc_id}
  //    where doc_id is the id of the document it is currently editing
  // - docMap: maps the id of the documents to:
  //      {string name,
  //       document_channel}

  // handles incomming messages to the room_channel (main working horse of the room)
  private function room_channel_handler(rooms, {~id, ~name, ~userMap, ~docMap}, room_msg) {

    match (room_msg) {

      // a user joins as a listener:
      //  - update the user list of all listeners
      //  - send the document list to newly joined user
      //  - send a message to the chat to anounce the arrival of the new user
      //  - add to userMap
      case {join: user, ~chan} :
        newUsers = IntMap.add(user.id, {~user, cursor: {row: 0, column: 0}, ~chan, doc_id: none}, userMap)
        message = {
          source: {system},
          text : "{user.name} joined the room",
          date : Date.now(),
        }
        broadCastUsers(newUsers, docMap)
        Session.send(chan, {documents: docmap_to_list(docMap)})
        notifyAll({~message}, newUsers)
        {set: {~id, ~name, userMap: newUsers, ~docMap}}

      // a user leaves:
      //  - remove from userMap
      //  - if there are now more listeners, initiate removal of this room
      //  - otherwise: - anounce the departure of the user in chat
      //               - update the user list of all listeners
      //               - if the user was editing a document, remove him as a listener from that document
      case {leave: user} :
        {~user, ~cursor, ~chan, ~doc_id} = Option.get(IntMap.get(user.id, userMap))
        newUsers = IntMap.remove(user.id, userMap)
        if (IntMap.is_empty(newUsers)) {
          // remove this room from rooms
          Session.send(rooms, {remove: {~id, ~name}})
          // stop all document sessions of this room
          Map.iter(function(_, {~name, ~doc_chan}) {
            Session.send(doc_chan, {stop})
          }, docMap)
          // stop this room session
          {stop}
        } else {
          message = {
            source: {system},
            text : "{user.name} left the room",
            date : Date.now(),
          }
          notifyAll({~message}, newUsers)
          broadCastUsers(newUsers, docMap)

          // if listening to document, remove listener
          Option.map(function (id) {
            Document.unsubscribe_document(Option.get(IntMap.get(id, docMap)).doc_chan, user.id)
            doc_id
          }, doc_id)

          {set: {~id, ~name, userMap: newUsers, ~docMap}}
        }

      // broadcast chat message to all listeners
      case {~message} :
        notifyAll({~message}, userMap)
        {unchanged}

      // a user has changed its cursor in the document:
      // update cursor of user and broadcast the update to all listeners
      case {~cursor, ~user} :
        newUsers = IntMap.replace(user.id, function ({~user, cursor: old_cursor, ~chan, ~doc_id}) {
          broadCastUser(user, doc_id, cursor, userMap, docMap)
          {~user, ~cursor, ~chan, ~doc_id}
        }, userMap)
        {set: {~id, ~name, ~docMap, userMap: newUsers}}

      // creating a new document:
      //  - create a new document_channel
      //  - notify all listeners of the new document
      //  - add the new document_channel
      case {create_document: doc_name} :
        create_and_add_document(id, name, doc_name, "", docMap, userMap)

      // a user wants to join a given document:
      //  - if the user was already editing another document, unsubscribe him from that channel
      //  - send the document_channel to the given client_room_channel
      //  - update cursor and doc_id of the user
      case {join_document: new_doc_id, ~user, ~client_room_chan} :
        // set the doc_id of the user to new doc_id
        newUsers = IntMap.replace(user.id, function ({~user, ~cursor, ~chan, ~doc_id}) {
          // remove listener from old document if exists
          Option.map(function (d_id) {
            Document.unsubscribe_document(Option.get(IntMap.get(d_id, docMap)).doc_chan, user.id)
          }, doc_id)

          doc = IntMap.get(new_doc_id, docMap)
          match (doc) {
            case {some: {~name, ~doc_chan}} :
              Session.send(client_room_chan, {doc: {id: new_doc_id, ~name}, ~doc_chan})
            case {none} :
              Session.send(chan, {error: Int.to_string(id) + " does not exist"})
          }
          // set new doc id and cursor to 0 0
          {~user, cursor: {row: 0, column: 0}, ~chan, doc_id: {some: new_doc_id}}
        }, userMap)
        {set: {~id, ~name, userMap: newUsers, ~docMap}}

      // send the saved documents from Documents to given client_room_channel
      case {get_saved_documents: client_room_chan} :
        documents = Documents.get_stringmap()
        Session.send(client_room_chan, {import: documents})
        {unchanged}

      // import a given document from Documents into the room:
      //  - create a new room_channel for it
      //  - add it to the docMap
      //  - broadcast the new documents list
      case {import_document: doc_name} :
        text = Documents.get(doc_name)
        create_and_add_document(id, name, doc_name, text, docMap, userMap)

      // remove a saved document:
      //  - remove it from database
      //  - send the remover an updated list
      case {delete_saved_document: doc_name, ~client_room_chan} :
        Documents.delete(doc_name)
        documents = Documents.get_stringmap()
        Session.send(client_room_chan, {import: documents})
        {unchanged}
    }
  }
}
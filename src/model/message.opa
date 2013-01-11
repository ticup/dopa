//
// model/message.opa
//
// Represents a message for the chat of the room_channel
//
// @author: Tim Coppieters
// @date: 01/2013


type source = { system } or { user user }
type message = { source source, string text, Date.date date }


module Message {

  // converts a message into html
  function to_html(message) {
    date = Date.to_formatted_string(Date.default_printer, message.date)
    time = Date.to_string_time_only(message.date)
    <div class="line">
      <span class="date" title="{date}">{time}</span>
      {source_to_html(message.source)}
      <div class="message">{message.text}</>
    </div>
  }

  // converts the source of a message 
  function source_to_html(source) {
    match(source) {
      case {system} :
        <span class="system" />
      case {~user} :
        <span class="user">{user.name}</span>
    }
  }
}
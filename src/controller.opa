module Controller {


}

// Parse URL
url_parser = parser {
  case (.*): View.start()
}

// Start the server
Server.start(Server.http, [
  { resources : @static_resource_directory("resources") }, // include resources directory
  { register : {css:["/resources/css/style.css"]} }, // include CSS in headers
  { custom : url_parser } // URL parser
])

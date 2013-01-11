
module Controller {


}
resources = @static_resource_directory("resources")

// Parse URL
url_parser = parser {
  case (.*): View.start()
}

custom = {
  parser {
    case r={Server.resource_map(resources)} : r
    default: View.start()
  }
}

// Start the server
Server.start(Server.http, [
  { resources : @static_resource_directory("resources") }, // include resources directory
  { register : [ {css: [ "/resources/css/style.css", "/resources/js/jquery-ui/css/smoothness/jquery-ui-1.9.2.custom.min.css"]},
                 {js: ["/resources/js/ace-builds-master/src-min-noconflict/ace.js", "resources/js/jquery-ui/js/jquery-ui-1.9.2.custom.min.js"]}
               ] },
  { ~custom } // URL parser
])

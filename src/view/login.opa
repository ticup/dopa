//
// view/login.opa
//
// @author: Tim Coppieters
// @date: 01/2013



import stdlib.web.client

module View {

  // sets up the basic structure of the page
  function build_page(content) {
    <div class="navbar navbar-fixed-top">
      <div class=navbar-inner>
        <div id=#navbar class=container>
          <a class=brand href="">dopa</>
        </div>
      </div>
    </div>
    <div id=#main>
      {content}
    </div>
    <div id=#chat/>
    
  }

  // login
  function login(_) {
    name = Dom.get_value(#name)
    ViewUtil.requires_value(function(name) {
      user = {
        id: Random.int(Limits.max_int),
        name: name
      }
      ViewRooms.enter_rooms(user)
    }, name, "Please enter a nickname to proceed")
  }

  // Start page: gets called by the controller and sets up the page
  function start() {
    html = build_page(
      <div id=#login_container>
        <h4>A collaborative programming editor built in Opa.</h4>
        <input id=#name
               type="text"
               placeholder="Enter Nickname"
               autofocus="autofocus"
               onready={function(_){Dom.give_focus(#name)}}
               onnewline={login}/>
        <button class="btn primary"
                onclick={login}>Join
        </button>
      </div>
    )
    Resource.page("Dopa - Collaboratively writing code", html)
  }

}

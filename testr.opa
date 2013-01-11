client function blah(_) {

i = Int.of_string_opt("xyz")

#content = <>meh {i}</>

}

 

function page() {

i = Int.of_string_opt("xyz")

<div id=#content onready={blah}>

loading...

</div>

}

 

Server.start(Server.http, {{title: "", page: page}})
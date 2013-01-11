#!/usr/bin/env sh
/*usr/bin/env true
export NODE_PATH="$NODE_PATH:/opt/mlstate/lib/opa/static:/opt/mlstate/lib/opa/stdlib:/opt/mlstate/lib/opa/stdlib/stdlib.qmljs:`which npm > /dev/null 2>&1 && npm root -g`:node_modules:"


node=`which node 2>&1`
if [ $? -ne 0 ] || [ ! -x "$node" ]; then

    NODE_VERSION=v0.8.7

    # Detect OS
    IS_LINUX=""
    IS_MAC=""
    IS_WINDOWS=""
    IS_FREEBSD=""
    case $(uname) in
    CYGWIN*) IS_WINDOWS=1;;
    Darwin*) IS_MAC=1;;
    Linux*|GNU/kFreeBSD) IS_LINUX=1;;
    FreeBSD) IS_FREEBSD=1;;
    *)
            echo "Error: could not detect OS. Defaulting to Linux" >&2
            IS_LINUX=1
    esac

    echo "node.js is missing, Download and install it ? (no will abort) [Yn] \c"
    read yesno
    case "$yesno" in
        y|Y|yes|YES)
        if [ -n "$IS_MAC" ]; then
        port=`which port 2>&1`
        if [ $? -eq 0 ] && [ -x "$port" ]; then
            echo "--> Installing via MacPorts...";
            sudo port install nodejs
        else
            brew=`which brew 2>&1`
            if [ $? -eq 0 ] && [ -x "$brew" ]; then
            echo "--> Installing via Homebrew...";
            brew install node # Warning: brew installs are known to be buggy
            else
            if ! [ -f /tmp/node-$NODE_VERSION.pkg ]; then
                NODE_URL=http://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION.pkg
                echo "--> Downloading $NODE_URL..."
                curl $NODE_URL > /tmp/node-$NODE_VERSION.pkg
            fi
            echo "--> Opening Node installer $NODE_VERSION, please follow the instructions and then relaunch this application"
            open /tmp/node-$NODE_VERSION.pkg
        exit 1
            fi
        fi
        elif [ -n "$IS_LINUX" ]; then
        case $(uname -v) in
            *Ubuntu*)
            sudo apt-get install python-software-properties
            sudo add-apt-repository ppa:chris-lea/node.js
            sudo apt-get update
            sudo apt-get install nodejs npm
            ;;
            *)
            echo "--> node.js is missing, please install node.js from: http://nodejs.org"
            exit 1
        esac
        else
        echo "--> node.js is missing, please install node.js from: http://nodejs.org"
        exit 1

        fi;;
    *) echo "--> Aborting..."; exit 1
    esac

fi;

if [ $? -ne 0 ]; then exit $?; fi;
node "$0" "$@"; exit $?;

*/


var min_node_version = 'v0.6.0';

if (process.version < min_node_version) {
    console.error('Your version of node seems to be too old. Please upgrade to a more recent version of node (>= '+min_node_version+')');
    process.exit(1);
}


require('opa-js-runtime-cps');
check_opa_deps(['opabsl.opp']);
require("opa-js-runtime-cps");
require("opabsl.opp");
require("stdlib.core.web.server.opx");
var ___server_ast = BslCps_topwait(___register_server_code_ec6de8cf({package_:"",adhoc_e:[{td:[],rd:[],r:[true],id:["`_v1_Server_private_run_services_stdlib.core.web.server`"],i:{some:"_v1_run_services"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[true],id:["_v1_page","`_v1_start_stdlib.core.web.server`"],i:{some:"_v1__do_"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["`_v1_FunActionServer_serialize_call_stdlib.core.funaction`","`_v1_FunActionServer_serialize_argument_stdlib.core.funaction`","_____fae"],i:{some:"_v1_page"},d:js_void,c:{some:"__v2_page"}},{td:[],rd:[],r:[false],id:["__stub_fae"],i:{some:"_v1_fae"},d:js_void,c:{some:"__v2_fae"}},{td:[],rd:["\"__fae\""],r:[false],id:["_v2_t","`_v1_OpaRPC_Server_send_to_client_stdlib.core.rpc.core`","`_v1_OpaRPC_add_args_with_type_stdlib.core.rpc.core`"],i:{some:"__stub_fae"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["_v1_blah","`_v205_t_stdlib.core.web.core`"],i:{some:"_v1_fa"},d:js_void,c:{some:"__v2_fa"}},{td:[],rd:[],r:[false],id:["__stub_blah"],i:{some:"_v1_blah"},d:js_void,c:{some:"__v2_blah"}},{td:[],rd:["\"__blah\""],r:[false],id:["__t","`_v1_OpaRPC_Server_send_to_client_stdlib.core.rpc.core`","`_v1_OpaRPC_add_args_with_type_stdlib.core.rpc.core`"],i:{some:"__stub_blah"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["_v1_t"],i:{some:"_v2_t"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["`_v12_t_stdlib.core.funaction`"],i:{some:"_v1_t"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["`_v245_t_stdlib.core`"],i:{some:"__t"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["___fae"],i:{some:"_____fae"},d:js_void,c:{none:js_void}}]},cont(BslCps_topk)));
var ______fae = BslCps_topwait(___define_rename_e6b11301("___fae",cont(BslCps_topk)));
var ___register_js_ast = BslCps_topwait(___register_js_code_ec6de8cf({ast:[{ast:[{d:js_void,c:[{v:""},{s:["___page","___fae","___fa","___blah"]},{v:";\n"}],r:[true],i:{i:"___toplevel_statement"}},{d:js_void,c:[{v:"var "},{i:"_s42febb4921"},{v:" = {quantifier:"},{i:"_sabdaa5be30"},{v:",body:"},{i:"_s5f404e41b9"},{v:"};\n"}],r:[false],i:{k:"_s42febb4921"}},{d:js_void,c:[{v:"var "},{i:"_s43bfedff2f"},{v:" = {TyArrow_params:"},{i:"_sf66f0e0ca4"},{v:",TyArrow_res:"},{i:"_s2474f3a4a6"},{v:"};\n"}],r:[false],i:{k:"_s43bfedff2f"}},{d:js_void,c:[{v:"var "},{i:"_s06b14c1d8a"},{v:" = {quantifier:"},{i:"_sabdaa5be30"},{v:",body:"},{i:"_s43bfedff2f"},{v:"};\n"}],r:[false],i:{k:"_s06b14c1d8a"}},{d:js_void,c:[{v:"function "},{i:"___blah"},{v:"(a){return a = "},{i:"BslNumber_Int_of_string_opt"},{v:"(\"xyz\"),"},{i:"___transform_on_client_2b6d75d2"},{v:"({hd:{jq:"},{i:"___select_id_2b6d75d2"},{v:"(\"content\"),subject:{content:{fragment:{hd:{text:\"meh \"},tl:{hd:"},{i:"___of_alpha_2b6d75d2"},{v:"("},{i:"_s9110c3bcc8"},{v:")(a),tl:{nil:"},{i:"js_void"},{v:"}}}}},verb:{set:"},{i:"js_void"},{v:"}},tl:{nil:"},{i:"js_void"},{v:"}});}\n"}],r:[false],i:{i:"___blah"}},{d:js_void,c:[{v:"function "},{i:"___fa"},{v:"(a){return "},{i:"___blah"},{v:";}\n"}],r:[false],i:{i:"___fa"}},{d:js_void,c:[{v:"function "},{i:"___an"},{v:"(a){return "},{i:"___blah"},{v:"(a);}\n"}],r:[false],i:{i:"___an"}},{d:js_void,c:[{v:"function "},{i:"___fae"},{v:"(a){return "},{i:"___an"},{v:";}\n"}],r:[false],i:{i:"___fae"}},{d:js_void,c:[{v:"function "},{i:"___page"},{v:"(){return "},{i:"BslNumber_Int_of_string_opt"},{v:"(\"xyz\"),{namespace:\"\",tag:\"div\",args:{hd:{namespace:\"\",name:\"id\",value:\"content\"},tl:{nil:"},{i:"js_void"},{v:"}},specific_attributes:{some:{\"class\":{nil:"},{i:"js_void"},{v:"},style:{nil:"},{i:"js_void"},{v:"},bool_attributes:{nil:"},{i:"js_void"},{v:"},events:{hd:{name:{ready:"},{i:"js_void"},{v:"},value:{expr:"},{i:"___an"},{v:"}},tl:{nil:"},{i:"js_void"},{v:"}},events_options:{nil:"},{i:"js_void"},{v:"},href:{none:"},{i:"js_void"},{v:"}}},xmlns:{nil:"},{i:"js_void"},{v:"},content:{hd:{text:\"\\nloading...\\n\"},tl:{nil:"},{i:"js_void"},{v:"}}};}\n"}],r:[false],i:{i:"___page"}},{d:js_void,c:[{v:"function "},{i:"___skeleton_fae"},{v:"(a){var b,f,e,d,c;return (b = "},{i:"__v8_unserialize_f2f00d5f"},{v:"(a).some)?(c = "},{i:"___extract_types_f2f00d5f"},{v:"(b),(d = c.types,d != null) && (a = c.rows,a != null) && (e = c.cols,e != null) && "},{i:"size"},{v:"(c) === 3 && (f = e.nil,f != null) && "},{i:"size"},{v:"(e) === 1 && "},{i:"size"},{v:"(f) === 0 && a.nil != null && "},{i:"size"},{v:"(a) === 1 && "},{i:"size"},{v:"(a.nil) === 0 && d.tl != null && d.hd != null && "},{i:"size"},{v:"(d) === 2 && d.tl.nil != null && "},{i:"size"},{v:"(d.tl) === 1 && "},{i:"size"},{v:"(d.tl.nil) === 0?(d = "},{i:"___implementation_ec6de8cf"},{v:"(c,"},{i:"_s06b14c1d8a"},{v:"),(a = d.TyArrow_params)?(a = "},{i:"___extract_values_f2f00d5f"},{v:"(b,a).some) && (a = a.tl) && a.nil?{some:"},{i:"__v6_serialize_f2f00d5f"},{v:"(d.TyArrow_res)("},{i:"___an"},{v:")}:{none:"},{i:"js_void"},{v:"}:{none:"},{i:"js_void"},{v:"}):{none:"},{i:"js_void"},{v:"}):{none:"},{i:"js_void"},{v:"};}\n"}],r:[false],i:{i:"___skeleton_fae"}},{d:{r:"\"__fae\""},c:[{v:"var "},{i:"___register_fae"},{v:" = "},{i:"___register_f2f00d5f"},{v:"("},{rd:"\"__fae\""},{v:","},{i:"___skeleton_fae"},{v:");\n"}],r:[false],i:{i:"___register_fae"}},{d:js_void,c:[{v:"function "},{i:"___skeleton_blah"},{v:"(a){var b,f,e,d,c;return (b = "},{i:"__v8_unserialize_f2f00d5f"},{v:"(a).some)?(c = "},{i:"___extract_types_f2f00d5f"},{v:"(b),(d = c.types,d != null) && (e = c.rows,e != null) && (a = c.cols,a != null) && "},{i:"size"},{v:"(c) === 3 && (f = a.nil,f != null) && "},{i:"size"},{v:"(a) === 1 && "},{i:"size"},{v:"(f) === 0 && e.nil != null && "},{i:"size"},{v:"(e) === 1 && "},{i:"size"},{v:"(e.nil) === 0 && d.tl != null && d.hd != null && "},{i:"size"},{v:"(d) === 2 && d.tl.nil != null && "},{i:"size"},{v:"(d.tl) === 1 && "},{i:"size"},{v:"(d.tl.nil) === 0?(a = "},{i:"___implementation_ec6de8cf"},{v:"(c,"},{i:"_s42febb4921"},{v:"),(c = a.TyArrow_params)?(b = "},{i:"___extract_values_f2f00d5f"},{v:"(b,c).some) && (c = b.tl) && c.nil?{some:"},{i:"__v6_serialize_f2f00d5f"},{v:"(a.TyArrow_res)("},{i:"___blah"},{v:"(b.hd))}:{none:"},{i:"js_void"},{v:"}:{none:"},{i:"js_void"},{v:"}):{none:"},{i:"js_void"},{v:"}):{none:"},{i:"js_void"},{v:"};}\n"}],r:[false],i:{i:"___skeleton_blah"}},{d:{r:"\"__blah\""},c:[{v:"var "},{i:"___register_blah"},{v:" = "},{i:"___register_f2f00d5f"},{v:"("},{rd:"\"__blah\""},{v:","},{i:"___skeleton_blah"},{v:");\n"}],r:[false],i:{i:"___register_blah"}}]}]},cont(BslCps_topk)));
global.___t = {body:__v245_t_ec6de8cf,quantifier:__v71_t_ec6de8cf};
global.__v1_t = {TyArrow_res:__v12_t_0ceeb04a,TyArrow_params:__v87_t_ec6de8cf};
global.__v2_t = {body:__v1_t,quantifier:__v71_t_ec6de8cf};
function __v3_an(a,b){return function (c){return ___send_to_client_f2f00d5f("__blah",c,a,b);};}
function __v2_an(a,b,c){return function (d){var e,f;return (f = d.TyArrow_params) && (e = f.tl) && e.nil?(e = ccont(c,__v3_an(d.TyArrow_res,c)),___add_args_with_type_f2f00d5f(f.hd,b,___add_var_types_skip_f2f00d5f(a,___empty_request_f2f00d5f),e)):___OpaRPC_error_stub_f2f00d5f("__blah",c);};}
function ___stub_blah(a){return function (b,c){return ___implementation_ec6de8cf({cols:{nil:js_void},rows:{nil:js_void},types:{tl:{nil:js_void},hd:a}},___t,ccont(c,__v2_an(a,b,c)));};}
global.___blah = function ___blah(a){return function (b,c){return ___stub_blah(a)(b,c);};};
___blah.distant = true;
function ___fa_skip(a){return ___blah(__v205_t_5bd07984);}
global.___fa = function ___fa(a,b){return return_tc(b,___fa_skip(a));};
___fa.distant = true;
function __v5_an(a,b){return function (c){return ___send_to_client_f2f00d5f("__fae",c,a,b);};}
function __v4_an(a,b,c){return function (d){var e,f;return (f = d.TyArrow_params) && (e = f.tl) && e.nil?(e = ccont(c,__v5_an(d.TyArrow_res,c)),___add_args_with_type_f2f00d5f(f.hd,b,___add_var_types_skip_f2f00d5f(a,___empty_request_f2f00d5f),e)):___OpaRPC_error_stub_f2f00d5f("__fae",c);};}
function ___stub_fae(a){return function (b,c){return ___implementation_ec6de8cf({cols:{nil:js_void},rows:{nil:js_void},types:{tl:{nil:js_void},hd:a}},__v2_t,ccont(c,__v4_an(a,b,c)));};}
global.___fae = function ___fae(a){return function (b,c){return ___stub_fae(a)(b,c);};};
___fae.distant = true;
function __v10_an(a,b){return function (c){return return_tc(a,{name:b,value:c});};}
function __v6_an(a,b,c,d){return function (e){return return_tc(a,{namespace:d,tag:c,args:b,specific_attributes:e,xmlns:{nil:js_void},content:{tl:{nil:js_void},hd:{text:"\nloading...\n"}}});};}
function __v7_an(a){return function (b){return return_tc(a,{some:b});};}
function __v8_an(a,b,c,d){return function (e){return return_tc(a,{"class":d,style:c,bool_attributes:b,events:e,events_options:{nil:js_void},href:{none:js_void}});};}
function __v9_an(a){return function (b){return return_tc(a,{hd:b,tl:{nil:js_void}});};}
function __v11_an(a){return function (b){return return_tc(a,{value:b});};}
function __v12_an(a){return function (b){return ___serialize_call_0ceeb04a(______fae,{nil:js_void},{tl:{nil:js_void},hd:b},a);};}
global.___page = function ___page(a){return BslNumber_Int_of_string_opt("xyz"),a = ccont(a,__v6_an(a,{tl:{nil:js_void},hd:{value:"content",name:"id",namespace:""}},"div","")),a = ccont(a,__v7_an(a)),a = ccont(a,__v8_an(a,{nil:js_void},{nil:js_void},{nil:js_void})),a = ccont(a,__v9_an(a)),a = ccont(a,__v10_an(a,{ready:js_void})),a = ccont(a,__v11_an(a)),___serialize_argument_0ceeb04a(__v60_t_ec6de8cf)("_v1_page",0,ccont(a,__v12_an(a)));};
___page.distant = true;
var ____do_ = BslCps_topwait(___start_b970f080(___http_b970f080,{page:___page,title:""},cont(BslCps_topk)));
var ___run_services = BslCps_topwait(___run_services_b970f080(cont(BslCps_topk)));

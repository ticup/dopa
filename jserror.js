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
var ___server_ast = BslCps_topwait(___register_server_code_ec6de8cf({package_:"",adhoc_e:[{td:[],rd:[],r:[true],id:["`_v1_Server_private_run_services_stdlib.core.web.server`"],i:{some:"_v1_run_services"},d:js_void,c:{none:js_void}},{td:[],rd:[],r:[false],id:["_v1_fortytwo"],i:{some:"_v1_Test"},d:js_void,c:{some:"__v2_Test"}},{td:[],rd:[],r:[false],id:["__stub_fortytwo"],i:{some:"_v1_fortytwo"},d:js_void,c:{some:"__v2_fortytwo"}},{td:[],rd:["\"__fortytwo\""],r:[false],id:["`_v1_OpaRPC_Server_send_to_client_stdlib.core.rpc.core`"],i:{some:"__stub_fortytwo"},d:js_void,c:{none:js_void}}]},cont(BslCps_topk)));
var ___register_js_ast = BslCps_topwait(___register_js_code_ec6de8cf({ast:[{plugin:"0_BundledPlugin",ast:[{d:js_void,c:[{v:"\n"}],r:[true],i:{i:"___comment"}},{d:js_void,c:[{v:"function "},{i:"fortytwo"},{v:"(){return 42;}\n"}],r:[false],i:{i:"fortytwo"}}]},{ast:[{d:js_void,c:[{v:""},{s:["___fortytwo"]},{v:";\n"}],r:[true],i:{i:"___toplevel_statement"}},{d:js_void,c:[{v:"function "},{i:"___fortytwo"},{v:"(){return "},{i:"test_fortytwo"},{v:"();}\n"}],r:[false],i:{i:"___fortytwo"}},{d:js_void,c:[{v:"var "},{i:"___Test"},{v:" = {fortytwo:"},{i:"___fortytwo"},{v:"};\n"}],r:[false],i:{i:"___Test"}},{d:js_void,c:[{v:"function "},{i:"___skeleton_fortytwo"},{v:"(a){var b,f,e,d,c;return (b = "},{i:"__v8_unserialize_f2f00d5f"},{v:"(a).some)?(c = "},{i:"___extract_types_f2f00d5f"},{v:"(b),(d = c.types,d != null) && (e = c.rows,e != null) && (a = c.cols,a != null) && "},{i:"size"},{v:"(c) === 3 && (f = a.nil,f != null) && "},{i:"size"},{v:"(a) === 1 && "},{i:"size"},{v:"(f) === 0 && e.nil != null && "},{i:"size"},{v:"(e) === 1 && "},{i:"size"},{v:"(e.nil) === 0 && d.nil != null && "},{i:"size"},{v:"(d) === 1 && "},{i:"size"},{v:"(d.nil) === 0?(f = "},{i:"___implementation_ec6de8cf"},{v:"(c,"},{i:"_sb7894df5b0"},{v:"),(a = f.TyArrow_params)?(a = "},{i:"___extract_values_f2f00d5f"},{v:"(b,a).some) && a.nil?{some:"},{i:"__v6_serialize_f2f00d5f"},{v:"(f.TyArrow_res)("},{i:"test_fortytwo"},{v:"())}:{none:"},{i:"js_void"},{v:"}:{none:"},{i:"js_void"},{v:"}):{none:"},{i:"js_void"},{v:"}):{none:"},{i:"js_void"},{v:"};}\n"}],r:[false],i:{i:"___skeleton_fortytwo"}},{d:{r:"\"__fortytwo\""},c:[{v:"var "},{i:"___register_fortytwo"},{v:" = "},{i:"___register_f2f00d5f"},{v:"("},{rd:"\"__fortytwo\""},{v:","},{i:"___skeleton_fortytwo"},{v:");\n"}],r:[false],i:{i:"___register_fortytwo"}}]}]},cont(BslCps_topk)));
function ___an(a){return function (b){var c;return (c = b.TyArrow_params) && c.nil?___send_to_client_f2f00d5f("__fortytwo",___empty_request_f2f00d5f,b.TyArrow_res,a):___OpaRPC_error_stub_f2f00d5f("__fortytwo",a);};}
global.___stub_fortytwo = function ___stub_fortytwo(a){return ___implementation_ec6de8cf({cols:{nil:js_void},rows:{nil:js_void},types:{nil:js_void}},__v193_t_f2f00d5f,ccont(a,___an(a)));};
global.___fortytwo = function ___fortytwo(a){return ___stub_fortytwo(a);};
___fortytwo.distant = true;
global.___Test = {fortytwo:___fortytwo};
var ___run_services = BslCps_topwait(___run_services_b970f080(cont(BslCps_topk)));


import QtQuick 1.1
import "script"
import "script/ajaxmee.js"    as Ajaxmee
import "script/array2json.js" as ArrayToJson
import "script/storage.js"    as Storage

Rectangle {
    id: container
    width: 854; height: 480
    color: "#222222"

    Text {
	id: cfgURL
	visible: false
	text: ""
    }
    Text {
	id: cfgPassword
	visible: false
	text: ""
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
	id: config
	width: 854; height: 480
	visible: false
	color: "#aaaaaa"
	opacity: 1
	z: 100

	Column {
	    spacing: 15
            anchors.horizontalCenter: parent.horizontalCenter
	    Grid {
		columns: 2
		spacing: 10
		Text { 
		    text: "Server" 
		    font.pixelSize: 30
		    horizontalAlignment: Text.AlignRight
		}
		TextInput { 
		    id: c_host
		    text: "http://" 
		    font.pixelSize: 30
		}
		Text { 
		    text: "Password" 
		    font.pixelSize: 30
		    horizontalAlignment: Text.AlignRight
		}
		TextInput { 
		    id: c_pass
		    text: "http://" 
		    font.pixelSize: 30
		}
	    }
            TextButton {
                anchors.horizontalCenter: parent.horizontalCenter
		width: 200
		height: 40
		text: "Done"
		onClicked: { 
		    config.visible = false; 
		    Storage.setSetting( "host",     c_host.text );
		    Storage.setSetting( "password", c_pass.text );
		    cfgURL.text      = c_host.text;
		    cfgPassword.text = c_pass.text;
		}
	    }
	}
    }

    // The model:
    ListModel {
        id: torrentModel

        // ListElement {
        //     name: "Debian.iso"; cost: 2.45; total_seeds: 145; total_peers: 22; total_size: 43284423423;
	//     download_payload_rate : 40000;
	//     progress: 79.4; eta: 3700; state: "Paused"; objstate: "Paused"; objid: "fdsfdsfds";
        //     attributes: [
        //         ListElement { description: "Free and Open Source" },
        //         ListElement { description: "Joy for all" }
        //     ]
        // }
    }

    // The delegate for each fruit in the model:
    Component {
        id: listDelegate
        
        Item {
            id: delegateItem
            width: listView.width; height: 72
            clip: true

            Row {
		id: r
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Image {
		    width: 64; height: 64;
		    id: pauseplay
                    source: iconPlayPause( objstate )
                    MouseArea { anchors.fill: parent; onClicked: togglePlayPause( index ) }
                }

                Column {
		    id: col
                    anchors.verticalCenter: parent.verticalCenter

                    Text { 
                        text: name
                        font.pixelSize: 22
                        color: "white"
                    }

		    ProgressBar {
			id: bar
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: parent.left
			height: 24
			width: 500
			minimum: 0
			maximum: 100
			color: "#333333"
			secondColor: "#444444"
			value: progress
		    }

                    Row {
			anchors.top: bar.top
                        spacing: 10


			Text { 
			    anchors.left: parent.left
			    anchors.verticalCenter: parent.verticalCenter
			    text: formatsz( total_size )
			    font.pixelSize: 15
			    color: "white"
			}

			Text { 
			    id: seedsText
			    anchors.verticalCenter: parent.verticalCenter
			    text: total_seeds ? total_seeds : " "
			    font.pixelSize: 15
			    color: "white"
			}
			Text { 
			    id: peersText
			    anchors.verticalCenter: parent.verticalCenter
			    text: total_peers ? total_peers : " "
			    font.pixelSize: 15
			    color: "grey"
			}
			Text { 
			    anchors.verticalCenter: parent.verticalCenter
			    text: objstate
			    font.pixelSize: 20
			    color: objstate == "Seeding" ? "yellow" : "white"
			}

                        // Repeater {
                        //     model: attributes
                        //     Text { text: descriptionX; color: "White" }
                        // }
                    }
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 10

                Text { 
                    anchors.verticalCenter: parent.verticalCenter
                    text: download_payload_rate ? formatsz( download_payload_rate ) : "Zzz"
                    font.pixelSize: 22
                    color: "red"
                    font.bold: true
                }

                Text { 
                    anchors.verticalCenter: parent.verticalCenter
                    text: formateta( eta )
                    font.pixelSize: 25
                    color: "red"
                    font.bold: true
                }

                Image {
		    width: 64; height: 64;
                    source: "images/delete.png"
                    MouseArea { anchors.fill:parent; onClicked: removeTorrent(index) }
                }
            }
        }
    }

    // The view:
    ListView {
        id: listView
        anchors.fill: parent; anchors.margins: 20
        model: torrentModel
        delegate: listDelegate
    }

    Row {
        anchors { left: parent.left; bottom: parent.bottom; margins: 20 }
        spacing: 10

        TextButton {
	    height: 30
	    width:  130
	    text: "Config"
	    onClicked: config.visible = true	    
	}
        Text { 
	    id: status
            text: "Starting up..." 
	    color: "#ddddaa"
	}

	Timer {
            interval: 3000; running: true; repeat: true
            onTriggered: timer()
	}
    }

    function timer() {

	var data;

	console.log("cfgURL.text:" + cfgURL.text);
	data = { 'method': 'web.update_ui', 
		 'params' : [["queue","name","total_size","state","progress","num_seeds","total_seeds","num_peers","total_peers","download_payload_rate","upload_payload_rate","eta","ratio","distributed_copies","is_auto_managed","time_added","tracker_host"],{}]  }
	Ajaxmee.ajaxmee('POST', cfgURL.text, data,
		function(data) {
//		    console.log('ok', 'data:' + data)
//		    console.log("starting to loop");
		    var x = JSON.parse(data);
		    updateModel( torrentModel, x["result"]["torrents"] );
		    status.text = "Updated at:" + Date().toString();
		},
		function(status, statusText) {
		    console.log('error', status, statusText)
		})
	
    }

    function updateModel( model, data ) 
    {
	var existingIndex = 0;
	var existingIndexMax = model.count;
	var id;

 	console.log("==========updateModel()");
	for( id in data ) 
	{
	    var found = false;
	    var name = data[ id ];
//	    console.log( "looping... existingIndex:" + existingIndex + " id:" + id + " name:" + name );

	    var col = data[ id ];
	    var k;
	    var row = {};
	    row[ "objid" ] = id;
	    row[ "name" ] = "v";
	    for( k in col ) 
	    {
		if( k == "state" ) {
		    row[ "objstate" ] = col[k];
		}
		else {
		    row[ k ] = col[ k ];
		}
	    }

 	    // find it if it exists...
	    for( ; existingIndex < existingIndexMax; ++existingIndex )
	    {
 		var torrentid = model.get( existingIndex ).objid;
//		console.log( "   .. existingIndex:" + existingIndex + " torrentid:" + torrentid );

		if( torrentid == id )
		{
//		    console.log( "   .. found at existingIndex:" + existingIndex );
		    found = true;
 		    model.set( existingIndex, row );
		    ++existingIndex;
		    break;
		}
		else
		{
		    // This element from the local model no longer exists on the server,
		    // remove it. Do not advance the index as we have removed an element instead.
		    model.remove( existingIndex );
		    --existingIndex;
		}
	    }

	    // it didn't exist, add it as new.
	    if( !found )
	    {
//		console.log( "   .. NOT FOUND, ADDING... torrentid:" + torrentid );
		model.append( row );
	    }
	}
    }


    function updateModelBruteForce( model, data ) 
    {
	torrentModel.clear();

	var id;
	for( id in data ) 
	{
	    console.log( "looping... " + id );
	    var x = data[ id ];
	    console.log( "   name:" + x["name"] );
	    console.log( "   eta:"  + x["eta"] );
	    console.log( "   seeds:"  + x["total_seeds"] );

	    var row = {};
	    row[ "objid" ] = id;
	    var k;
	    for( k in x ) {
		if( k == "state" ) {
		    row[ "objstate" ] = x[k];
		}
		else {
		    row[ k ] = x[ k ];
		}
	    }

	    model.append( row );
	}
    }

    function startupFunction() 
    {
        Storage.initialize();
	c_host.text = Storage.getSetting( "host" );
	c_pass.text = Storage.getSetting( "password" );
	cfgURL.text      = c_host.text;
	cfgPassword.text = c_pass.text;


	status.text = "started"
	var data = { 'method': 'auth.login', 'params' : [ cfgPassword.text ]  }
	Ajaxmee.ajaxmee('POST', cfgURL.text, data,
		function(data) {
		    console.log('ok', 'data:' + data)
		    console.log("---------- CALLING TIMER()...");
//		    timer();
		    timer();
		},
		function(status, statusText) {
		    console.log('error', status, statusText)
		})
    }

    Component.onCompleted: startupFunction();

    function formateta( t ) {
	if( !t ) { 
	    return " ";
	}
	if( t > 3600 ) {
	    var h = t / 3600;
	    return Number( h  ).toFixed(1) + " H";
	}
	if( t > 60 ) {
	    var m = t / 60;
	    return Number( m  ).toFixed(1) + " M";
	}
	return t + " S";
    }
    function formatsz( sz ) {
	if( !sz ) { 
	    return " ";
	}
	if( sz > 1024 * 1024 * 1024 ) {
	    return Number( (sz / (1024 * 1024 * 1024))).toFixed(1) + "g";
	}
	if( sz > 1024 * 1024 ) {
	    return Number( (sz / (1024 * 1024))).toFixed(1) + "m";
	}
	if( sz > 1024 ) {
	    return Number( (sz / 1024)).toFixed(1) + "k";
	}
	return Number( sz ).toFixed(0) + "b";
    }

    function iconPlayPause( state ) {
	console.log("iconPlayPause:" + state);
	if( state == "Paused" || !state ) {
	    return "images/play.png";
	}
	return "images/pause.png";
    }

    function togglePlayPause( x ) {
	
	var c = torrentModel.get(x).objstate;
	var torrentid = torrentModel.get(x).objid;
	console.log( "=========== togglePlayPause() x:" + x + "  c: " + c + " torrentid:" + torrentid );
	if( c == "Paused" || c == ""  || !c ) {
	    c = "Play"; 
	}
	else {
	    c = "Paused";
	}
	console.log( "togglePlayPause x:" + x + "  set-c: " + c );
//	torrentModel.setProperty( x, "objstate", " " )
//	torrentModel.setProperty( x, "objstate", c )


	var data = { 'method': 'auth.login', 'params' : [ cfgPassword.text ]  }
	Ajaxmee.ajaxmee('POST', cfgURL.text, data,
			function(data) {
			    console.log('ok', 'data:' + data)
			},
			function(status, statusText) {
			    console.log('error', status, statusText)
			})

	console.log( "pause torrent:" + torrentid );
	data = { 'method': 'core.pause_torrent', 
		 'params' : [[ torrentid ]] 
	       };
	if( c != "Paused" ) {
	    data["method"] = 'core.resume_torrent';
	}
	Ajaxmee.ajaxmee('POST', cfgURL.text, data,
			function(data) {
			    console.log('ok', 'data:' + data)
			    timer();
			},
			function(status, statusText) {
			    console.log('error', status, statusText)
			})
    }

    function removeTorrent( x ) {
	var c = torrentModel.get(x).objstate;
	var torrentid = torrentModel.get(x).objid;
	console.log( "removeTorrent x:" + x + "  c: " + c );

	var data = { 'method': 'auth.login', 'params' : [ cfgPassword.text ]  }
	Ajaxmee.ajaxmee('POST', cfgURL.text, data,
			function(data) {
			    console.log('ok', 'data:' + data)
			},
			function(status, statusText) {
			    console.log('error', status, statusText)
			})

	data = { 'method': 'core.remove_torrent', 
		 'params' : [ torrentid, false ] 
	       };
	Ajaxmee.ajaxmee('POST', cfgURL.text, data,
			function(data) {
			    console.log('ok', 'data:' + data)
			    timer();
			},
			function(status, statusText) {
			    console.log('error', status, statusText)
			})
    }
}


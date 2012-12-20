LifeLine
========

LifeLine is a utility, written with Adobe Flex, that offers a connection service between web pages where cookies are not an 
appropriate solution.

(Author's Note: My initial need was to offer a way to communicate from a web page to an application running another
web page in a webkit.)

LifeLine offers a way to determine when other LifeLine instances are available through an internal ping, offers
a method to send JSON data and to send shutdown requests.

Setup
-----

LifeLine is designed to be driven via javascript. To set it up, use the swfobject.js library which can be included on your page
from google here:

    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>

The following code segment demonstrates how to initialize a LifeLine instance:

    var swfVersionStr = '11.0.0'; // minimum flash version
    var flashvars = {
      server_name : 'my_lifeline',
      onReady :     'my_ready_function',
      onJsonData :  'my_json_function',
      onShutdown :  'mu_shutdown_function'
    };
    var attributes = {
      id : 'my_lifeline', name : 'my_lifeline'
    };            

    swfobject.embedSWF(
        'lifeline.swf', 'my_flash_div', 
        '1', '1', 
        swfVersionStr, '', 
        flashvars, {}, attributes);
        
    // JavaScript enabled so display the flashContent div in case it is not replaced with a swf object.
    swfobject.createCSS('#my_flash_div', 'display:block;text-align:left;');

    // called when the LifeLine component has completed initialization.
    function my_lifeline(lifeline_name, status) {
      // Do something on initialization.
    }
    
    // Called when other Lifeline instances send data to this one.
    function my_json_function(lifeline_name, json_data) {
      var my_data = parseJSON(json_data);
    }
    
    // Called when other Lifeline instances send a shutdown request.
    // Its up to you to decide how to deal with the message.
    function my_shutdown_function(lifelin_name) {
      
    }
    
Once this has been done, connecting to, and monitoring another LifeLine instance is simple. The following code
shows how to monitor the status of another instance named 'lifeline_remote'.

    ...
    // Connect to another lifeline instance with a 1 second ping
    var lifeline = $('my_lifeline')[0];
    lifeline.connect('lifeline_remote', 1, "on_lifeline_status");
    
    function on_lifeline_status(lifeline_name, status) {
      if (status == 'CONNECTED') {
        // you just connected to lifeline
      }
      else if (status == 'DISCONNECTED') {
        // the remove lifeline instance is no longer available.
      }
    }
  
API
---

Initialization Properties:

* server_name:String optional - makes the component a server that can accept requests from other local LifeLine servers.
* onReady:String optional- a javascript callback to call when the component has been initialized. A JSON object with status and message are passed.
* onJsonData:String optional - a javascript callback to call when other LifeLine servers send it json_data. The originating LifeLine server name and json_data are passed as parameters.
* onShutdown:String optional - a javascript calback to call when other LifeLine servers send it a shutdown notice. The originating LifeLine Server name is passed as a parameter.

Available functions:

* connect(remote_name, status_function_name) - must be called once before making other calls to remote instance. The status function is called
from the server when the connection status of the remote changes.
* send_json(remote_name, json_data) - sends JSON data to the Lifeline server named. Returns JSON data with status and message
* is_connected(remote_name) - returns true if the named remote is connected.
* shutdown(remote_name) - sends a shutdown request to the named remote. Returns success status via JSON data with status and message.

Building
--------

To build Lifeline you need the flex sdk and ant. 1st edit FLEX_HOME in build/build.properties and then type the following commands from
the top level directory.

    > cd build
    > and

Testing
-------
There's a simple test application found in the test directory. I've also included a Rack config to simplify testing it out.

From the command line (assuming you've got Ruby installed)...

    > bundle
    > rackup
    
Then load the following urls into your browser in two windows:

* http://localhost:9292/test/lifeline-remote.html
* http://localhost:9292/test/lifeline-test.html

The remote should spit out its status, then it should spit out some data sent from the other test page.
The test page should spit out its status and report CONNECTION to the remote.

Close the remote page and note that it become DISCONNECTED. Reload the remote page and note that it reports that it is
connected.

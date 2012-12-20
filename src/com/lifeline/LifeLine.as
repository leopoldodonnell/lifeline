package com.lifeline {
  import mx.core.Application;
  import mx.events.FlexEvent;
  import flash.events.StatusEvent;
  import flash.external.ExternalInterface;
  import flash.net.LocalConnection;
  import flash.system.Security;
  
  /**
   * Lifeline provides a life-line that connects multiple instances of 
   * javascripted Flash Components hosted on the same machine together.
   *
   * Each instance can act as a server that other intances can connect to.
   * To do this, set the 'server_name' flash_var which will then start it up.
   *
   * Clients that wish to communicate with a server call the connect method
   * which, if successful, will allow calls to the methods:
   *  * send_json: to send json data to the other server
   *  * is_connected: to query if the server is successfully connected
   *  * shutdown: to send a shutdown request to the other server
   *
   * Once connected javascript clients can get notifications when other servers
   * become connected and disconnected by through the status_callback passed to
   * the connect method.
   *
   * Available flash_vars:
   *  * server_name:String optional - makes the component a server that can accept
   *    requests from other local Lifeline servers.
   *  * onReady:String optional- a javascript callback to call when the component
   *    has been initialized. A JSON object with status and message are passed.
   *  * onJsonData:String optional - a javascript callback to call when other Lifeline
   *    servers send it json_data. The originating Lifeline server name and json_data
   *    are passed as parameters.
   *  * onShutdown:String optional - a javascript calback to call when other Lifeline
   *    servers send it a shutdown notice. The originating Lifeline Server name is
   *    passed as a parameter.
   */
  public class Lifeline extends Application {
    private var local_server : LifelineLocalConnection;
    private var m_is_connected : Boolean = false;
    
    // A collection of connected clients
    private var clients:Object = new Object();
    
    // Javascript initialized members
    private var server_name : String = '';
    private var js_on_json_data : String; // expects client_name and data
    private var js_on_shutdown : String;  // expects client_name
    
    public function Lifeline() {
			addEventListener(FlexEvent.APPLICATION_COMPLETE, main_init);
    }
    
    private function main_init(event:FlexEvent) : void {

      // Process Flashvars.
			var parameters : Object = mx.core.FlexGlobals.topLevelApplication.parameters; 

      var status:String = json_return('OK');

      // is a server_name is provided, start it up.
      if (parameters.hasOwnProperty("server_name")) {    
        status = start_server(parameters.server_name);
      }
      
      // optional callback for json data sent by clients.
      if (parameters.hasOwnProperty("onJsonData")) {
        js_on_json_data = parameters.onJsonData;
      }

      // optional callback for shutdown requests by clients.
      if (parameters.hasOwnProperty("onShutdown")) {
        js_on_shutdown = parameters.onShutdown;
      }
      
      // Initialize methods called from javascript
      ExternalInterface.addCallback("send_json", ext_send_json);
      ExternalInterface.addCallback("connect", ext_connect);
      ExternalInterface.addCallback("shutdown", ext_shutdown);
      ExternalInterface.addCallback("is_connected", ext_is_connected);
      
      // Notify javasccript that the component is ready
			if (parameters.hasOwnProperty("onReady")) {
			  ExternalInterface.call(parameters.onReady, server_name, status);
			}
    }
    
    public function get is_connected() : Boolean { return m_is_connected; }
  
    public function set is_connected(value:Boolean) : void { m_is_connected = value; }
    
    /*
     * Setup the server if a server_name was provided in the flash_vars.
     */
    private function start_server(server_name:String) : String {
      this.server_name = server_name;
      
      local_server = new LifelineLocalConnection();
      local_server.send_json  = this.on_send_json;
      local_server.ping       = this.on_ping;
      local_server.shutdown   = this.on_shutdown;
      Security.allowDomain("*");
      local_server.allowInsecureDomain('*');
      local_server.allowDomain('*');      

      try {
        // add an _ to allow all domains.
        local_server.connect("_" + this.server_name);
        is_connected = true;
      }
      catch (error:ArgumentError) {
        // Already Connected.
        return json_return("ERROR", "Argument Error: the server may already be initialized.");
      }
      catch (error:TypeError) {
        return json_return("ERROR", "Type Error: the server name may be bad");
      }
      return json_return("OK", "Server started for: " + this.server_name);
    }
    
    // -- Calls from java
    
    /*
     * Connect to another Lifeline server via javascript
     *
     * client_name: the name of the server
     * ping_frequency: the number of seconds between pings to the named server
     * status_callback: the name of a javascript callback to call with connection status
     *  changes. The callback will be sent the server name and the status ("CONNECTED", "DISCONNECTED")
     */
    private function ext_connect(client_name:String, ping_frequency:Number, status_callback:String) : void {
      var client:LifelineClient = new LifelineClient(client_name, ping_frequency, status_callback);
      clients[client_name] = client;
      client.start();
    }
    
    /*
     * Determine if a LiveLine server is connected via javacript
     */
    private function ext_is_connected(client_name:String) : Boolean {
      var client:LifelineClient = clients[client_name];
      return client ? client.is_connected : false;
    }

    /*
     * Send JSON data to another Lifeline server via javascript.
     */
    private function ext_send_json(client_name:String, json_data:String) : String {
      var client:LifelineClient = clients[client_name];
      if (client)  {
        client.send_json(json_data);
        return json_return("OK");
      }
      return json_client_error(client_name);
    }
    
    /*
     * Send a shutdown notice to another Lifeline server via javascript.
     * No policy is enforced, it is up to implementers to decide what to
     * once the message has been sent.
     */
    private function ext_shutdown(client_name:String) : String {
      var client:LifelineClient = clients[client_name];
      if (client) {
        client.shutdown();
        return json_return("OK");
      }
      return json_client_error(client_name);
    }

    // -- Calls from other clients
    
    /*
     * Handle SJON data from other Lifeline servers.
     */
    public function on_send_json(client_name:String, json_string:String) : void {
      if (js_on_json_data) ExternalInterface.call(js_on_json_data, client_name, json_string);
    }
    
    /*
     * Provide a ping to determine if this server is alive.
     */
    public function on_ping() : void {
      // Nothing to do
    }
    
    /*
     * Notify javascript of a shutdown request.
     */
    public function on_shutdown(client_name:String) : void {
      if (is_connected && js_on_shutdown) ExternalInterface.call(js_on_shutdown, client_name);      
    }
  }  
}

internal function json_return(status:String, message:String = '') : String {
  return '{status: \""' + status + '\", message: \"' + message + '\"}'
}

internal function json_client_error(client_name:String) : String {
  return json_return("ERROR", "Lifeline didn't find client: " + client_name + 
                      " Try calling the connect method first.");
}


internal dynamic class LifelineLocalConnection extends flash.net.LocalConnection {}

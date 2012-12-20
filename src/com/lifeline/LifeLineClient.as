
package com.lifeline {
  import flash.utils.Timer;
  import flash.events.TimerEvent;
  import flash.events.StatusEvent;
  import flash.external.ExternalInterface;
  import flash.net.LocalConnection;

  /**
   * The LifelineClient is the interface to other Lifeline servers that
   * may or may not be running. This class manages the LocalConnection and
   * provides the interface to calls that can be made to other Lifeline
   * servers.
   */
  public class LifelineClient {
    private var client_name:String;
    private var client_server:LocalConnection;
    private var status_callback:String;
    private var m_is_connected:Boolean = false;
    private var ping_timer:Timer = new Timer(1000, 0);

    public function LifelineClient(client_name:String, ping_frequency:Number, status_callback:String) {
      this.client_name = client_name;
      this.status_callback = status_callback;
      client_server = new LocalConnection();
      client_server.addEventListener(StatusEvent.STATUS, on_client_status);
      ping_timer.delay = ping_frequency * 1000;
      ping_timer.addEventListener(TimerEvent.TIMER, on_timer_event);
    }
  
    public function get is_connected() : Boolean { return m_is_connected; }
  
    public function set is_connected(value:Boolean) : void { m_is_connected = value; }
  
    public function start() : void {
      client_server.send("_"+client_name, 'ping');
      ping_timer.start(); 
    }

    public function send_json(json_data:String) : void { client_server.send("_"+client_name, 'send_json', client_name, json_data); }
  
    public function shutdown() : void {
      client_server.send("_"+client_name, 'shutdown', client_name);
    }
  
    /*
     * Handle status results from attempts to send messages to the server represented
     * by this instance.
     */
    private function on_client_status(event:StatusEvent) : void {
      switch (event.level) {
        case "status":
          if (is_connected == false) {
            ExternalInterface.call(status_callback, client_name, "CONNECTED");
            is_connected = true;
          }
          break;
        case "error":
          // send failed
          if (is_connected) {
            ExternalInterface.call(status_callback, client_name, "DISCONNECTED");
            is_connected = false;
          }
          break;
        default:
          ExternalInterface.call(status_callback, client_name, "DISCONNECTED");
          break;
      }    
    }

    /*
     * Keep pinging the server regardless of connection status.
     */
    private function on_timer_event(e:TimerEvent) : void {
      client_server.send("_"+client_name, 'ping');
    }
  }
}
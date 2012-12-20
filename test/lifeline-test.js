
var lifeline_factory = function(args) {
  var swfVersionStr = "11.0.0";
  var xiSwfUrlStr = "";
  var params = {};
  var flashvars = {
    server_name : args.server_name,
    onReady : args.on_ready,
    onJsonData : args.on_data     
  };
  var attributes = {
    id : args.server_name, name : args.server_name
  };            

  swfobject.embedSWF(
      "../bin/lifeline.swf", args.flash_div, 
      "10", "10", 
      swfVersionStr, xiSwfUrlStr, 
      flashvars, params, attributes);
  // JavaScript enabled so display the flashContent div in case it is not replaced with a swf object.
  swfobject.createCSS("#"+args.flash_div, "display:block;text-align:left;");
  
  return $("#"+args.server_name)[0]
}

var llprint = function(str) {
  $('#lifeline-output').append('<li>'+str+'</li>');
}

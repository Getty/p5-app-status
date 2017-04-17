
function AppStatus(ws_url) {
  var self = this;
  self.ws_url = 'ws://' + window.location.hostname + ":" + ( parseInt(window.location.port) + 1 ) + "/";
  self.ws_connected = false;
  self.connect_socket();
}

AppStatus.prototype.s = function(data) {
  this.ws.send(JSON.stringify(data));
};

AppStatus.prototype.connect_socket = function(){
  var self = this;
  var ws = new ReconnectingWebSocket(self.ws_url);
  ws.onopen = function(evt){
    $('#app-status-not-connected').hide();
  };
  ws.onmessage = function (evt) {
    var json_data = evt.data;
    var data = JSON.parse(json_data);
    console.log('message',data);
  };
  ws.onerror = function(evt) {
    if (self.ws_connected) {
      self.ws.close();
    } else {
      $('#app-status-not-connected').show();
    }
  };
  ws.onclose = function(evt) {
    $('#app-status-not-connected').show();
  };
  self.ws = ws;
};

var app_status;

$(function(){

  app_status = new AppStatus();

});

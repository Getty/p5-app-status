
function AppStatusDashboard() {
  var self = this;
  self.ws_url = 'ws://' + window.location.hostname + ":" + ( parseInt(window.location.port) + 1 ) + "/";
  self.ws_connected = false;
  self.locale = 'de';
  self.time_format = 'dddd, MMMM Do YYYY, hh:mm:ss';
  self.reddit_filter = [
    'aww','funny','nba','interestingasfuck','overwatch','oldschoolcool',
    'blackpeopletwitter','sports','hockey','pokemongo','baseball',
    'mildlyinteresting','wholesomememes','thisismylifenow','leagueoflegends',
    'bikinibottomtwitter','adviceanimals','the_donald','youdontsurf',
    'wtf','woahdude','kenm','gifrecipes','perfecttiming','tinder','music',
    'nonononoyes','pokemon','standupshots','pandr','shittyfoodporn',
    'bettereveryloop','pics','gifs','peoplefuckingdying','leafs',
    'natureismetal','oddlysatisfying','earthporn','unexpected'
  ];
  self.reddit_highlight = [
    'news','politics','europe','worldnews','esist','enoughtrumpspam',
    'starwars','videos','marchagainsttrump'
  ];

  moment.locale(self.locale);

  self.connect_socket();
  self.update_clock();
  $('.ping').each(function(){
    self.start_ping($(this).data('url'),$(this).find('.pingresult'));
  });
  self.check_rss();
}

AppStatusDashboard.prototype.check_rss = function(url,pingresult) {
  var self = this;
  $.get('https://www.reddit.com/r/all/.rss?limit=200', function (data) {
    $('#custom').empty();
    $(data).find("entry").each(function () { // or "item" or whatever suits your feed
      var el = $(this);
      var sub = el.find("category").attr('term');
      if ($.inArray(sub.toLowerCase(),self.reddit_filter) < 0) {
        var div = $('<div class="bigfont"><span style="color:#adff2f">[' + sub + ']</span> ' + el.find("title").text() + '</div>');
        if ($.inArray(sub.toLowerCase(),self.reddit_highlight) >= 0) {
          div.css('color','yellow');
        }
        $('#custom').append(div);
      }
    });
  });
  setTimeout(function(){
    self.check_rss();
  }, 60 * 1000);
};

AppStatusDashboard.prototype.start_ping = function(url,pingresult) {
  var self = this;
  setTimeout(function(){
    ping(url).then(function(delta) {
      if (delta > 3) {
        if (delta > 500) {
          pingresult.html('<span style="color:yellow">' + delta + '</span>');
        } else {
          pingresult.text(delta);
        }
      }
      self.start_ping(url,pingresult);
    }).catch(function(error) {
      pingresult.html('<span style="color:red">ERROR</span>');
      self.start_ping(url,pingresult);
    });
  }, 5 * 1000);
};

AppStatusDashboard.prototype.update_clock = function() {
  var self = this;
  $('#clock').text(moment().format(self.time_format));
  setTimeout(function(){
    self.update_clock();
  }, 1000);
};

AppStatusDashboard.prototype.s = function(data) {
  this.ws.send(JSON.stringify(data));
};

AppStatusDashboard.prototype.disconnected = function(data) {
  self.ws_connected = false;
  $('#disconnected').show();
};

AppStatusDashboard.prototype.connected = function(data) {
  self.ws_connected = true;
  $('#disconnected').hide();
};

AppStatusDashboard.prototype.connect_socket = function(){
  var self = this;
  var ws = new ReconnectingWebSocket(self.ws_url);
  ws.onopen = function(evt){
    self.connected();
  };
  ws.onmessage = function (evt) {
    var json_data = evt.data;
    var data = JSON.parse(json_data);
  };
  ws.onerror = function(evt) {
    if (self.ws_connected) {
      self.ws.close();
    } else {
      self.disconnected();
    }
  };
  ws.onclose = function(evt) {
    self.disconnected();
  };
  self.ws = ws;
};

var app_status;

$(function(){

  app_status = new AppStatusDashboard();

});

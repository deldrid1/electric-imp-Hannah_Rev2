var http    = require('http'),
	express = require("express"),
    app     = express(),
    server  = http.createServer(app),
    //io      = require('socket.io').listen(server),
	os      = require('os'),
    port    = parseInt(process.env.PORT, 10) || 4567;
    
app.configure(function(){
  app.use(express.methodOverride());
  app.use(express.bodyParser());
  app.use(express.logger('short'));	//'short', 'tiny', 'dev', 'default' or custom using Connect Tokens
  app.use(express.static(__dirname));
  app.use(express.errorHandler({
    dumpExceptions: true, 
    showStack: true
  }));
  app.use(app.router);
});

/*io.configure(function () {
    io.set('authorization', function (handshakeData, callback) {
        if (handshakeData.xdomain) {
            callback('Cross-domain connections are not allowed');
        } else {
            callback(null, true);
        }
    });
});*/

//Redirect Naked Domain
app.get("/", function(req, res) {
  res.redirect("/index.html");
});

//The 404 Route (ALWAYS Keep this as the last route)
app.get('*', function(req, res){
  res.send('404 NOT FOUND', 404);
});

//Start the Server
server.listen(port);

//Get our IP Address
var interfaces = os.networkInterfaces();
var addresses = [];
for (k in interfaces) {
    for (k2 in interfaces[k]) {
        var address = interfaces[k][k2];
        if (address.family == 'IPv4' && !address.internal) {
            addresses.push(address.address)
        }
    }
}

//Log to let everyone know we are up and running
console.log("\nStatic file server running for folder '" + __dirname + "' at\n\nhttp://localhost:" + port + "/ (OR Local Network IP Addresses: " + addresses + ")\n\nCTRL + C to shutdown");
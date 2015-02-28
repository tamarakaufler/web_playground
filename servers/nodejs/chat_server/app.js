// nodejs chat server
//      uses socket.io and express packages
//      port is customizable

var app  = require('express')();
var http = require('http').Server(app);
var io   = require('socket.io')(http);

var port = 8001;

var client = {},
    index  = 0
;

app.get('/', function(req, res){
    res.sendFile(__dirname + '/index.html');
});

// event handlers
io.on('connect', function(socket) {

    // give the client a friendly nickname
    // and store
    var nickname = 'Friend ' + ++index; 
    client[socket.client.id] = nickname;

    // post a message to the just connected client
    socket.emit('chat', "<< I am " + nickname + ' >>');
    // post a message to all other clients
    socket.broadcast.emit('chat', client[socket.client.id] + ' connected');
    // post a message to everyone about the number of connected clients
    io.emit('chat', "<< There are now " + (client_count(client)) + ' friends connected >>');

    //io.of('/').clients(function(error, clients){
    //    if (error) throw error;
    //    console.log(clients); // => [PZDoMHjiu8PYfRiKAAAF, Anw2LatarvGVVXEIAAAD]
    //});

    socket.on('chat', function(msg) {
        socket.emit('chat', "I just said: " + msg);
        socket.broadcast.emit('chat', '[' + client[socket.client.id]+ '] ' + msg);

    }).on('disconnect', function() {
        socket.broadcast.emit('chat', "Bye everyone from " + client[socket.client.id]);
        delete client[socket.client.id];
        socket.broadcast.emit('chat', "Only " + (client_count(client)) + ' friend(s) left');
    });
});

http.listen(port, function() {
    console.log('listening on *:' + port);
});

// -------------------------------- FUNCTIONS --------------------------------

function client_count (client) {
    var count = Object.keys(client).length || 0;

    // 
    return (count<2) ? 0 : (count-2);
}


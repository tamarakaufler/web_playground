Various implementations of different types of servers

Perl:

chat_server.pl:
    TCP server
    Event-driven implementation, using only non-blocking modules

    server:     perl chat_server.pl
    clients:    in terminals:    telnet 127.0.0.1 8888
                                 send message in either way:
                                        a) message<ENTER>
                                        b)  OK<ENTER>
                                            message<ENTER>

                                        method b) shows how to approach implementing
                                        a custom protocol

nodejs:

chat_server/app.js:
    Web socket
    server and client socket.io, express modules
    
    server:     cd chat_server
                nodejs app.js
    clients:    in browser:     in several tabs:    http://localhost:8000/
                                                    enter message in one tab and see the message
                                                    broadcast in the others




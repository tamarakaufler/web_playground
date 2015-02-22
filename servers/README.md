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




#!/bin/bash

LOGFILESYSLOG=/var/log/syslog
if [ -f "$LOGFILESYSLOG" ]; then
    echo "" > $LOGFILESYSLOG
fi

LOGFILESYSLOG1=/var/log/syslog.1
if [ -f "$LOGFILESYSLOG1" ]; then
    echo "" > $LOGFILESYSLOG1
fi

LOGFILEKERN=/var/log/kern.log
if [ -f "$LOGFILEKERN" ]; then
    echo "" > $LOGFILEKERN
fi

LOGFILEKERN1=/var/log/kern.log.1
if [ -f "$LOGFILEKERN1" ]; then
    echo "" > $LOGFILEKERN1
fi

LOGFILEMSG=/var/log/messages
if [ -f "$LOGFILEMSG" ]; then
    echo "" > $LOGFILEMSG
fi

LOGFILEMSG1=/var/log/messages.1
if [ -f "$LOGFILEMSG1" ]; then
    echo "" > $LOGFILEMSG1
fi

LOGFILEDEBUG=/var/log/debug
if [ -f "$LOGFILEDEBUG" ]; then
    echo "" > $LOGFILEDEBUG
fi

LOGFILEDEBUG1=/var/log/debug.1
if [ -f "$LOGFILEDEBUG1" ]; then
    echo "" > $LOGFILEDEBUG1
fi
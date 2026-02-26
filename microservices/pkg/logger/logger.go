package logger

import (
	"log"
	"os"
)

type Logger struct {
	infoLog  *log.Logger
	errorLog *log.Logger
}

func NewLogger() *Logger {
	return &Logger{
		infoLog:  log.New(os.Stdout, "INFO\t", log.Ldate|log.Ltime),
		errorLog: log.New(os.Stderr, "ERROR\t", log.Ldate|log.Ltime|log.Lshortfile),
	}
}

func (l *Logger) Info(message string) {
	l.infoLog.Println(message)
}

func (l *Logger) Error(message string, err error) {
	if err != nil {
		l.errorLog.Printf("%s: %v", message, err)
	} else {
		l.errorLog.Println(message)
	}
}

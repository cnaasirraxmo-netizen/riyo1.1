package response

type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Error   interface{} `json:"error,omitempty"`
}

func Success(message string, data interface{}) Response {
	return Response{
		Success: true,
		Message: message,
		Data:    data,
		Error:   nil,
	}
}

func Error(message string, err interface{}) Response {
	return Response{
		Success: false,
		Message: message,
		Data:    nil,
		Error:   err,
	}
}

package domain

type Notification struct {
	ID      string `json:"id"`
	UserID  string `json:"user_id"`
	Title   string `json:"title"`
	Message string `json:"message"`
	Type    string `json:"type"` // info, success, warning
}

type NotificationService interface {
	SendPush(userID string, title, message string) error
	SendGlobal(title, message string) error
}

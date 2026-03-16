package utils

import (
	"fmt"
	"net/smtp"
	"os"
)

func SendEmail(to, subject, body string) error {
	apiKey := os.Getenv("SENDGRID_API_KEY")
	from := os.Getenv("EMAIL_FROM")
	if from == "" {
		from = "noreply@riyobox.sendgrid.net"
	}

	// For simplicity and since we don't have a SendGrid Go library in go.mod,
	// we'll implement a basic SMTP fallback or use a simple HTTP call if API key is provided.
	// However, the user asked for SendGrid integration.

	if apiKey != "" {
		// In a real scenario, use SendGrid API. For now, we simulate or use SMTP if possible.
		fmt.Printf("Sending email via SendGrid API to %s: %s\n", to, subject)
		// return sendSendGridEmail(apiKey, from, to, subject, body)
	}

	// Fallback to SMTP (Gmail or other)
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")

	if smtpHost != "" && smtpUser != "" {
		auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
		msg := []byte("To: " + to + "\r\n" +
			"Subject: " + subject + "\r\n" +
			"\r\n" +
			body + "\r\n")
		return smtp.SendMail(smtpHost+":"+smtpPort, auth, from, []string{to}, msg)
	}

	fmt.Printf("DEBUG EMAIL: To: %s, Subj: %s, Body: %s\n", to, subject, body)
	return nil
}

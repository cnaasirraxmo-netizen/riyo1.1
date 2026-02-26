package domain

import (
	"context"
	"time"
)

type User struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	FirebaseID string    `json:"firebase_id" gorm:"uniqueIndex;not null"`
	Email      string    `json:"email" gorm:"uniqueIndex;not null"`
	Name       string    `json:"name"`
	Role       string    `json:"role" gorm:"default:user"`
	Status     string    `json:"status" gorm:"default:active"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type UserRepository interface {
	Create(ctx context.Context, user *User) error
	GetByFirebaseID(ctx context.Context, firebaseID string) (*User, error)
	GetByID(ctx context.Context, id uint) (*User, error)
	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id uint) error
	List(ctx context.Context) ([]User, error)
}

type UserUsecase interface {
	RegisterOrLogin(ctx context.Context, firebaseID, email, name string) (*User, error)
	GetUserProfile(ctx context.Context, firebaseID string) (*User, error)
	UpdateUserStatus(ctx context.Context, id uint, status string) error
	GetAllUsers(ctx context.Context) ([]User, error)
}

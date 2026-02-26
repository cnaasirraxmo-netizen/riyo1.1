package usecase

import (
	"context"
	"errors"
	"github.com/riyo/user-service/internal/domain"
	"gorm.io/gorm"
)

type userUsecase struct {
	userRepo domain.UserRepository
}

func NewUserUsecase(repo domain.UserRepository) domain.UserUsecase {
	return &userUsecase{userRepo: repo}
}

func (u *userUsecase) RegisterOrLogin(ctx context.Context, firebaseID, email, name string) (*domain.User, error) {
	user, err := u.userRepo.GetByFirebaseID(ctx, firebaseID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Create new user
			newUser := &domain.User{
				FirebaseID: firebaseID,
				Email:      email,
				Name:       name,
				Role:       "user",
				Status:     "active",
			}
			err = u.userRepo.Create(ctx, newUser)
			if err != nil {
				return nil, err
			}
			return newUser, nil
		}
		return nil, err
	}

	if user.Status == "suspended" {
		return nil, errors.New("account is suspended")
	}

	return user, nil
}

func (u *userUsecase) GetUserProfile(ctx context.Context, firebaseID string) (*domain.User, error) {
	user, err := u.userRepo.GetByFirebaseID(ctx, firebaseID)
	if err != nil {
		return nil, err
	}
	if user.Status == "suspended" {
		return nil, errors.New("account is suspended")
	}
	return user, nil
}

func (u *userUsecase) UpdateUserStatus(ctx context.Context, id uint, status string) error {
	user, err := u.userRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	user.Status = status
	return u.userRepo.Update(ctx, user)
}

func (u *userUsecase) GetAllUsers(ctx context.Context) ([]domain.User, error) {
	return u.userRepo.List(ctx)
}

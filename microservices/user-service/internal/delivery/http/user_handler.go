package http

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/riyo/pkg/response"
	"github.com/riyo/user-service/internal/domain"
)

type UserHandler struct {
	userUsecase domain.UserUsecase
}

func NewUserHandler(r gin.IRouter, us domain.UserUsecase) {
	handler := &UserHandler{
		userUsecase: us,
	}

	api := r.Group("/v1/users")
	{
		api.POST("/sync", handler.SyncUser)
		api.GET("/profile", handler.GetProfile)
		api.GET("/", handler.GetAllUsers)
	}
}

// ... remaining functions same as before
func (h *UserHandler) SyncUser(c *gin.Context) {
	verifiedUID := c.GetHeader("X-User-ID")

	var input struct {
		FirebaseID string `json:"firebase_id" binding:"required"`
		Email      string `json:"email" binding:"required"`
		Name       string `json:"name"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, response.Error("Invalid input", err.Error()))
		return
	}

	// SECURITY FIX: Prevent Identity Spoofing
	if verifiedUID != "" && input.FirebaseID != verifiedUID {
		c.JSON(http.StatusForbidden, response.Error("Forbidden", "Cannot sync profile for another user"))
		return
	}

	user, err := h.userUsecase.RegisterOrLogin(c.Request.Context(), input.FirebaseID, input.Email, input.Name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, response.Error("Failed to sync user", err.Error()))
		return
	}

	c.JSON(http.StatusOK, response.Success("User synced successfully", user))
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	firebaseID := c.GetHeader("X-User-ID")
	if firebaseID == "" {
		c.JSON(http.StatusUnauthorized, response.Error("Unauthorized", "Missing user ID"))
		return
	}

	user, err := h.userUsecase.GetUserProfile(c.Request.Context(), firebaseID)
	if err != nil {
		c.JSON(http.StatusNotFound, response.Error("User not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, response.Success("Profile retrieved", user))
}

func (h *UserHandler) GetAllUsers(c *gin.Context) {
	requestorUID := c.GetHeader("X-User-ID")
	if requestorUID == "" {
		c.JSON(http.StatusUnauthorized, response.Error("Unauthorized", "Missing user ID"))
		return
	}

	// SECURITY FIX: Implement RBAC
	user, err := h.userUsecase.GetUserProfile(c.Request.Context(), requestorUID)
	if err != nil || user.Role != "admin" {
		c.JSON(http.StatusForbidden, response.Error("Forbidden", "Admin access required"))
		return
	}

	users, err := h.userUsecase.GetAllUsers(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, response.Error("Failed to fetch users", err.Error()))
		return
	}

	c.JSON(http.StatusOK, response.Success("Users retrieved", users))
}

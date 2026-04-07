package middleware

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	supabase "github.com/supabase-community/supabase-go"
)

type contextKey string

const (
	UserIDKey   contextKey = "user_id"
	UserRoleKey contextKey = "user_role"
)

// supabaseUser represents the user object returned by Supabase Auth
type supabaseUser struct {
	ID string `json:"id"`
}

// AuthMiddleware validates the JWT token via Supabase Auth
func AuthMiddleware(supabaseURL, serviceKey string) func(http.Handler) http.Handler {
	// Create a single service-key client for DB lookups
	dbClient, _ := supabase.NewClient(supabaseURL, serviceKey, &supabase.ClientOptions{})

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				writeError(w, http.StatusUnauthorized, "Missing authorization header")
				return
			}

			token := strings.TrimPrefix(authHeader, "Bearer ")
			if token == authHeader {
				writeError(w, http.StatusUnauthorized, "Invalid authorization format")
				return
			}

			// Validate the token by calling Supabase Auth directly
			req, err := http.NewRequest("GET", supabaseURL+"/auth/v1/user", nil)
			if err != nil {
				writeError(w, http.StatusInternalServerError, "Internal error")
				return
			}
			req.Header.Set("Authorization", "Bearer "+token)
			req.Header.Set("apikey", serviceKey)

			resp, err := http.DefaultClient.Do(req)
			if err != nil {
				writeError(w, http.StatusUnauthorized, "Failed to validate token")
				return
			}
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				writeError(w, http.StatusUnauthorized, "Invalid or expired token")
				return
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				writeError(w, http.StatusInternalServerError, "Failed to read auth response")
				return
			}

			var user supabaseUser
			if err := json.Unmarshal(body, &user); err != nil || user.ID == "" {
				writeError(w, http.StatusUnauthorized, "Invalid token payload")
				return
			}

			userID := user.ID

			// Get user profile to determine role using the service key client
			data, _, err := dbClient.From("users").Select("role", "exact", false).Eq("id", userID).Execute()
			if err != nil {
				writeError(w, http.StatusUnauthorized, "User profile not found")
				return
			}

			var profiles []struct {
				Role string `json:"role"`
			}
			if err := json.Unmarshal(data, &profiles); err != nil || len(profiles) == 0 {
				writeError(w, http.StatusUnauthorized, "User profile not found")
				return
			}

			// Add user info to context
			ctx := context.WithValue(r.Context(), UserIDKey, userID)
			ctx = context.WithValue(ctx, UserRoleKey, profiles[0].Role)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireRole checks that the user has the required role
func RequireRole(role string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userRole, ok := r.Context().Value(UserRoleKey).(string)
			if !ok || userRole != role {
				writeError(w, http.StatusForbidden, "Insufficient permissions")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// GetUserID extracts the user ID from context
func GetUserID(r *http.Request) string {
	if id, ok := r.Context().Value(UserIDKey).(string); ok {
		return id
	}
	return ""
}

// GetUserRole extracts the user role from context
func GetUserRole(r *http.Request) string {
	if role, ok := r.Context().Value(UserRoleKey).(string); ok {
		return role
	}
	return ""
}

func writeError(w http.ResponseWriter, status int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	fmt.Fprintf(w, `{"success":false,"error":"%s"}`, msg)
}


package handlers

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/ergo/backend/internal/middleware"
	"github.com/ergo/backend/internal/models"
	"github.com/ergo/backend/internal/utils"
	"github.com/resend/resend-go/v2"
	storage_go "github.com/supabase-community/storage-go"
	postgrest "github.com/supabase-community/postgrest-go"
	supabase "github.com/supabase-community/supabase-go"
)

type InvitationsHandler struct {
	client *supabase.Client
}

func NewInvitationsHandler(client *supabase.Client) *InvitationsHandler {
	return &InvitationsHandler{client: client}
}

// SendInvite sends an invitation to a tenant for a specific unit
func (h *InvitationsHandler) SendInvite(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	var req models.SendInviteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.UnitID == "" || (req.Email == "" && req.Phone == "") {
		respondError(w, http.StatusBadRequest, "Unit ID and at least email or phone are required")
		return
	}

	// Verify the unit belongs to a building owned by this landlord
	uData, _, err := h.client.From("units").Select("*, buildings!inner(landlord_id, name, address)", "exact", false).Eq("id", req.UnitID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to verify unit")
		return
	}

	var units []struct {
		models.Unit
		Buildings struct {
			LandlordID string `json:"landlord_id"`
			Name       string `json:"name"`
			Address    string `json:"address"`
		} `json:"buildings"`
	}
	json.Unmarshal(uData, &units)

	if len(units) == 0 || units[0].Buildings.LandlordID != userID {
		respondError(w, http.StatusForbidden, "Unit not found or not in your building")
		return
	}

	if units[0].Status == "occupied" {
		respondError(w, http.StatusBadRequest, "Unit is already occupied")
		return
	}

	// 1. Get Landlord Name for the lease
	profData, _, _ := h.client.From("users").Select("full_name", "exact", false).Eq("id", userID).Execute()
	var profiles []struct {
		FullName string `json:"full_name"`
	}
	json.Unmarshal(profData, &profiles)
	landlordName := "Landlord"
	if len(profiles) > 0 {
		landlordName = profiles[0].FullName
	}

	// 2. Prepare Lease Data
	unit := units[0]
	leaseData := utils.LeaseData{
		LandlordName: landlordName,
		TenantName:   req.FullName,
		BuildingName: unit.Buildings.Name, // This needs buildings(name) in select
		Address:      unit.Buildings.Address,
		UnitNumber:   unit.UnitNumber,
		RentAmount:   float64(unit.RentAmount) / 100,
		StartDate:    req.LeaseStart,
		EndDate:      req.LeaseEnd,
	}

	// 3. Generate PDF
	pdfBytes, err := utils.GenerateLeasePDF(leaseData)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to generate lease PDF")
		return
	}

	// 4. Upload to Supabase Storage
	token := generateToken()
	fileName := fmt.Sprintf("leases/%s_%s.pdf", req.UnitID, token[:8])
	contentType := "application/pdf"
	_, err = h.client.Storage.UploadFile("documents", fileName, bytes.NewReader(pdfBytes), storage_go.FileOptions{ContentType: &contentType})
	if err != nil {
		// Log error but proceed with invitation if only storage fails
		fmt.Printf("Storage upload failed: %v\n", err)
	}
	fileURL := h.client.Storage.GetPublicUrl("documents", fileName).SignedURL

	// 5. Create Invitation Record
	invite := map[string]interface{}{
		"unit_id":     req.UnitID,
		"landlord_id": userID,
		"email":       req.Email,
		"phone":       req.Phone,
		"token":       token,
		"status":      "pending",
	}

	data, _, err := h.client.From("invitations").Insert(invite, false, "", "", "").Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create invitation: "+err.Error())
		return
	}

	var created []models.Invitation
	json.Unmarshal(data, &created)

	// 6. Record Document in DB
	doc := map[string]interface{}{
		"uploaded_by": userID,
		"unit_id":     req.UnitID,
		"name":        "Lease Agreement - " + unit.UnitNumber,
		"type":        "lease_agreement",
		"file_url":    fileURL,
		"file_size":   len(pdfBytes),
	}
	h.client.From("documents").Insert(doc, false, "", "", "").Execute()

	// 7. Send Email via Resend
	resendKey := os.Getenv("RESEND_API_KEY")
	if resendKey != "" && req.Email != "" {
		client := resend.NewClient(resendKey)
		inviteLink := fmt.Sprintf("https://ergo-app.vercel.app/invite?token=%s", token)
		
		params := &resend.SendEmailRequest{
			From:    "Ergo <onboarding@resend.dev>", // Or your verified domain
			To:      []string{req.Email},
			Subject: "Invitation to Join Ergo - " + unit.UnitNumber,
			Html:    fmt.Sprintf("<h1>Welcome to your new home!</h1><p>%s has invited you to join Ergo and sign your lease for <strong>%s</strong>.</p><p>Click here to accept: <a href='%s'>Accept Invitation</a></p>", landlordName, unit.UnitNumber, inviteLink),
		}
		client.Emails.Send(params)
	}

	respondJSON(w, http.StatusCreated, models.APIResponse{
		Success: true,
		Data:    created[0],
		Message: "Invitation sent successfully with generated lease",
	})
}

// GetInviteByToken retrieves invitation details for the acceptance page (public)
func (h *InvitationsHandler) GetInviteByToken(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	if token == "" {
		respondError(w, http.StatusBadRequest, "Token is required")
		return
	}

	data, _, err := h.client.From("invitations").Select("*, units(unit_number, rent_amount), buildings:units(buildings(name, address, photo_url))", "exact", false).Eq("token", token).Eq("status", "pending").Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch invitation")
		return
	}

	var invitations []json.RawMessage
	json.Unmarshal(data, &invitations)

	if len(invitations) == 0 {
		respondError(w, http.StatusNotFound, "Invalid or expired invitation")
		return
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    invitations[0],
	})
}

// ListInvitations returns all invitations for a landlord
func (h *InvitationsHandler) ListInvitations(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	data, _, err := h.client.From("invitations").Select("*, units(unit_number, building_id)", "exact", false).Eq("landlord_id", userID).Order("created_at", &postgrest.OrderOpts{Ascending: false}).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch invitations")
		return
	}

	var invitations []json.RawMessage
	json.Unmarshal(data, &invitations)

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    invitations,
	})
}

func generateToken() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

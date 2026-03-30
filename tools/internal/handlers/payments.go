package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/ergo/backend/internal/middleware"
	"github.com/ergo/backend/internal/models"
	"github.com/ergo/backend/internal/utils"
	postgrest "github.com/supabase-community/postgrest-go"
	supabase "github.com/supabase-community/supabase-go"
)

type PaymentsHandler struct {
	client *supabase.Client
}

func NewPaymentsHandler(client *supabase.Client) *PaymentsHandler {
	return &PaymentsHandler{client: client}
}

// InitializePayment starts a Paystack payment for a tenant
func (h *PaymentsHandler) InitializePayment(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	var req models.InitializePaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.UnitID == "" || req.Period == "" {
		respondError(w, http.StatusBadRequest, "Unit ID and period are required")
		return
	}

	// Get unit details (verify tenant owns this unit) and the landlord_id
	data, _, err := h.client.From("units").Select("*, buildings(id, name, landlord_id)", "exact", false).Eq("id", req.UnitID).Eq("tenant_id", userID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch unit")
		return
	}

	var units []struct {
		models.Unit
		Buildings struct {
			ID         string `json:"id"`
			Name       string `json:"name"`
			LandlordID string `json:"landlord_id"`
		} `json:"buildings"`
	}
	json.Unmarshal(data, &units)

	if len(units) == 0 {
		respondError(w, http.StatusNotFound, "Unit not found or not assigned to you")
		return
	}

	unit := units[0]

	// Create a pending payment record
	payment := map[string]interface{}{
		"tenant_id":   userID,
		"unit_id":     req.UnitID,
		"building_id": unit.Buildings.ID,
		"amount":      unit.RentAmount,
		"currency":    "NGN",
		"status":      "pending",
		"period":      req.Period,
	}

	payData, _, err := h.client.From("payments").Insert(payment, false, "", "", "").Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create payment record")
		return
	}

	var payments []models.Payment
	json.Unmarshal(payData, &payments)

	// Fetch the landlord's subaccount code
	landlordData, _, err := h.client.From("profiles").Select("paystack_subaccount_code", "exact", false).Eq("id", unit.Buildings.LandlordID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch landlord profile")
		return
	}

	var landlords []struct {
		PaystackSubaccountCode *string `json:"paystack_subaccount_code"`
	}
	json.Unmarshal(landlordData, &landlords)

	if len(landlords) == 0 || landlords[0].PaystackSubaccountCode == nil {
		respondError(w, http.StatusBadRequest, "Landlord has not set up bank details to receive payments")
		return
	}

	subaccountCode := *landlords[0].PaystackSubaccountCode

	// Fetch tenant email
	tenantData, _, err := h.client.From("profiles").Select("email", "exact", false).Eq("id", userID).Execute()
	var tenants []struct {
		Email string `json:"email"`
	}
	json.Unmarshal(tenantData, &tenants)
	tenantEmail := tenants[0].Email

	authURL, accessCode, err := utils.InitializeSplitPayment(tenantEmail, float64(unit.RentAmount)/100, payments[0].ID, subaccountCode)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to initialize Paystack transaction: "+err.Error())
		return
	}

	respondJSON(w, http.StatusCreated, models.APIResponse{
		Success: true,
		Data: map[string]interface{}{
			"payment":           payments[0],
			"amount_naira":      float64(unit.RentAmount) / 100,
			"authorization_url": authURL,
			"access_code":       accessCode,
			"reference":         payments[0].ID,
		},
		Message: "Payment checkout initiated",
	})
}

// PaystackWebhook handles Paystack payment callbacks
func (h *PaymentsHandler) PaystackWebhook(w http.ResponseWriter, r *http.Request) {
	// TODO: Verify Paystack webhook signature
	// TODO: Parse the event and update the payment status

	var event map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	// Acknowledge receipt immediately (Paystack expects 200)
	w.WriteHeader(http.StatusOK)
}

// SetupBank handles the landlord submitting bank details to create a Paystack Subaccount
func (h *PaymentsHandler) SetupBank(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	var req models.BankSetupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	subaccountCode, err := utils.CreateSubaccount(req.BusinessName, req.BankCode, req.AccountNumber)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create Paystack subaccount: "+err.Error())
		return
	}

	update := map[string]interface{}{
		"paystack_subaccount_code": subaccountCode,
	}

	_, _, err = h.client.From("profiles").Update(update, "", "").Eq("id", userID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to save linked bank account")
		return
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Bank details verified and linked successfully",
		Data: map[string]string{
			"subaccount_code": subaccountCode,
		},
	})
}

// ListPayments returns payment history (scoped by role)
func (h *PaymentsHandler) ListPayments(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	userRole := middleware.GetUserRole(r)

	query := h.client.From("payments").Select("*, profiles!payments_tenant_id_fkey(full_name), buildings(name), units(unit_number)", "exact", false).Order("created_at", &postgrest.OrderOpts{Ascending: false})

	if userRole == "tenant" {
		query = query.Eq("tenant_id", userID)
	} else {
		// Landlord: filter by buildings they own
		// First get their building IDs
		bData, _, _ := h.client.From("buildings").Select("id", "exact", false).Eq("landlord_id", userID).Execute()
		var bIDs []struct {
			ID string `json:"id"`
		}
		json.Unmarshal(bData, &bIDs)

		if len(bIDs) > 0 {
			ids := make([]string, len(bIDs))
			for i, b := range bIDs {
				ids[i] = b.ID
			}
			// Use In filter for building_id
			query = query.In("building_id", ids)
		}
	}

	// Apply optional filters
	if status := r.URL.Query().Get("status"); status != "" {
		query = query.Eq("status", status)
	}
	if buildingID := r.URL.Query().Get("building_id"); buildingID != "" {
		query = query.Eq("building_id", buildingID)
	}

	data, _, err := query.Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch payments")
		return
	}

	var payments []json.RawMessage
	json.Unmarshal(data, &payments)

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    payments,
	})
}

package handlers

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/ergo/backend/internal/middleware"
	"github.com/ergo/backend/internal/models"
	postgrest "github.com/supabase-community/postgrest-go"
	supabase "github.com/supabase-community/supabase-go"
)

type DashboardHandler struct {
	client *supabase.Client
}

func NewDashboardHandler(client *supabase.Client) *DashboardHandler {
	return &DashboardHandler{client: client}
}

// LandlordDashboard returns aggregated stats for the landlord
func (h *DashboardHandler) LandlordDashboard(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	// Get landlord profile
	profData, _, profErr := h.client.From("users").Select("full_name", "exact", false).Eq("id", userID).Execute()
	log.Printf("[DEBUG] Profile query for userID=%s, data=%s, err=%v", userID, string(profData), profErr)
	var profiles []struct {
		FullName string `json:"full_name"`
	}
	json.Unmarshal(profData, &profiles)
	landlordName := "User"
	if len(profiles) > 0 {
		landlordName = profiles[0].FullName
		log.Printf("[DEBUG] Landlord name resolved: %s", landlordName)
	} else {
		log.Printf("[DEBUG] No profile found, using fallback 'User'")
	}

	// Get buildings
	bData, _, _ := h.client.From("buildings").Select("*", "exact", false).Eq("landlord_id", userID).Execute()
	var buildingList []models.Building
	json.Unmarshal(bData, &buildingList)

	buildingIDs := make([]string, len(buildingList))
	for i, b := range buildingList {
		buildingIDs[i] = b.ID
	}

	// Default empty results if no buildings
	if len(buildingIDs) == 0 {
		respondJSON(w, http.StatusOK, models.APIResponse{
			Success: true,
			Data: map[string]interface{}{
				"landlord_name":    landlordName,
				"total_buildings":  0,
				"total_units":      0,
				"occupied_units":   0,
				"total_collected":  0,
				"total_pending":    0,
				"recent_payments":  []interface{}{},
				"pending_payments": []interface{}{},
				"recent_activity":  []interface{}{},
			},
		})
		return
	}

	// Get all units across buildings for stats
	var totalUnits int
	var occupiedUnits int
	uData, _, _ := h.client.From("units").Select("status", "exact", false).In("building_id", buildingIDs).Execute()
	var units []struct {
		Status string `json:"status"`
	}
	json.Unmarshal(uData, &units)
	totalUnits = len(units)
	for _, u := range units {
		if u.Status == "occupied" {
			occupiedUnits++
		}
	}

	// Get payment totals
	var totalCollected int64
	var totalPending int64
	pData, _, _ := h.client.From("payments").Select("amount, status", "exact", false).In("building_id", buildingIDs).Execute()
	var payments []struct {
		Amount int64  `json:"amount"`
		Status string `json:"status"`
	}
	json.Unmarshal(pData, &payments)
	for _, p := range payments {
		if p.Status == "successful" {
			totalCollected += p.Amount
		} else if p.Status == "pending" {
			totalPending += p.Amount
		}
	}

	// Recent Successful Payments (Recent Collections)
	rpData, _, _ := h.client.From("payments").Select("*, users!payments_tenant_id_fkey(full_name), buildings(name), units(unit_number)", "exact", false).In("building_id", buildingIDs).Eq("status", "successful").Order("created_at", &postgrest.OrderOpts{Ascending: false}).Limit(5, "").Execute()
	var recentPayments []json.RawMessage
	json.Unmarshal(rpData, &recentPayments)

	// Actual Pending Payments
	ppData, _, _ := h.client.From("payments").Select("*, users!payments_tenant_id_fkey(full_name), buildings(name), units(unit_number)", "exact", false).In("building_id", buildingIDs).Eq("status", "pending").Order("created_at", &postgrest.OrderOpts{Ascending: false}).Limit(5, "").Execute()
	var pendingPayments []json.RawMessage
	json.Unmarshal(ppData, &pendingPayments)

	// Build recent activity feed
	var recentActivity []map[string]interface{}

	// Activity from payments (last 5)
	var paymentActivity []struct {
		Amount    int64  `json:"amount"`
		Status    string `json:"status"`
		CreatedAt string `json:"created_at"`
		Users     struct {
			FullName string `json:"full_name"`
		} `json:"users"`
		Buildings struct {
			Name string `json:"name"`
		} `json:"buildings"`
	}
	paData, _, _ := h.client.From("payments").Select("amount, status, created_at, users!payments_tenant_id_fkey(full_name), buildings(name)", "exact", false).In("building_id", buildingIDs).Order("created_at", &postgrest.OrderOpts{Ascending: false}).Limit(5, "").Execute()
	json.Unmarshal(paData, &paymentActivity)
	for _, p := range paymentActivity {
		recentActivity = append(recentActivity, map[string]interface{}{
			"type":       "payment",
			"title":      "Rent Payment " + p.Status,
			"subtitle":   p.Users.FullName + " • " + p.Buildings.Name,
			"amount":     p.Amount,
			"status":     p.Status,
			"created_at": p.CreatedAt,
		})
	}

	// Activity from maintenance requests (last 5)
	var maintActivity []struct {
		Title     string `json:"title"`
		Status    string `json:"status"`
		Priority  string `json:"priority"`
		CreatedAt string `json:"created_at"`
		Units     struct {
			UnitNumber string `json:"unit_number"`
		} `json:"units"`
	}
	maData, _, _ := h.client.From("maintenance_requests").Select("title, status, priority, created_at, units(unit_number)", "exact", false).In("building_id", buildingIDs).Order("created_at", &postgrest.OrderOpts{Ascending: false}).Limit(5, "").Execute()
	json.Unmarshal(maData, &maintActivity)
	for _, m := range maintActivity {
		statusLabel := "Submitted"
		if m.Status == "resolved" {
			statusLabel = "Resolved"
		} else if m.Status == "in_progress" {
			statusLabel = "In Progress"
		}
		recentActivity = append(recentActivity, map[string]interface{}{
			"type":       "maintenance",
			"title":      "Maintenance: " + m.Title,
			"subtitle":   "Unit " + m.Units.UnitNumber + " • " + statusLabel,
			"status":     m.Status,
			"created_at": m.CreatedAt,
		})
	}

	// Activity from invitations (last 5)
	var inviteActivity []struct {
		Status    string `json:"status"`
		CreatedAt string `json:"created_at"`
		Email     *string `json:"email"`
		Units     struct {
			UnitNumber string `json:"unit_number"`
		} `json:"units"`
	}
	invData, _, _ := h.client.From("invitations").Select("status, created_at, email, units(unit_number)", "exact", false).Eq("landlord_id", userID).Order("created_at", &postgrest.OrderOpts{Ascending: false}).Limit(5, "").Execute()
	json.Unmarshal(invData, &inviteActivity)
	for _, inv := range inviteActivity {
		title := "Tenant Invitation Sent"
		if inv.Status == "accepted" {
			title = "Lease Agreement Signed"
		}
		subtitle := "Unit " + inv.Units.UnitNumber
		if inv.Email != nil {
			subtitle += " • " + *inv.Email
		}
		recentActivity = append(recentActivity, map[string]interface{}{
			"type":       "invitation",
			"title":      title,
			"subtitle":   subtitle,
			"status":     inv.Status,
			"created_at": inv.CreatedAt,
		})
	}

	// Sort activity by created_at desc
	for i := 0; i < len(recentActivity); i++ {
		for j := i + 1; j < len(recentActivity); j++ {
			ti := recentActivity[i]["created_at"].(string)
			tj := recentActivity[j]["created_at"].(string)
			if ti < tj {
				recentActivity[i], recentActivity[j] = recentActivity[j], recentActivity[i]
			}
		}
	}
	if len(recentActivity) > 10 {
		recentActivity = recentActivity[:10]
	}

	dashboard := map[string]interface{}{
		"landlord_name":    landlordName,
		"total_buildings":  len(buildingIDs),
		"total_units":      totalUnits,
		"occupied_units":   occupiedUnits,
		"total_collected":  totalCollected,
		"total_pending":    totalPending,
		"recent_payments":  recentPayments,
		"pending_payments": pendingPayments,
		"active_buildings": buildingList,
		"recent_activity":  recentActivity,
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    dashboard,
	})
}

// TenantDashboard returns the tenant's unit, building, and payment info
func (h *DashboardHandler) TenantDashboard(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	// Get profile
	profData, _, _ := h.client.From("users").Select("*", "exact", false).Eq("id", userID).Execute()
	var profiles []models.Profile
	json.Unmarshal(profData, &profiles)

	if len(profiles) == 0 {
		respondError(w, http.StatusNotFound, "Profile not found")
		return
	}

	// Get assigned unit
	uData, _, _ := h.client.From("units").Select("*, buildings(*)", "exact", false).Eq("tenant_id", userID).Execute()
	var units []struct {
		models.Unit
		Buildings models.Building `json:"buildings"`
	}
	json.Unmarshal(uData, &units)

	if len(units) == 0 {
		// Tenant has no unit yet
		respondJSON(w, http.StatusOK, models.APIResponse{
			Success: true,
			Data: map[string]interface{}{
				"profile":    profiles[0],
				"unit":       nil,
				"building":   nil,
				"total_paid": 0,
				"message":    "No unit assigned. Accept an invitation to get started.",
			},
		})
		return
	}

	unit := units[0]

	// Get payment history for this unit
	pData, _, _ := h.client.From("payments").Select("*", "exact", false).Eq("tenant_id", userID).Eq("unit_id", unit.ID).Order("created_at", &postgrest.OrderOpts{Ascending: false}).Execute()
	var payments []models.Payment
	json.Unmarshal(pData, &payments)

	var totalPaid int64
	var lastPayment *models.Payment
	for _, p := range payments {
		if p.Status == "successful" {
			totalPaid += p.Amount
		}
	}
	if len(payments) > 0 {
		lastPayment = &payments[0]
	}

	dashboard := map[string]interface{}{
		"profile":      profiles[0],
		"unit":         unit.Unit,
		"building":     unit.Buildings,
		"total_paid":   totalPaid,
		"last_payment": lastPayment,
		"next_amount":  unit.RentAmount,
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    dashboard,
	})
}

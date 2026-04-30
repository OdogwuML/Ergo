package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/ergo/backend/internal/middleware"
	"github.com/ergo/backend/internal/models"
	postgrest "github.com/supabase-community/postgrest-go"
	supabase "github.com/supabase-community/supabase-go"
)

type BuildingsHandler struct {
	client *supabase.Client
}

func NewBuildingsHandler(client *supabase.Client) *BuildingsHandler {
	return &BuildingsHandler{client: client}
}

// ListBuildings returns all buildings for the authenticated landlord
func (h *BuildingsHandler) ListBuildings(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	data, _, err := h.client.From("buildings").Select("*", "exact", false).Eq("landlord_id", userID).Order("created_at", &postgrest.OrderOpts{Ascending: false}).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch buildings")
		return
	}

	var buildings []models.Building
	json.Unmarshal(data, &buildings)

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    buildings,
	})
}

// GetBuilding returns a single building with unit stats
func (h *BuildingsHandler) GetBuilding(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	buildingID := getPathParam(r, "id")

	// Get building
	data, _, err := h.client.From("buildings").Select("*", "exact", false).Eq("id", buildingID).Eq("landlord_id", userID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to fetch building")
		return
	}

	var buildings []models.Building
	json.Unmarshal(data, &buildings)
	if len(buildings) == 0 {
		respondError(w, http.StatusNotFound, "Building not found")
		return
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    buildings[0],
	})
}

// CreateBuilding creates a new building
func (h *BuildingsHandler) CreateBuilding(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	var req models.CreateBuildingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Name == "" || req.Address == "" {
		respondError(w, http.StatusBadRequest, "Name and address are required")
		return
	}

	building := map[string]interface{}{
		"landlord_id":    userID,
		"name":           req.Name,
		"address":        req.Address,
		"total_units":    req.TotalUnits,
		"price_per_unit": req.PricePerUnit,
		"has_pool":       req.HasPool,
		"has_gym":        req.HasGym,
		"has_parking":    req.HasParking,
		"has_cctv":       req.HasCCTV,
	}
	if req.PhotoURL != "" {
		building["photo_url"] = req.PhotoURL
	}

	data, _, err := h.client.From("buildings").Insert(building, false, "", "", "").Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create building: "+err.Error())
		return
	}

	var created []models.Building
	json.Unmarshal(data, &created)

	// Auto-generate units if requested
	if req.TotalUnits > 0 {
		var unitsToInsert []map[string]interface{}
		for i := 1; i <= req.TotalUnits; i++ {
			unitsToInsert = append(unitsToInsert, map[string]interface{}{
				"building_id": created[0].ID,
				"unit_number": fmt.Sprintf("Unit %d", i),
				"rent_amount": req.PricePerUnit,
				"status":      "vacant",
			})
		}
		// Bulk insert (ignore result, we only care that the building was created)
		_, _, err = h.client.From("units").Insert(unitsToInsert, false, "", "", "").Execute()
		if err != nil {
			fmt.Printf("Warning: Failed to auto-generate units for building %s: %v\n", created[0].ID, err)
		}
	}

	respondJSON(w, http.StatusCreated, models.APIResponse{
		Success: true,
		Data:    created[0],
		Message: fmt.Sprintf("Building created successfully with %d units generated", req.TotalUnits),
	})
}

// UpdateBuilding updates a building's details
func (h *BuildingsHandler) UpdateBuilding(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	buildingID := getPathParam(r, "id")

	var req models.UpdateBuildingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	update := map[string]interface{}{}
	if req.Name != nil {
		update["name"] = *req.Name
	}
	if req.Address != nil {
		update["address"] = *req.Address
	}
	if req.TotalUnits != nil {
		update["total_units"] = *req.TotalUnits
	}
	if req.PhotoURL != nil {
		update["photo_url"] = *req.PhotoURL
	}

	if len(update) == 0 {
		respondError(w, http.StatusBadRequest, "No fields to update")
		return
	}

	data, _, err := h.client.From("buildings").Update(update, "", "").Eq("id", buildingID).Eq("landlord_id", userID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to update building")
		return
	}

	var updated []models.Building
	json.Unmarshal(data, &updated)

	if len(updated) == 0 {
		respondError(w, http.StatusNotFound, "Building not found")
		return
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    updated[0],
		Message: "Building updated successfully",
	})
}

// ListUnits returns all units for a building
func (h *BuildingsHandler) ListUnits(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)
	buildingID := getPathParam(r, "id")

	// Verify building belongs to this landlord
	bData, _, err := h.client.From("buildings").Select("id", "exact", false).Eq("id", buildingID).Eq("landlord_id", userID).Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to verify building")
		return
	}
	var bCheck []struct {
		ID string `json:"id"`
	}
	json.Unmarshal(bData, &bCheck)
	if len(bCheck) == 0 {
		respondError(w, http.StatusNotFound, "Building not found")
		return
	}

	// Get units with tenant profiles (aliased to match model)
	data, _, err := h.client.From("units").Select("*, tenant:users!units_tenant_id_fkey(full_name, email, phone)", "exact", false).Eq("building_id", buildingID).Order("unit_number", &postgrest.OrderOpts{Ascending: true}).Execute()
	if err != nil {
		fmt.Printf("[ERROR] ListUnits Postgrest Error for building %s: %v\n", buildingID, err)
		respondError(w, http.StatusInternalServerError, "Failed to fetch units")
		return
	}

	var units []models.UnitWithTenant
	if err := json.Unmarshal(data, &units); err != nil {
		fmt.Printf("[ERROR] Failed to unmarshal units JSON (Building %s): %v\nRaw Data: %s\n", buildingID, err, string(data))
		respondError(w, http.StatusInternalServerError, "Data unmarshaling failed")
		return
	}

	respondJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    units,
	})
}

// CreateUnit creates a new unit in a building
func (h *BuildingsHandler) CreateUnit(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r)

	var req models.CreateUnitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.BuildingID == "" || req.UnitNumber == "" {
		respondError(w, http.StatusBadRequest, "Building ID and unit number are required")
		return
	}

	// Verify building belongs to this landlord
	bData, _, _ := h.client.From("buildings").Select("id", "exact", false).Eq("id", req.BuildingID).Eq("landlord_id", userID).Execute()
	var bCheck []struct {
		ID string `json:"id"`
	}
	json.Unmarshal(bData, &bCheck)
	if len(bCheck) == 0 {
		respondError(w, http.StatusForbidden, "Building not found or not yours")
		return
	}

	unit := map[string]interface{}{
		"building_id": req.BuildingID,
		"unit_number": req.UnitNumber,
		"rent_amount": req.RentAmount,
		"lease_start": req.LeaseStart,
		"lease_end":   req.LeaseEnd,
	}

	data, _, err := h.client.From("units").Insert(unit, false, "", "", "").Execute()
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create unit: "+err.Error())
		return
	}

	var created []models.Unit
	json.Unmarshal(data, &created)

	respondJSON(w, http.StatusCreated, models.APIResponse{
		Success: true,
		Data:    created[0],
		Message: "Unit created successfully",
	})
}

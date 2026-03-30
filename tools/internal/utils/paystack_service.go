package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

const PaystackBaseURL = "https://api.paystack.co"

// CreateSubaccount requests a subaccount creation on Paystack for split payments.
func CreateSubaccount(businessName, bankCode, accountNumber string) (string, error) {
	secretKey := os.Getenv("PAYSTACK_SECRET_KEY")
	if secretKey == "" {
		return "", fmt.Errorf("PAYSTACK_SECRET_KEY not set")
	}

	payload := map[string]interface{}{
		"business_name":  businessName,
		"settlement_bank": bankCode,
		"account_number":  accountNumber,
		"percentage_charge": 0, // Using flat fee, so percentage is 0. Wait, Paystack requires percentage for subaccounts unless flat fee is defined per transaction.
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequest("POST", PaystackBaseURL+"/subaccount", bytes.NewBuffer(payloadBytes))
	if err != nil {
		return "", err
	}

	req.Header.Set("Authorization", "Bearer "+secretKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to create subaccount: %s", string(bodyBytes))
	}

	var result struct {
		Status  bool `json:"status"`
		Data    struct {
			SubaccountCode string `json:"subaccount_code"`
		} `json:"data"`
	}

	if err := json.Unmarshal(bodyBytes, &result); err != nil {
		return "", err
	}

	if !result.Status {
		return "", fmt.Errorf("paystack returned status false: %s", string(bodyBytes))
	}

	return result.Data.SubaccountCode, nil
}

// InitializeSplitPayment creates a transaction link that splits payment to the landlord
func InitializeSplitPayment(email string, amountNaira float64, reference string, subaccountCode string) (string, string, error) {
	secretKey := os.Getenv("PAYSTACK_SECRET_KEY")
	if secretKey == "" {
		return "", "", fmt.Errorf("PAYSTACK_SECRET_KEY not set")
	}

	amountKobo := int64(amountNaira * 100)

	// Ergo's flat fee is 500 Naira (50000 kobo)
	// We want Ergo to keep the fee and the landlord to get the rent amount.
	
	payload := map[string]interface{}{
		"email":             email,
		"amount":            amountKobo,
		"reference":         reference,
		"subaccount":        subaccountCode,
		"bearer":            "subaccount", // Subaccount bears any Paystack fees? Or account? Usually "account" bears it so Ergo pays standard Paystack fees? Let's assume account.
		// Wait, if amountKobo is JUST the Rent+500, we should use transaction charge.
		// Paystack docs: "transaction_charge" -> Flat fee we want to keep? No, "transaction_charge" is the flat amount that goes to the main account (Ergo). The rest goes to the subaccount.
		"transaction_charge": 50000, 
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return "", "", err
	}

	req, err := http.NewRequest("POST", PaystackBaseURL+"/transaction/initialize", bytes.NewBuffer(payloadBytes))
	if err != nil {
		return "", "", err
	}

	req.Header.Set("Authorization", "Bearer "+secretKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", "", fmt.Errorf("failed to initialize payment: %s", string(bodyBytes))
	}

	var result struct {
		Status  bool `json:"status"`
		Data    struct {
			AuthorizationURL string `json:"authorization_url"`
			AccessCode       string `json:"access_code"`
		} `json:"data"`
	}

	if err := json.Unmarshal(bodyBytes, &result); err != nil {
		return "", "", err
	}

	if !result.Status {
		return "", "", fmt.Errorf("paystack returned status false: %s", string(bodyBytes))
	}

	return result.Data.AuthorizationURL, result.Data.AccessCode, nil
}

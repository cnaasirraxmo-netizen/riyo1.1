package response

import "testing"

func TestSuccess(t *testing.T) {
	msg := "test success"
	data := "test data"
	resp := Success(msg, data)

	if !resp.Success {
		t.Errorf("Expected Success to be true")
	}
	if resp.Message != msg {
		t.Errorf("Expected Message to be %s, got %s", msg, resp.Message)
	}
	if resp.Data != data {
		t.Errorf("Expected Data to be %s, got %s", data, resp.Data)
	}
}

func TestError(t *testing.T) {
	msg := "test error"
	err := "something went wrong"
	resp := Error(msg, err)

	if resp.Success {
		t.Errorf("Expected Success to be false")
	}
	if resp.Message != msg {
		t.Errorf("Expected Message to be %s, got %s", msg, resp.Message)
	}
	if resp.Error != err {
		t.Errorf("Expected Error to be %s, got %s", err, resp.Error)
	}
}

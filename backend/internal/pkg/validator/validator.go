package validator

import (
	"fmt"
	"regexp"
)

var (
	// emailRegex はメールアドレスの正規表現
	emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
)

// ValidationError はバリデーションエラー
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// Error はエラーメッセージを返す
func (e ValidationError) Error() string {
	return fmt.Sprintf("%s: %s", e.Field, e.Message)
}

// ValidateEmail はメールアドレスをバリデーションする
func ValidateEmail(email string) error {
	if email == "" {
		return ValidationError{
			Field:   "email",
			Message: "email is required",
		}
	}
	if !emailRegex.MatchString(email) {
		return ValidationError{
			Field:   "email",
			Message: "invalid email format",
		}
	}
	return nil
}

// ValidateRequired は必須項目をバリデーションする
func ValidateRequired(field, value string) error {
	if value == "" {
		return ValidationError{
			Field:   field,
			Message: fmt.Sprintf("%s is required", field),
		}
	}
	return nil
}

// ValidateMaxLength は最大長をバリデーションする
func ValidateMaxLength(field, value string, maxLength int) error {
	if len(value) > maxLength {
		return ValidationError{
			Field:   field,
			Message: fmt.Sprintf("%s must be at most %d characters", field, maxLength),
		}
	}
	return nil
}

// ValidateMinLength は最小長をバリデーションする
func ValidateMinLength(field, value string, minLength int) error {
	if len(value) < minLength {
		return ValidationError{
			Field:   field,
			Message: fmt.Sprintf("%s must be at least %d characters", field, minLength),
		}
	}
	return nil
}

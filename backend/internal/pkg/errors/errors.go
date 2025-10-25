package errors

import (
	"errors"
	"fmt"
)

// エラーコード定義
const (
	CodeInvalidRequest = "INVALID_REQUEST"
	CodeUnauthorized   = "UNAUTHORIZED"
	CodeForbidden      = "FORBIDDEN"
	CodeNotFound       = "NOT_FOUND"
	CodeConflict       = "CONFLICT"
	CodeInternalError  = "INTERNAL_ERROR"
)

// AppError はアプリケーション固有のエラー型
type AppError struct {
	Code    string // エラーコード
	Message string // エラーメッセージ
	Err     error  // 元のエラー
}

// Error は error インターフェースの実装
func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Unwrap は元のエラーを返す
func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError は新しいAppErrorを生成する
func NewAppError(code, message string, err error) *AppError {
	return &AppError{
		Code:    code,
		Message: message,
		Err:     err,
	}
}

// エラー生成ヘルパー関数

// NewInvalidRequestError は不正なリクエストエラーを生成する
func NewInvalidRequestError(message string) *AppError {
	return NewAppError(CodeInvalidRequest, message, nil)
}

// NewUnauthorizedError は認証エラーを生成する
func NewUnauthorizedError(message string) *AppError {
	return NewAppError(CodeUnauthorized, message, nil)
}

// NewForbiddenError は権限エラーを生成する
func NewForbiddenError(message string) *AppError {
	return NewAppError(CodeForbidden, message, nil)
}

// NewNotFoundError はリソース未検出エラーを生成する
func NewNotFoundError(message string) *AppError {
	return NewAppError(CodeNotFound, message, nil)
}

// NewConflictError は競合エラーを生成する
func NewConflictError(message string) *AppError {
	return NewAppError(CodeConflict, message, nil)
}

// NewInternalError は内部エラーを生成する
func NewInternalError(message string, err error) *AppError {
	return NewAppError(CodeInternalError, message, err)
}

// エラー判定ヘルパー関数

// IsAppError は AppError かどうかを判定する
func IsAppError(err error) bool {
	var appErr *AppError
	return errors.As(err, &appErr)
}

// GetAppError は AppError を取得する
func GetAppError(err error) *AppError {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr
	}
	return nil
}

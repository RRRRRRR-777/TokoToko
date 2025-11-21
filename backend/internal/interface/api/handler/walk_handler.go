package handler

import (
	"net/http"

	"github.com/RRRRRRR-777/TekuToko/backend/internal/di"
)

// WalkHandler は散歩APIのハンドラー
type WalkHandler struct {
	container *di.Container
	// TODO: Phase2で追加
	// walkUsecase walk.Usecase
}

// NewWalkHandler は新しいWalkHandlerを生成する
func NewWalkHandler(container *di.Container) *WalkHandler {
	return &WalkHandler{
		container: container,
	}
}

// ListWalks は散歩一覧を取得する
// GET /v1/walks
func (h *WalkHandler) ListWalks(w http.ResponseWriter, r *http.Request) {
	// TODO: Phase2で実装
	// - 認証ユーザーID取得
	// - ページネーションパラメータ取得
	// - Usecase呼び出し
	// - レスポンス返却
	w.WriteHeader(http.StatusNotImplemented)
	w.Write([]byte(`{"message":"Not implemented yet"}`))
}

// GetWalk は散歩詳細を取得する
// GET /v1/walks/:id
func (h *WalkHandler) GetWalk(w http.ResponseWriter, r *http.Request) {
	// TODO: Phase2で実装
	w.WriteHeader(http.StatusNotImplemented)
	w.Write([]byte(`{"message":"Not implemented yet"}`))
}

// CreateWalk は新しい散歩を作成する
// POST /v1/walks
func (h *WalkHandler) CreateWalk(w http.ResponseWriter, r *http.Request) {
	// TODO: Phase2で実装
	w.WriteHeader(http.StatusNotImplemented)
	w.Write([]byte(`{"message":"Not implemented yet"}`))
}

// UpdateWalk は散歩を更新する
// PUT /v1/walks/:id
func (h *WalkHandler) UpdateWalk(w http.ResponseWriter, r *http.Request) {
	// TODO: Phase2で実装
	w.WriteHeader(http.StatusNotImplemented)
	w.Write([]byte(`{"message":"Not implemented yet"}`))
}

// DeleteWalk は散歩を削除する
// DELETE /v1/walks/:id
func (h *WalkHandler) DeleteWalk(w http.ResponseWriter, r *http.Request) {
	// TODO: Phase2で実装
	w.WriteHeader(http.StatusNotImplemented)
	w.Write([]byte(`{"message":"Not implemented yet"}`))
}

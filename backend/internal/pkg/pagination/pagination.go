package pagination

import (
	"net/http"
	"strconv"
)

const (
	// DefaultPage はデフォルトのページ番号
	DefaultPage = 1
	// DefaultLimit はデフォルトの取得件数
	DefaultLimit = 20
	// MaxLimit は最大取得件数
	MaxLimit = 100
)

// Params はページネーションパラメータ
type Params struct {
	Page   int
	Limit  int
	Offset int
}

// ParseParams はHTTPリクエストからページネーションパラメータを取得する
func ParseParams(r *http.Request) Params {
	page := parseIntParam(r, "page", DefaultPage)
	limit := parseIntParam(r, "limit", DefaultLimit)

	// バリデーション
	if page < 1 {
		page = DefaultPage
	}
	if limit < 1 {
		limit = DefaultLimit
	}
	if limit > MaxLimit {
		limit = MaxLimit
	}

	offset := (page - 1) * limit

	return Params{
		Page:   page,
		Limit:  limit,
		Offset: offset,
	}
}

// parseIntParam はクエリパラメータから整数値を取得する
func parseIntParam(r *http.Request, key string, defaultValue int) int {
	value := r.URL.Query().Get(key)
	if value == "" {
		return defaultValue
	}

	intValue, err := strconv.Atoi(value)
	if err != nil {
		return defaultValue
	}

	return intValue
}

// Metadata はページネーションのメタデータ
type Metadata struct {
	Page       int `json:"page"`
	Limit      int `json:"limit"`
	TotalCount int `json:"total_count"`
	TotalPages int `json:"total_pages"`
}

// NewMetadata は新しいメタデータを生成する
func NewMetadata(page, limit, totalCount int) Metadata {
	totalPages := (totalCount + limit - 1) / limit
	return Metadata{
		Page:       page,
		Limit:      limit,
		TotalCount: totalCount,
		TotalPages: totalPages,
	}
}

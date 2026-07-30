// Package cleanup 定義 macOS cleanup domain 的純資料模型。
package cleanup

// Item 是使用者在 preview 與 confirmation 中看到的 cleanup item。
type Item struct {
	ID          string
	Description string
	SizeBytes   int64
	SizeKnown   bool
	Available   bool
}

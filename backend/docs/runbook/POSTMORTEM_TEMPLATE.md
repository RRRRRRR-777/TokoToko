# ポストモーテム: [インシデントタイトル]

**日付**: YYYY-MM-DD
**著者**: [担当者名]
**レビュアー**: [レビュアー名]
**ステータス**: Draft / Review / Final

---

## エグゼクティブサマリー

**概要**（2-3文で簡潔に）:
- 何が起こったか
- いつ起こったか
- 影響範囲
- 復旧までの時間

---

## インシデント詳細

### 発生日時
- **検知**: YYYY-MM-DD HH:MM:SS JST
- **対応開始**: YYYY-MM-DD HH:MM:SS JST
- **復旧**: YYYY-MM-DD HH:MM:SS JST
- **完全解決**: YYYY-MM-DD HH:MM:SS JST

### 影響範囲
- **影響を受けたサービス**: [例: Walk API, ユーザー認証]
- **影響を受けたユーザー数**: [例: 全ユーザー、特定機能ユーザー]
- **影響度**: Critical / High / Medium / Low
- **ダウンタイム**: [例: 15分]
- **データ損失**: あり / なし

### SLO への影響
- **Availability**: [例: 99.5% (目標: 99.9%)]
- **Error Budget 消費**: [例: 30分のダウンタイム = 0.07%]
- **残りError Budget**: [例: 0.03% / 0.1%]

---

## タイムライン

| 時刻 (JST) | イベント | 担当者 | アクション |
|-----------|---------|--------|-----------|
| HH:MM | インシデント発生 | - | デプロイ実行 |
| HH:MM | アラート検知 | Cloud Monitoring | Slackに通知送信 |
| HH:MM | 対応開始 | @engineer1 | アラート受領、調査開始 |
| HH:MM | 原因特定 | @engineer1 | エラーログから原因特定 |
| HH:MM | 対応実施 | @engineer1 | ロールバック開始 |
| HH:MM | 部分復旧 | @engineer1 | Podが正常起動 |
| HH:MM | 完全復旧 | @engineer1 | エラー率正常化確認 |
| HH:MM | インシデントクローズ | @engineer1 | モニタリング継続 |

---

## 根本原因分析（RCA）

### 直接の原因
[技術的な直接原因を詳細に記載]

**例**:
- デプロイしたコードに nil pointer dereference が含まれていた
- データベース接続プールのサイズ設定が不適切だった
- メモリリークによりOOMキルが発生した

### 根本原因
[なぜその問題が発生したかの深掘り分析]

**5 Whys 分析**:
1. **Why**: なぜサービスが停止したか？
   → nil pointer dereference が発生したため

2. **Why**: なぜ nil pointer dereference が発生したか？
   → ユーザーデータが存在しない場合の処理が不十分だったため

3. **Why**: なぜそのコードがリリースされたか？
   → ユニットテストでカバーされていなかったため

4. **Why**: なぜユニットテストでカバーされていなかったか？
   → エッジケースのテストケース追加が漏れていたため

5. **Why**: なぜテストケース追加が漏れたか？
   → コードレビュー時にテストカバレッジの確認が不十分だったため

**根本原因**:
- テストカバレッジの確認プロセスが不十分
- エッジケースのテスト戦略が未整備

---

## 対応内容

### 即座の対応（Mitigation）
1. **ロールバック実施**
   - リビジョン3からリビジョン2にロールバック
   - 実行コマンド: `kubectl rollout undo deployment/tekutoko-api --to-revision=2`

2. **動作確認**
   - ヘルスチェック成功確認
   - エラー率の正常化確認

3. **モニタリング強化**
   - エラーログの継続監視
   - ダッシュボードでの状態確認

### 根本的な修正（Resolution）
1. **コード修正**
   - nil チェック追加
   - エラーハンドリング改善

2. **テスト追加**
   - エッジケースのユニットテスト追加
   - 統合テスト追加

3. **検証**
   - ステージング環境での動作確認
   - 負荷テスト実施

---

## うまくいったこと（Good）

- ✅ アラートが迅速に発火し、5分以内に検知できた
- ✅ Runbook に従ってスムーズにロールバックできた
- ✅ デプロイメントバックアップから簡単に復元できた
- ✅ チーム内のコミュニケーションが円滑だった

---

## 改善が必要なこと（Bad）

- ❌ ステージング環境でのテストが不十分だった
- ❌ デプロイ前のコードレビューでエッジケースが見落とされた
- ❌ カナリアデプロイを実施していなかった
- ❌ アラート検知から対応開始まで10分かかった

---

## 学んだこと（Learned）

- 📚 nil pointer 参照は Go で頻出するエラーパターン
- 📚 エッジケースのテストカバレッジが重要
- 📚 ロールバックは迅速な復旧に有効
- 📚 自動化されたアラートの重要性

---

## アクションアイテム

### 即座対応（1週間以内）
| # | タスク | 担当者 | 期限 | ステータス |
|---|--------|--------|------|-----------|
| 1 | nil チェックの追加 | @engineer1 | YYYY-MM-DD | ✅ Done |
| 2 | エッジケースのテスト追加 | @engineer1 | YYYY-MM-DD | 🔄 In Progress |
| 3 | コードレビューガイドライン更新 | @tech-lead | YYYY-MM-DD | 📝 Todo |

### 短期対応（1ヶ月以内）
| # | タスク | 担当者 | 期限 | ステータス |
|---|--------|--------|------|-----------|
| 4 | カナリアデプロイの導入 | @devops | YYYY-MM-DD | 📝 Todo |
| 5 | テストカバレッジ目標設定（80%以上） | @tech-lead | YYYY-MM-DD | 📝 Todo |
| 6 | 自動E2Eテストの追加 | @qa | YYYY-MM-DD | 📝 Todo |

### 長期対応（3ヶ月以内）
| # | タスク | 担当者 | 期限 | ステータス |
|---|--------|--------|------|-----------|
| 7 | Chaos Engineering 導入 | @sre | YYYY-MM-DD | 📝 Todo |
| 8 | オンコール体制の整備 | @manager | YYYY-MM-DD | 📝 Todo |

---

## 再発防止策

### プロセス改善
1. **コードレビュー強化**
   - エッジケースのテストカバレッジ確認を必須化
   - レビューチェックリストに追加

2. **デプロイプロセス改善**
   - カナリアデプロイの導入（10% → 50% → 100%）
   - ステージング環境での負荷テスト必須化

3. **テスト戦略**
   - テストカバレッジ目標: 80%以上
   - エッジケーステストの自動生成検討

### 技術的改善
1. **静的解析ツール導入**
   - nilチェック漏れの自動検出
   - CI/CDに組み込み

2. **モニタリング強化**
   - エラーパターン別のアラート追加
   - ダッシュボードのカスタマイズ

3. **自動テスト拡充**
   - E2Eテストの追加
   - 契約テスト（Contract Test）の導入

---

## 関連ドキュメント

- [インシデント対応Runbook](./README.md)
- [ロールバック手順](./ROLLBACK.md)
- [GitHub Issue #XXX](https://github.com/RRRRRRR-777/TokoToko/issues/XXX)
- [Slack Thread](https://tekutoko.slack.com/archives/XXX)
- [Cloud Monitoring Incident](https://console.cloud.google.com/monitoring/alerting/incidents/XXX)

---

## メトリクス

### インシデント対応時間
- **MTTD (Mean Time To Detect)**: 5分
- **MTTM (Mean Time To Mitigate)**: 15分
- **MTTR (Mean Time To Resolve)**: 30分
- **MTTF (Mean Time To Fix)**: 2日（完全修正まで）

### ビジネス影響
- **影響ユーザー数**: [例: 100ユーザー]
- **失敗リクエスト数**: [例: 500リクエスト]
- **推定損失**: [例: なし / 軽微]

---

## レビュー履歴

| 日付 | レビュアー | コメント | ステータス |
|------|-----------|---------|-----------|
| YYYY-MM-DD | @tech-lead | 根本原因分析を深掘り | Draft |
| YYYY-MM-DD | @manager | アクションアイテム追加 | Review |
| YYYY-MM-DD | @cto | 承認 | Final |

---

## 付録

### エラーログサンプル
```
[ERROR] 2025-01-16 12:34:56 panic: runtime error: invalid memory address or nil pointer dereference
goroutine 123 [running]:
main.getUserWalks(...)
    /app/handlers/walk.go:45
...
```

### 参考資料
- [Go Nil Pointer Best Practices](https://go.dev/doc/effective_go#nil)
- [Google SRE Book - Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [Atlassian Incident Postmortem Template](https://www.atlassian.com/incident-management/postmortem)

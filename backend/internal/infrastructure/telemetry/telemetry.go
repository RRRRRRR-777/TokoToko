package telemetry

import (
	"context"
	"fmt"
	"os"
	"time"

	mexporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/metric"
	texporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/trace"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/logger"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/metric"
	metricnoop "go.opentelemetry.io/otel/metric/noop"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
	"go.opentelemetry.io/otel/trace"
	tracenoop "go.opentelemetry.io/otel/trace/noop"
	"go.uber.org/zap"
)

// TelemetryProvider はメトリクスとトレースを統合管理するプロバイダー
type TelemetryProvider struct {
	meterProvider  metric.MeterProvider
	tracerProvider trace.TracerProvider
	sdkMeter       *sdkmetric.MeterProvider // シャットダウン用（noopの場合はnil）
	sdkTracer      *sdktrace.TracerProvider // シャットダウン用（noopの場合はnil）
	logger         logger.Logger
	isNoop         bool
}

// hasGCPCredentials はGCP認証情報が利用可能かどうかをチェックする
func hasGCPCredentials() bool {
	// 1. GOOGLE_APPLICATION_CREDENTIALS 環境変数をチェック
	if creds := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"); creds != "" {
		if _, err := os.Stat(creds); err == nil {
			return true
		}
	}

	// 2. Application Default Credentials (ADC) のデフォルトパスをチェック
	// Linux/macOS: ~/.config/gcloud/application_default_credentials.json
	if home, err := os.UserHomeDir(); err == nil {
		adcPath := fmt.Sprintf("%s/.config/gcloud/application_default_credentials.json", home)
		if _, err := os.Stat(adcPath); err == nil {
			return true
		}
	}

	// 3. GCE/Cloud Run等のメタデータサーバーは実行時にしか確認できないため、
	//    ローカル環境では上記のファイルベースのチェックで十分
	return false
}

// shouldUseNoopTelemetry はNoopテレメトリーを使用すべきかを判定する
func shouldUseNoopTelemetry() bool {
	// 1. 環境変数で明示的にnoop指定されている場合
	if os.Getenv("TELEMETRY_NOOP") == "true" {
		return true
	}

	// 2. GCP認証情報がない場合
	return !hasGCPCredentials()
}

// NewTelemetryProvider は新しいテレメトリープロバイダーを作成する
func NewTelemetryProvider(ctx context.Context, projectID, serviceName, environment string, log logger.Logger) (*TelemetryProvider, error) {
	// Noopモードを使用すべき場合
	if shouldUseNoopTelemetry() {
		log.Info("Using noop telemetry provider (local mode)",
			zap.String("service_name", serviceName),
			zap.String("environment", environment),
			zap.Bool("telemetry_noop_env", os.Getenv("TELEMETRY_NOOP") == "true"),
		)

		noopMeter := metricnoop.NewMeterProvider()
		noopTracer := tracenoop.NewTracerProvider()

		otel.SetMeterProvider(noopMeter)
		otel.SetTracerProvider(noopTracer)

		return &TelemetryProvider{
			meterProvider:  noopMeter,
			tracerProvider: noopTracer,
			sdkMeter:       nil,
			sdkTracer:      nil,
			logger:         log,
			isNoop:         true,
		}, nil
	}

	// Resource定義（サービス情報）
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName(serviceName),
			semconv.ServiceVersion("1.0.0"),
			semconv.DeploymentEnvironment(environment),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create resource: %w", err)
	}

	// Cloud Monitoring Exporter作成（メトリクス）
	metricsExporter, err := mexporter.New(
		mexporter.WithProjectID(projectID),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create metrics exporter: %w", err)
	}

	// MeterProvider作成
	meterProvider := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
		sdkmetric.WithReader(
			sdkmetric.NewPeriodicReader(
				metricsExporter,
				sdkmetric.WithInterval(60*time.Second), // 60秒ごとにエクスポート
			),
		),
	)

	// Cloud Trace Exporter作成（トレース）
	traceExporter, err := texporter.New(
		texporter.WithProjectID(projectID),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create trace exporter: %w", err)
	}

	// TracerProvider作成
	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithResource(res),
		sdktrace.WithBatcher(traceExporter),
		// サンプリング設定: 本番環境では10%、開発環境では100%
		sdktrace.WithSampler(getSampler(environment)),
	)

	// グローバルプロバイダーとして設定
	otel.SetMeterProvider(meterProvider)
	otel.SetTracerProvider(tracerProvider)

	log.Info("Telemetry provider initialized with GCP exporters",
		zap.String("project_id", projectID),
		zap.String("service_name", serviceName),
		zap.String("environment", environment),
	)

	return &TelemetryProvider{
		meterProvider:  meterProvider,
		tracerProvider: tracerProvider,
		sdkMeter:       meterProvider,
		sdkTracer:      tracerProvider,
		logger:         log,
		isNoop:         false,
	}, nil
}

// getSampler は環境に応じたサンプリング戦略を返す
func getSampler(environment string) sdktrace.Sampler {
	switch environment {
	case "production":
		// 本番環境: 10%のトレースをサンプリング
		return sdktrace.TraceIDRatioBased(0.1)
	case "staging":
		// ステージング環境: 50%のトレースをサンプリング
		return sdktrace.TraceIDRatioBased(0.5)
	default:
		// 開発環境: すべてのトレースをサンプリング
		return sdktrace.AlwaysSample()
	}
}

// Shutdown はテレメトリープロバイダーをシャットダウンする
func (tp *TelemetryProvider) Shutdown(ctx context.Context) error {
	tp.logger.Info("Shutting down telemetry provider", zap.Bool("is_noop", tp.isNoop))

	// Noopモードの場合はシャットダウン不要
	if tp.isNoop {
		return nil
	}

	// Tracerのシャットダウン（未送信スパンをフラッシュ）
	if tp.sdkTracer != nil {
		if err := tp.sdkTracer.Shutdown(ctx); err != nil {
			tp.logger.Error("Failed to shutdown tracer provider", zap.Error(err))
		}
	}

	// Metricsのシャットダウン（未送信メトリクスをフラッシュ）
	if tp.sdkMeter != nil {
		if err := tp.sdkMeter.Shutdown(ctx); err != nil {
			tp.logger.Error("Failed to shutdown meter provider", zap.Error(err))
			return err
		}
	}

	return nil
}

// Meter はMeterを取得する
func (tp *TelemetryProvider) Meter(name string) metric.Meter {
	return tp.meterProvider.Meter(name)
}

// Tracer はTracerを取得する
func (tp *TelemetryProvider) Tracer(name string) trace.Tracer {
	return tp.tracerProvider.Tracer(name)
}

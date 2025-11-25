package telemetry

import (
	"context"
	"fmt"
	"time"

	mexporter "github.com/GoogleCloudPlatform/opentelemetry-operations-go/exporter/metric"
	"github.com/RRRRRRR-777/TekuToko/backend/internal/infrastructure/logger"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
	"go.uber.org/zap"
)

// MetricsProvider はメトリクスプロバイダーのインターフェース
type MetricsProvider struct {
	meterProvider *sdkmetric.MeterProvider
	logger        logger.Logger
}

// NewMetricsProvider は新しいメトリクスプロバイダーを作成する
func NewMetricsProvider(ctx context.Context, projectID, serviceName, environment string, log logger.Logger) (*MetricsProvider, error) {
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

	// Cloud Monitoring Exporter作成
	exporter, err := mexporter.New(
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
				exporter,
				sdkmetric.WithInterval(60*time.Second), // 60秒ごとにエクスポート
			),
		),
	)

	// グローバルMeterProviderとして設定
	otel.SetMeterProvider(meterProvider)

	log.Info("Metrics provider initialized",
		zap.String("project_id", projectID),
		zap.String("service_name", serviceName),
		zap.String("environment", environment),
	)

	return &MetricsProvider{
		meterProvider: meterProvider,
		logger:        log,
	}, nil
}

// Shutdown はメトリクスプロバイダーをシャットダウンする
func (mp *MetricsProvider) Shutdown(ctx context.Context) error {
	mp.logger.Info("Shutting down metrics provider")
	return mp.meterProvider.Shutdown(ctx)
}

// Meter はMeterを取得する
func (mp *MetricsProvider) Meter(name string) metric.Meter {
	return mp.meterProvider.Meter(name)
}

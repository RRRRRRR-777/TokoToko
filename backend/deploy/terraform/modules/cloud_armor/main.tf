# Cloud Armorモジュール
# Google Cloud Armor セキュリティポリシー

resource "google_compute_security_policy" "policy" {
  name        = var.policy_name
  description = var.description
  project     = var.project_id

  # デフォルトルール: 許可
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule: allow all traffic"
  }

  # OWASP ModSecurity Core Rule Set - SQLインジェクション対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1000
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
        }
      }
      description = "OWASP: SQL injection protection"
    }
  }

  # OWASP ModSecurity Core Rule Set - XSS対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1001
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
        }
      }
      description = "OWASP: Cross-site scripting (XSS) protection"
    }
  }

  # OWASP ModSecurity Core Rule Set - LFI対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1002
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('lfi-v33-stable')"
        }
      }
      description = "OWASP: Local file inclusion (LFI) protection"
    }
  }

  # OWASP ModSecurity Core Rule Set - RFI対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1003
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('rfi-v33-stable')"
        }
      }
      description = "OWASP: Remote file inclusion (RFI) protection"
    }
  }

  # OWASP ModSecurity Core Rule Set - RCE対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1004
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('rce-v33-stable')"
        }
      }
      description = "OWASP: Remote code execution (RCE) protection"
    }
  }

  # OWASP ModSecurity Core Rule Set - Scanner対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1005
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('scannerdetection-v33-stable')"
        }
      }
      description = "OWASP: Scanner detection"
    }
  }

  # OWASP ModSecurity Core Rule Set - Protocol Attack対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1006
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('protocolattack-v33-stable')"
        }
      }
      description = "OWASP: Protocol attack protection"
    }
  }

  # OWASP ModSecurity Core Rule Set - Session Fixation対策
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_rule_action
      priority = 1007
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('sessionfixation-v33-stable')"
        }
      }
      description = "OWASP: Session fixation protection"
    }
  }

  # レートリミット（オプション）
  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []
    content {
      action   = "rate_based_ban"
      priority = 2000
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = ["*"]
        }
      }
      rate_limit_options {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"
        rate_limit_threshold {
          count        = var.rate_limit_threshold_count
          interval_sec = var.rate_limit_threshold_interval
        }
        ban_duration_sec = var.rate_limit_ban_duration
      }
      description = "Rate limiting: ${var.rate_limit_threshold_count} requests per ${var.rate_limit_threshold_interval}s"
    }
  }

  # カスタムルール（オプション）
  dynamic "rule" {
    for_each = var.custom_rules
    content {
      action   = rule.value.action
      priority = rule.value.priority
      match {
        expr {
          expression = rule.value.expression
        }
      }
      description = rule.value.description
    }
  }

  # Adaptive Protection（オプション）
  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable          = true
        rule_visibility = var.adaptive_protection_rule_visibility
      }
    }
  }
}

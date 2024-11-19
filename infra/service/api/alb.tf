# APIサービス用のアプリケーションロードバランサーを作成
resource "aws_alb_target_group" "sol_api" {
  name        = "${local.fqn}-api-tg"
  target_type = "lambda"
}

# ALBのリスナーを定義
# ポート80でHTTPリクエストを受け取り、ポート443でHTTPSにリダイレクトする
# リダイレクトはHTTPステータスコード301を使用
resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = data.terraform_remote_state.alb.outputs.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPSリスナーを定義
# ポート443でHTTPSリクエストを受け取り、別途定義したACM照明書を使用してSSL/TLS終端の設定を行う
# デフォルトアクションとして、APIサービス用のターゲットグループに転送する
resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = data.terraform_remote_state.alb.outputs.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.terraform_remote_state.acm.outputs.acm.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.sol_api.arn
  }
}

# 特定のパスパターンに基づき、トラフィックを特定のターゲットグループにルーティングするためのルールを定義
# リクエストパスが/api/*の場合はAPIサービスに転送する
resource "aws_alb_listener_rule" "sol_api" {
  listener_arn = aws_alb_listener.https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.sol_api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

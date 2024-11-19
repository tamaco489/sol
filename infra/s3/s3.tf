resource "aws_s3_bucket" "image" {
  bucket = "${local.fqn}-image"

  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "${local.fqn}-image" }
}

# S3バケットを静的ウェブサイトとしてホスティングするための設定
resource "aws_s3_bucket_website_configuration" "image" {
  bucket = aws_s3_bucket.image.bucket

  # ホスティングするファイルの設定、バケットにアクセスした際にデフォルトで表示するファイルを指定
  index_document {
    suffix = "index.html"
  }
}

# S3のアクセス制御設定（パブリックアクセスをすべてブロックに設定）
resource "aws_s3_bucket_public_access_block" "image" {
  bucket = aws_s3_bucket.image.bucket
}

# S3のCORS設定
resource "aws_s3_bucket_cors_configuration" "image" {
  bucket = aws_s3_bucket.image.bucket

  cors_rule {
    allowed_headers = ["*"]          # 許可するHTTPヘッダー、全てのヘッダーを許可
    allowed_methods = ["GET", "PUT"] # 許可するHTTPメソッド、GETとPUTを許可
    allowed_origins = ["*"]          # 許可するオリジン、全てのオリジンを許可
    expose_headers  = ["ETag"]       # frontendのJavaScriptがアクセスできるヘッダーをETagに指定、異なるオリジンのリクエストでもブラウザが読み取ることができるようになる。ETagはS3のオブジェクトのバージョンを表すハッシュ値、リソースが最新かどうかを確認するために使用される。
    max_age_seconds = 3000           # ブラウザがCORSプリフライトレスポンスをキャッシュする最大時間を3000秒に設定
  }
}

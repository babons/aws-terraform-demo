resource "aws_s3_bucket" "demo" {
  bucket = "babon-demo-bucket"
  
  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
  }
  
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "demo" {
  bucket = aws_s3_bucket.demo.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.demo.id
  key    = "index.html"
  source = "./index.html"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./index.html")
}

resource "aws_s3_bucket_policy" "demo_policy" {
  bucket = aws_s3_bucket.demo.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Principal: "*",
        Action: "s3:ListBucket",
        Resource: "${aws_s3_bucket.demo.arn}"
      },
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.demo.arn}/*"
      }
    ]
  })
}


resource "aws_s3_bucket_website_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}
resource "aws_dynamodb_table" "visitor_count" {
  name         = "visit-count-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "N"
  }

  tags = {
    Name        = "visitor-count-table"
    Environment = "prod"
  }
}

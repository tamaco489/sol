# コスト削減のため、NAT Gatewayは1つにする
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet["a"].id
  tags          = { Name = "${local.fqn}-nat-gateway-a" }
}

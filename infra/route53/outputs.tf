output "host_zone" {
  value = {
    id   = aws_route53_zone.sol_host_zone.id
    name = aws_route53_zone.sol_host_zone.name
  }
}

output "name_servers" {
  value = zipmap(
    [for i in range(length(aws_route53_zone.sol_host_zone.name_servers)) : tostring(i + 1)],
    aws_route53_zone.sol_host_zone.name_servers
  )
}

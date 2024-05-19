output "control_plane_ip" {
  value = aws_instance.raphaeliac_control_plane.public_ip
}

output "worker_nodes_ip" {
  value = join("", aws_instance.raphaeliac_worker_nodes[*].public_ip)
}

output "frontend_ip" {
  value = data.aws_eip.frontend_eip.public_ip
}

output "nlb_arn" {
  value = aws_lb.raphaeliac_nlb.arn
}


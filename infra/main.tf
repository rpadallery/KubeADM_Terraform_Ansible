terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.1.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}



resource "aws_security_group" "raphaeliac_sg_flannel" {
  name = "flannel-overlay"
  tags = {
    Name = "Flannel Overlay"
  }

  ingress {
    description = "flannel overlay"
    protocol    = "udp"
    from_port   = 8285
    to_port     = 8285
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "flannel overlay"
    protocol    = "udp"
    from_port   = 8472
    to_port     = 8472
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "raphaeliac_sg_common" {
  name = "common-ports"
  tags = {
    Name = "Common Ports"
  }

  ingress {
    description = "Allow SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Frontend Port"
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow generic port"
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Backend Port"
    protocol    = "tcp"
    from_port   = 3001
    to_port     = 3001
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "raphaeliac_sg_control_plane" {
  name = "control-plane"
  tags = {
    Name = "Control Plane SG"
  }
  ingress {
    description = "API Server"
    protocol    = "tcp"
    from_port   = 6443
    to_port     = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kubelet API"
    protocol    = "tcp"
    from_port   = 2379
    to_port     = 2380
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "etcd server client API"
    protocol    = "tcp"
    from_port   = 10250
    to_port     = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kube Scheduler"
    protocol    = "tcp"
    from_port   = 10259
    to_port     = 10259
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kube Controller manager"
    protocol    = "tcp"
    from_port   = 10257
    to_port     = 10257
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "raphaeliac_sg_worker_nodes" {
  name = "worker-nodes"
  tags = {
    Name = "Worker Nodes SG"
  }
  ingress {
    description = "Kubelet API"
    protocol    = "tcp"
    from_port   = 10250
    to_port     = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "NodePort Services"
    protocol    = "tcp"
    from_port   = 30000
    to_port     = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "raphaeliac"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./raphaeliac.pem"
  }
}

data "aws_eip" "frontend_eip" {
  public_ip = var.EIP
}

resource "aws_instance" "raphaeliac_frontend" {
  ami                         = var.debian_ami
  instance_type               = "t2.micro"
  key_name                    = "raphaeliac"
  associate_public_ip_address = false
  security_groups = [
    aws_security_group.raphaeliac_sg_common.name,
    aws_security_group.raphaeliac_sg_control_plane.name,
    aws_security_group.raphaeliac_sg_flannel.name
  ]
  tags = {
    Name = "Raphaeliac Frontend"
    Role = "Frontend"
  }

  provisioner "local-exec" {
    command = "echo 'frontend ${data.aws_eip.frontend_eip.public_ip}' >> ./files/hosts"
  }
}

resource "aws_eip_association" "frontend_eip_association" {
  instance_id   = aws_instance.raphaeliac_frontend.id
  allocation_id = data.aws_eip.frontend_eip.id
}

resource "aws_instance" "raphaeliac_control_plane" {
  ami                         = var.debian_ami
  instance_type               = "t2.medium"
  key_name                    = "raphaeliac"
  associate_public_ip_address = true
  security_groups = [
    aws_security_group.raphaeliac_sg_common.name,
    aws_security_group.raphaeliac_sg_control_plane.name,
    aws_security_group.raphaeliac_sg_flannel.name
  ]

  tags = {
    Name = "Raphaeliac Master"
    Role = "Control Plane Node"
  }
  provisioner "local-exec" {
    command = "echo 'master ${self.public_ip}' >> ./files/hosts"
  }
}
resource "aws_instance" "raphaeliac_worker_nodes" {
  ami                         = var.debian_ami
  count                       = var.worker_nodes_count
  instance_type               = "t2.medium"
  key_name                    = "raphaeliac"
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.raphaeliac_sg_common.id,
    aws_security_group.raphaeliac_sg_worker_nodes.id,
    aws_security_group.raphaeliac_sg_flannel.id
  ]

  tags = {
    Name = "Raphaeliac Worker ${count.index}"
    Role = "Worker Node"
  }

  provisioner "local-exec" {
    command = "echo 'worker-${count.index} ${self.public_ip}' >> ./files/hosts"
  }
}

resource "ansible_host" "raphaeliac_control_plane_host" {
  depends_on = [
    aws_instance.raphaeliac_control_plane
  ]
  name   = "control_plane"
  groups = ["master"]
  variables = {
    ansible_user                 = "admin"
    ansible_host                 = aws_instance.raphaeliac_control_plane.public_ip
    ansible_ssh_private_key_file = "./raphaeliac.pem"
    node_hostname                = "master"
  }
}

resource "ansible_host" "raphaeliac_worker_nodes_host" {
  depends_on = [
    aws_instance.raphaeliac_worker_nodes
  ]
  count  = 2
  name   = "worker-${count.index}"
  groups = ["workers"]
  variables = {
    ansible_user                 = "admin"
    ansible_host                 = aws_instance.raphaeliac_worker_nodes[count.index].public_ip
    ansible_ssh_private_key_file = "./raphaeliac.pem"
    node_hostname                = "worker-${count.index}"
  }
}

resource "ansible_host" "raphaeliac_frontend_host" {
  depends_on = [
    aws_instance.raphaeliac_frontend
  ]
  name   = "frontend"
  groups = ["frontend"]
  variables = {
    ansible_user                 = "admin"
    ansible_host                 = data.aws_eip.frontend_eip.public_ip
    ansible_ssh_private_key_file = "./raphaeliac.pem"
    node_hostname                = "frontend"
  }
}

data "aws_vpcs" "all_vpcs" {}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = var.raphaeliac_vpc_id
}

resource "aws_lb" "raphaeliac_nlb" {
  name               = "raphaeliac-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.default_subnets.ids
  security_groups = [
    aws_security_group.raphaeliac_sg_common.id,
    aws_security_group.raphaeliac_sg_control_plane.id,
    aws_security_group.raphaeliac_sg_flannel.id,
    aws_security_group.raphaeliac_sg_worker_nodes.id
  ]
}

resource "aws_lb_target_group" "worker_nodes_target_group" {
  name     = "worker-nodes-target-group"
  port     = 3001
  protocol = "TCP"
  vpc_id   = var.raphaeliac_vpc_id 
}

resource "aws_lb_target_group_attachment" "worker_nodes_attachments" {
  count            = var.worker_nodes_count
  target_group_arn = aws_lb_target_group.worker_nodes_target_group.arn
  target_id        = aws_instance.raphaeliac_worker_nodes[count.index].id
  port             = 80
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.raphaeliac_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.worker_nodes_target_group.arn
  }
}

resource "null_resource" "build_docker_image_frontend" {
  provisioner "local-exec" {
    command = "docker build -t registry.gitlab.com/projets-persos4/iac/frontend ../frontend/ --build-arg REACT_APP_BACKEND_URL=\"http://${aws_lb.raphaeliac_nlb.dns_name}\""
  }
  depends_on = [aws_lb.raphaeliac_nlb]

}

resource "null_resource" "build_docker_image_backend" {
  provisioner "local-exec" {
    command = "docker build -t registry.gitlab.com/projets-persos4/iac/backend ../backend/  --build-arg AWS_ACCESS_KEY_ID=${var.AWS_ACCESS_KEY_ID} --build-arg AWS_SECRET_ACCESS_KEY=${var.AWS_SECRET_ACCESS_KEY}  --build-arg S3_REGION=${var.S3_REGION} --build-arg S3_BUCKET=${var.S3_BUCKET}"
  }
}

resource "null_resource" "push_image_frontend" {
  provisioner "local-exec" {
    command = "docker push ${var.REGISTRY_FRONTEND}"
  }
  depends_on = [null_resource.build_docker_image_frontend]

}

resource "null_resource" "push_image_backend" {
  provisioner "local-exec" {
    command = "docker push ${var.REGISTRY_BACKEND}"
  }
  depends_on = [null_resource.build_docker_image_backend]
}

resource "local_file" "backend_yml" {
  filename = "./files/backend.yml"
  content  = <<-EOT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  selector:
    matchLabels:
      run: backend
  replicas: 3
  template: 
    metadata:
      labels:
        run: backend
    spec:
      containers: 
      - name: backend
        image: registry.gitlab.com/projets-persos4/iac/backend
        ports: 
        - containerPort: 3001
---
apiVersion: v1

kind: Service
metadata:
  name: backend-svc
  labels: 
    run: backend-svc
  annotations: 
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${aws_lb.raphaeliac_nlb.arn}
spec: 
  ports: 
  - port: 3001
    targetPort: 3001
    protocol: TCP
  selector: 
    run: backend
  type: LoadBalancer
  externalTrafficPolicy: Local
EOT
}
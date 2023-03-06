resource "aws_instance" "public_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.main-sg.id]
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = var.ecs_associate_public_ip_address
  tags = {
    Name = "jump-server"
  }
}
resource "aws_instance" "my_instances" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [aws_security_group.main-sg.id]

  tags = {
    Name = "private-instance-${var.name_prefix[floor(count.index / 2)]}-${count.index % 2 + 1}"
  }

  user_data = lookup(
    {
      for i in range(var.instance_count):
      i => i == 0 || i == 1 ? "#!/bin/bash\nsudo apt update -y\nsudo apt install nginx -y\nsudo systemctl start nginx" : i == 2 || i == 3 ? "#!/bin/bash\nsudo apt update -y\nsudo apt install wget -y\nsudo wget https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.86/bin/apache-tomcat-8.5.86.tar.gz" : i == 4 ? "#!/bin/bash\nsudo yum install -y mysql-server\nsudo systemctl start mysqld" : ""
    },
    count.index,
    ""
  )

  # Prevent user_data script from being copied to instance
  # by excluding it from the metadata options
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
  }
}


# resource "aws_instance" "my_instances" {
#   count = var.instance_count
#   ami           = var.ami_id
#   instance_type = var.instance_type
#   key_name      = var.key_name
#   subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
#   vpc_security_group_ids = [aws_security_group.main-sg.id]

#   tags = {
#     Name = "private-instance-${var.name_prefix[floor(count.index / 2)]}-${count.index % 2 + 1}"
#   }
# }

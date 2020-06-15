provider "aws" {
  region = "ap-south-1"
  profile= "default"
}
resource "aws_key_pair" "tfkey" {

key_name  = "tfkey"
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCw7Ywoiemow0CDBP2COX01dLb7lIKSNbXydZKL7MCMZeFr40Oi5fzv3n43kyEjH88tZL2/W5mOD4k9aAzaqPaneFXvJrUxYXJUWnnEWU4QPpDaFuks1tMo2IpAb/S5m6gLkmYuxPUnxCXNF0BkYgsdcXxkn1FToQ7Mxq334Ul33dcl+ENyguUGrZKNS5al9Tmmzf789GA6k9KJojRvy04QqJO+euSZPlHQC024k+M1P+RGol7ofO57qfmTLsbYhNZHWBcOM+IowoIqMYn0E2KfQ+Esw/1U084Ffi6awzbfmQLVYxP7QTGPYs++Tdmc4Lg6GRVigbuBb49L9Dbgqe0L"

}



resource "aws_security_group" "tasksg" {
name = "tasksg" 
description = "Allow TLS inbound traffic"
vpc_id = "vpc-c09380a8"

ingress {
description = "SSH"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [ "0.0.0.0/0" ]
}
ingress {
description = "HTTP"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = [ "0.0.0.0/0" ]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "tasksg"
}
}

resource "aws_ebs_volume" "ebs" {
  availability_zone = aws_instance.my.availability_zone
  size              = 1

  tags = {
    Name = "ebsvol"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs.id}"
  instance_id = "${aws_instance.my.id}"
force_detach = true
}

resource "aws_s3_bucket" "buckets" {

	 bucket = "mybucketfortask1"

	 acl  = "public-read"

	 tags = {

		Name = "terraform bucket"

	 }

}

locals {

s3_origin_id = "myS3Origin"

}




resource "aws_s3_bucket_object" "task1bucket_object" {
key = "tfkey"
bucket = "${aws_s3_bucket.buckets.id}"

source = "https://github.com/ss1998-seth/Terraform/blob/master/images.jpeg"
}
//Allow Public Access s3 bucket
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = "${aws_s3_bucket.buckets.id}"
block_public_acls   = false
  block_public_policy = false
}



resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}

resource "aws_instance"  "my"{
  ami= "ami-0447a12f28fddb066"
  instance_type="t2.micro"
  key_name     = "${aws_key_pair.tfkey.key_name}"

security_groups = ["${aws_security_group.tasksg.name}"]

user_data = <<-EOF

        #! /bin/bash

         sudo yum install httpd -y

         sudo systemctl start httpd

         sudo systemctl enable httpd

         sudo yum install git -y

         mkfs.ext4 /dev/sdf     

         mount /dev/sdf /var/www/html

       cd /var/www/html

        git clone  https:\\github.com\ss1998-seth\Terraform.git
EOF

tags={

Name ="task"

}

}








   
resource "aws_cloudfront_distribution" "s3_distribution" {

		 origin {

			domain_name = "${aws_s3_bucket.buckets.bucket_regional_domain_name}"

			origin_id  = "${local.s3_origin_id}"
                        custom_origin_config {
                                http_port = 80
                                   https_port = 80
                                   origin_protocol_policy = "match-viewer"
                                   origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
                             }
                     }
                enabled = true
			
		 default_cache_behavior {

				allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

				cached_methods  = ["GET", "HEAD"]

				target_origin_id = "${local.s3_origin_id}"

				forwarded_values {

				 query_string = false

				 cookies {

					forward = "none"

				 }

				}

				viewer_protocol_policy = "allow-all"
 min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400

		 }

			restrictions {

			geo_restriction {

			 restriction_type = "none"

			 

			}

			}

		 tags = {

			Environment = "production"

			}

		 viewer_certificate {

			cloudfront_default_certificate = true

		 }

}





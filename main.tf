provider "aws" {
  region                  = "us-west-2"
  shared_credentials_file = "/Users/tf_user/.aws/creds"
  profile                 = "customprofile"
}
# create IAM Role
resource "aws_iam_role" "eksServiceRole" {
  name        = "eksServiceRole"
  description = "eks service role"

  assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": "eks.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }
]
}
POLICY
}

#add policy to IAM
resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eksServiceRole.name}"
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSclusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eksServiceRole.name}"
}

# Create a VPC
resource "aws_vpc" "eksvpc" {
  cidr_block = "192.168.0.0/16"
}

# create subnet
resource "aws_subnet" "subnet01" {
  vpc_id            = "${aws_vpc.eksvpc.id}"
  cidr_block        = "192.168.64.0/18"
  availability_zone = "us-east-1a"

  tags {
    Name = "eksnet01"
  }

  depends_on = ["aws_vpc.eksvpc"]
}

resource "aws_subnet" "subnet02" {
  vpc_id            = "${aws_vpc.eksvpc.id}"
  cidr_block        = "192.168.128.0/18"
  availability_zone = "us-east-1b"

  tags {
    Name = "eksnet02"
  }

  depends_on = ["aws_vpc.eksvpc"]
}

resource "aws_subnet" "subnet03" {
  vpc_id            = "${aws_vpc.eksvpc.id}"
  cidr_block        = "192.168.192.0/18"
  availability_zone = "us-east-1c"

  tags {
    Name = "eksnet03"
  }

  depends_on = ["aws_vpc.eksvpc"]
}

# Internet Gateway

resource "aws_internet_gateway" "eksgw" {
  vpc_id = "${aws_vpc.eksvpc.id}"

  tags {
    Name = "eksmain"
  }

  depends_on = ["aws_vpc.eksvpc"]
}

resource "aws_route_table" "ekspublic" {
  vpc_id = "${aws_vpc.eksvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eksgw.id}"
  }

  depends_on = ["aws_vpc.eksvpc"]
}
# Route table associate

resource "aws_route_table_association" "rtsub01" {
  subnet_id      = "${aws_subnet.subnet01.id}"
  route_table_id = "${aws_route_table.ekspublic.id}"
  depends_on = ["aws_vpc.eksvpc"]
}

resource "aws_route_table_association" "rtsub02" {
  subnet_id      = "${aws_subnet.subnet02.id}"
  route_table_id = "${aws_route_table.ekspublic.id}"
  depends_on = ["aws_vpc.eksvpc"]
}

resource "aws_route_table_association" "rtsub03" {
  subnet_id      = "${aws_subnet.subnet03.id}"
  route_table_id = "${aws_route_table.ekspublic.id}"
  depends_on = ["aws_vpc.eksvpc"]
}

# security group for outbound all traffic

resource "aws_security_group" "eks_sg" {
  vpc_id = "${aws_vpc.eksvpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

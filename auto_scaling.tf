data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}


data "aws_region" "current" {}

locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.ekscluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.ekscluster.certificate_authority.0.data}' 'eks_test'
USERDATA
}

resource "aws_launch_configuration" "worker_ag_launch" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks-worker-profile.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "t2.nano"
  name_prefix                 = "terraform-eks-demo"
  security_groups             = ["${aws_security_group.eks_wsg.id}"]
  user_data_base64            = "${base64encode(local.demo-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker_ag_group" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.worker_ag_launch.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-demo"
  vpc_zone_identifier  = ["${aws_subnet.subnet01.id},${aws_subnet.subnet02.id},${aws_subnet.subnet03.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/eks_test"
    value               = "owned"
    propagate_at_launch = true
  }
}

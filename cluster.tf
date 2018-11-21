resource "aws_eks_cluster" "ekscluster" {
  name = "eks_test"
  role_arn = "${aws_iam_role.eksServiceRole.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks_sg.id}"]
    subnet_ids = ["${aws_subnet.subnet01.id}","${aws_subnet.subnet02.id}","${aws_subnet.subnet03.id}"]
  }
  depends_on = [
    "aws_iam_role_policy_attachment.demo-cluster-AmazonEKSServicePolicy",
    "aws_iam_role_policy_attachment.demo-cluster-AmazonEKSclusterPolicy",
  ]
}

#kubeconfig

locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.ekscluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.ekscluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "ekscluster"
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

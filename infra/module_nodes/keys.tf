# Downloads cloud image and generates keypair for access

resource "tls_private_key" "mykey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "local_file" "private_key" {
  filename = "${path.module}/keys/private_key_${var.node_type}.pem"
  content  = tls_private_key.mykey.private_key_pem
}


resource "local_file" "public_key" {
  filename = "${path.module}/keys/public_key_${var.node_type}.pem"
  content  = tls_private_key.mykey.public_key_openssh
}



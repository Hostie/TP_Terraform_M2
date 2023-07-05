variable ssh_host {}
variable ssh_user {}
variable ssh_key {}
variable psw {}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&"
}

resource "null_resource" "ssh_target" {
    connection {
        type    = "ssh"
        user    = var.ssh_user
        host    = var.ssh_host
        private_key = file(var.ssh_key)
        }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.psw} | sudo -S mkdir /home/server/openstack",
            "sudo chown server:server /home/server/openstack",
            "sudo chmod +x /home/server/openstack",
            "echo 'server ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/server",
            "cd /home/server/openstack",
            "git clone https://opendev.org/openstack/devstack",
            "cd devstack",
            "cat > local.conf << EOF\n[[local|localrc]]\nADMIN_PASSWORD=${random_password.password.result}\nDATABASE_PASSWORD=${random_password.password.result}\nRABBIT_PASSWORD=${random_password.password.result}\nSERVICE_PASSWORD=${random_password.password.result}\nEOF",
            "./stack.sh"
            ]
            }
   
}
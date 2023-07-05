resource "null_resource" "ssh_target" {
    connection {
        type    = "ssh"
        user    = var.ssh_user
        host    = var.ssh_host
        private_key = file(var.ssh_key)
        }
    provisioner "remote-exec" {
        inline = [
            
            ]
            }
   
}
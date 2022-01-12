output "vm1_public_ip" {
    value = module.vm1.public_ip
}

output "vm2_public_ip" {
    value = module.vm2.public_ip
}

output "capture_command" {
    value = "sudo tcpdump -i eth0 icmp -n"
}
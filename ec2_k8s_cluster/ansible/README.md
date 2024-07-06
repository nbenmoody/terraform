# Run Ansible playbooks

## Against admin node:
1. Snag the ip of the admin node:
`ter output -json | jq .admin_node.value -r | pbcopy`
2. Replace the IP in the hosts file here.
3. Run the playbook against the host:
`ansible-playbook -i hosts --user ubuntu --private-key ~/Creds/ben_personal ./admin-node.yml`

## Against the cluster nodes
1. Snag the ips of the cluster nodes:
`ter output -json | hq .cluster_nodes.value -r | pbcopy`
2. Replace the IPs in the hosts file here, reformatting as needed.
3. Run the playbook against the hosts:
`ansible-playbook -i hosts --user ubuntu --private-key ~/Creds/ben_personal ./cluster_node.yml`

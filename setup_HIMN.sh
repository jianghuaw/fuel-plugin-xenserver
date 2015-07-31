source localrc

echo "Setting up HIMN"

for HOST_NODE in ${COMPUTE_NODES//,/ }
do
	IFS=/ read -a _HOST_NODE <<< $HOST_NODE
	HOST=${_HOST_NODE[0]}
	NODE=${_HOST_NODE[1]}
	sshpass -p $XEN_PASSWORD ssh $XEN_ROOT@$HOST \
'set +x
vm_name="'$NODE'"
vm_uuid=$(xe vm-list name-label="$vm_name" --minimal)
if [ -n "$vm_uuid" ]; then
	device_number=2
	net_uuid=$(xe network-list bridge=xenapi minimal=true)
	vif_uuid=$(xe vif-list network-uuid="$net_uuid" vm-uuid="$vm_uuid" --minimal)
	if [ -z "$vif_uuid" ]; then
		
		eth2_uuid=$(xe vif-create network-uuid="$net_uuid" vm-uuid="$vm_uuid" device="$device_number")
		echo "$vm_name : HIMN created"

		#_vm=$(xe vif-plug uuid="$eth2_uuid")
	fi
	other_config=$(xe network-param-get param-name="other-config" uuid="$net_uuid")
	if [[ "$other_config" == "*is_guest_installer_network*" ]]; then
		echo "$vm_name : exposing HIMN"
		xe network-param-remove param-name="other-config" param-key="is_guest_installer_network" uuid="$net_uuid"
	fi
else
	echo "$vm_name does not exist"
fi
set +x'
done
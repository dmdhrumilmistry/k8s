apply: 
	@kubectl apply -f cloud-metadata-deny.yml
	@kubectl apply -f cloud-metadata-allow.yml
	@kubectl run allowtest --image=nginx
	@kubectl run denytest --image=nginx
	@kubectl label pod allowtest role=metadata-accessor

destroy:
	@kubectl delete -f cloud-metadata-deny.yml
	@kubectl delete -f cloud-metadata-allow.yml
	@kubectl delete pod allowtest
	@kubectl delete pod denytest


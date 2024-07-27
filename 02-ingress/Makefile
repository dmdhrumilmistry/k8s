apply:
	@kubectl apply -f service1.yaml
	@kubectl apply -f service2.yaml
	@kubectl apply -f ingress.yaml

destroy:
	@kubectl delete -f service1.yaml
	@kubectl delete -f service2.yaml
	@kubectl delete -f ingress.yaml

test:
	@sh ./test.sh

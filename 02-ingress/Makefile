apply:
	@kubectl apply -f service1.yaml
	@kubectl apply -f service2.yaml
	@kubectl apply -f ingress.yaml

destroy:
	@kubectl delete -f service1.yaml
	@kubectl delete -f service2.yaml
	@kubectl delete -f ingress.yaml

test:
	@curl http://localhost/service1 | grep -q "Welcome to nginx\!" && echo "success" || echo "failed"
	@curl http://localhost/service2 | grep -q "Welcome to nginx\!" && echo "success" || echo "failed"
	@curl http://localhost/ | grep -q "Welcome to nginx\!" && echo "failed" || echo "success"
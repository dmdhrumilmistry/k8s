apply:
	@kubectl apply -f namespace.yml
	@kubectl apply -f database.yml
	@kubectl apply -f frontend.yml
	@kubectl apply -f backend.yml
	@kubectl apply -f worker.yml
	@kubectl apply -f ingress.yml

destroy:
	@kubectl delete -f database.yml
	@kubectl delete -f frontend.yml
	@kubectl delete -f backend.yml
	@kubectl delete -f worker.yml
	@kubectl delete -f ingress.yml
	@kubectl delete -f namespace.yml


minikubei: # install minikube deps
	@minikube addons enable metrics-server
	@minikube addons enable ingress

ingress:
	@minikube tunnel
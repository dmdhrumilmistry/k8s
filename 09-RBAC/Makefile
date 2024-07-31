all: apply test destroy

apply: 
	@kubectl apply -f lab1/namespaces.yml
	@kubectl apply -f lab1/roles.yml
	@kubectl apply -f lab1/rolebindings.yml

	@kubectl apply -f lab2/namespaces.yml
	@kubectl apply -f lab2/roles.yml
	@kubectl apply -f lab2/rolebindings.yml

destroy:
	@kubectl delete -f lab1/rolebindings.yml
	@kubectl delete -f lab1/roles.yml
	@kubectl delete -f lab1/namespaces.yml

	@kubectl delete -f lab2/rolebindings.yml
	@kubectl delete -f lab2/roles.yml
	@kubectl delete -f lab2/namespaces.yml

test:
	@./lab1/test.sh
	@./lab2/test.sh

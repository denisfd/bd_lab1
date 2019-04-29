.PHONY: exec

exec:
	docker-compose -f docker-compose.yml exec -u postgres pg96 psql	

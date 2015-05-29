test: test-backend test-app test-frontend

test-backend:
	docker-compose run backend bash -c 'cd /play/backend && prove'

test-app:
	docker-compose run app bash -c 'cd /play/app && prove'

test-frontend:
	@echo "Frontend tests are temporarily broken due to problems with installing phantomjs in our containers"
	# www is based on node:0.12, frontend is based on nginx:latest, both are Debian 8, there's no phantomjs for Debian 8 :(
	# Command for running tests: phantomjs /www/tools/run-jasmine.js http://localhost:80/test/index.html

hack:
	@echo "Entering the docker container for editing the mounted code volumes."
	@echo "NOTE:"
	@echo "    This container includes berekuk's personal development environment."
	@echo "    You might want to edit dev/Dockerfile if you prefer something else."
	@docker exec -it questhub_dev_1 bash

restart-www:
	docker-compose kill www && docker-compose start www && docker-compose logs www

restart:
	docker-compose kill && docker-compose up -d

release: release-app release-backend release-www

release-app:
	docker build -t berekuk/questhub_app app
	docker push berekuk/questhub_app

release-backend:
	docker build -t berekuk/questhub_backend backend
	docker push berekuk/questhub_backend

release-www:
	docker build -t berekuk/questhub_www www
	docker push berekuk/questhub_www

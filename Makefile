.PHONY: client-run
client-run:
	cd client && flutter run

.PHONY: server-run
server-run:
	cd server && cargo run

.PHONY: docker-up
docker-up:
	cd server && docker compose up -d

.PHONY: docker-clean
docker-clean:
	cd server && docker compose down -v

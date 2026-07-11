.PHONY: up shell install-cli verify logs down

BIN_DIR ?= $(shell [ -d /opt/homebrew/bin ] && echo /opt/homebrew/bin || echo /usr/local/bin)

up:
	docker compose up -d --build vpn dev

shell:
	docker compose exec dev bash

install-cli:
	ln -sfn "$(CURDIR)/bin/vpngrok" "$(BIN_DIR)/vpngrok"
	@echo "installed $(BIN_DIR)/vpngrok"

verify:
	@echo "Tunnel exit (should NOT be your real IP/location):"
	@docker compose exec dev sh -c 'curl -s https://ipinfo.io/json | jq -r '"'"'"\(.ip) (\(.city), \(.country)) - \(.org)"'"'"''
	@docker compose exec dev sh -c 'curl -s --max-time 10 https://am.i.mullvad.net/connected || true'

logs:
	docker compose logs -f vpn

down:
	docker compose down

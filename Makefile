SHELL := /bin/bash

.PHONY: dev dev-stop dev-restart

dev:
	./scripts/dev-up.sh

dev-stop:
	./scripts/dev-down.sh

dev-restart: dev-stop dev

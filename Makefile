SHELL := /bin/bash

ANSIBLE_DIR := ansible

CONTEXT ?= remote
ALLOW_UNINSTALL ?= false
FORCE ?= false

# Interface no estilo do projeto de referência (docs/iac-onprem-cluster-swarm.zip)
ENVIRONMENT ?= prd
WITH_PREREQS ?= false
TARGET ?= platform

PORTAINER_GATEWAY_ENV_FILE ?= ./config/portainer-gateway.env
PORTAINER_MANAGEMENT_ENV_FILE ?= ./config/portainer-management.env
PORTAINER_REPOSITORY_ENV_FILE ?= ./config/portainer-repository.env


.PHONY: all help setup-local install-make-local install-sshpass-local install-ansible-local \
	check-tools check-ansible \
	check-portainer-gateway check-portainer-management check-portainer-repository check-portainer-connectivity \
	install-repository validate-repository uninstall-repository \
	install-management validate-management uninstall-management \
	install-gateway validate-gateway uninstall-gateway \
	install-platform validate-platform uninstall-platform \
	stacks install uninstall check clean clean-hard

all: help

help:
	@echo ""
	@echo "== Gravitee APIM (GIO) - Docker Swarm + Portainer API =="
	@echo ""
	@echo "[Bootstrap local]"
	@echo "  make install-make-local              - instala make local via script"
	@echo "  make install-sshpass-local           - instala sshpass local via script"
	@echo "  make install-ansible-local           - instala ansible local via script"
	@echo "  make setup-local                     - bootstrap local (make + sshpass + ansible)"
	@echo ""
	@echo "[Pré-checagem]"
	@echo "  make check-tools                     - valida dependências locais"
	@echo "  make check-ansible                   - valida sintaxe dos scripts Ansible (bash -n)"
	@echo "  make check-portainer-connectivity    - valida APIs do Portainer (gateway/management/repository)"
	@echo ""
	@echo "[Repository (Mongo + Elasticsearch + Kibana + Mongo-Express)]"
	@echo "  make install-repository              - instala/atualiza stacks do repositório"
	@echo "  make validate-repository             - valida stacks do repositório"
	@echo ""
	@echo "[Management]"
	@echo "  make install-management              - instala/atualiza stack Management"
	@echo "  make validate-management             - valida stack Management"
	@echo ""
	@echo "[Gateway]"
	@echo "  make install-gateway                 - instala/atualiza stack Gateway"
	@echo "  make validate-gateway                - valida stack Gateway"
	@echo ""
	@echo "[Plataforma - ponta a ponta]"
	@echo "  make install-platform                - repository -> management -> gateway"
	@echo "  make validate-platform               - valida repository + management + gateway"
	@echo ""
	@echo "[Desinstalação - protegida]"
	@echo "  make uninstall-platform ALLOW_UNINSTALL=true"
	@echo "  make uninstall-repository ALLOW_UNINSTALL=true"
	@echo "  make uninstall-management ALLOW_UNINSTALL=true"
	@echo "  make uninstall-gateway ALLOW_UNINSTALL=true"
	@echo "  (opcional) FORCE=true para limpeza mais agressiva"
	@echo ""
	@echo "[Interface estilo 'stacks' (aderente ao zip de referência)]"
	@echo "  ENVIRONMENT=prd make stacks install platform"
	@echo "  ENVIRONMENT=prd make stacks install repository"
	@echo "  ENVIRONMENT=prd make stacks install management"
	@echo "  ENVIRONMENT=prd make stacks install gateway"
	@echo "  ENVIRONMENT=prd make stacks check platform"
	@echo "  ENVIRONMENT=prd make stacks clean platform"
	@echo "  ENVIRONMENT=prd make stacks clean-hard platform ALLOW_UNINSTALL=true"
	@echo ""
	@echo "[Parâmetros úteis]"
	@echo "  CONTEXT=remote|local (default: remote)"
	@echo "  ENVIRONMENT=dsv|hml|prd (default: prd)"
	@echo "  WITH_PREREQS=true (bootstrap local via scripts)"

install-make-local:
	@bash ./scripts/install-make.sh

install-sshpass-local:
	@bash ./scripts/install-sshpass.sh

install-ansible-local:
	@bash ./scripts/install-ansible.sh

setup-local: install-make-local install-sshpass-local install-ansible-local
	@echo "Bootstrap local concluído."

check-tools:
	@command -v bash >/dev/null || { echo "bash não encontrado"; exit 1; }
	@command -v sshpass >/dev/null || { echo "sshpass não encontrado. Execute: make install-sshpass-local"; exit 1; }
	@command -v ansible-playbook >/dev/null || { echo "ansible-playbook não encontrado. Execute: make install-ansible-local"; exit 1; }
	@command -v curl >/dev/null || { echo "curl não encontrado"; exit 1; }
	@command -v python3 >/dev/null || { echo "python3 não encontrado"; exit 1; }
	@echo "Dependências locais OK."

check-ansible:
	@bash -n ./scripts/iac-gio-platform-repository.sh
	@bash -n ./scripts/iac-gio-platform-management.sh
	@bash -n ./scripts/iac-gio-platform-gateway.sh
	@echo "Sintaxe dos scripts OK."

check-portainer-gateway:
	@bash ./scripts/check-portainer-api.sh $(ANSIBLE_DIR)/$(PORTAINER_GATEWAY_ENV_FILE)

check-portainer-management:
	@bash ./scripts/check-portainer-api.sh $(ANSIBLE_DIR)/$(PORTAINER_MANAGEMENT_ENV_FILE)

check-portainer-repository:
	@bash ./scripts/check-portainer-api.sh $(ANSIBLE_DIR)/$(PORTAINER_REPOSITORY_ENV_FILE)

check-portainer-connectivity: check-portainer-gateway check-portainer-management check-portainer-repository
	@echo "Conectividade/API dos Portainers validada."

install-repository:
	@bash ./scripts/iac-gio-platform-repository.sh install $(CONTEXT) repository

validate-repository:
	@bash ./scripts/iac-gio-platform-repository.sh validate $(CONTEXT) repository

install-management:
	@bash ./scripts/iac-gio-platform-management.sh install $(CONTEXT) management

validate-management:
	@bash ./scripts/iac-gio-platform-management.sh validate $(CONTEXT) management

install-gateway:
	@bash ./scripts/iac-gio-platform-gateway.sh install $(CONTEXT) gateway

validate-gateway:
	@bash ./scripts/iac-gio-platform-gateway.sh validate $(CONTEXT) gateway

require-uninstall-approval:
	@if [[ "$(ALLOW_UNINSTALL)" != "true" ]]; then \
		echo "Desinstalação bloqueada. Use ALLOW_UNINSTALL=true para confirmar explicitamente."; \
		exit 1; \
	fi

uninstall-repository: require-uninstall-approval
	@ALLOW_UNINSTALL=$(ALLOW_UNINSTALL) FORCE_UNINSTALL=$(FORCE) bash ./scripts/iac-gio-platform-repository.sh uninstall $(CONTEXT) repository

uninstall-management: require-uninstall-approval
	@ALLOW_UNINSTALL=$(ALLOW_UNINSTALL) FORCE_UNINSTALL=$(FORCE) bash ./scripts/iac-gio-platform-management.sh uninstall $(CONTEXT) management

uninstall-gateway: require-uninstall-approval
	@ALLOW_UNINSTALL=$(ALLOW_UNINSTALL) FORCE_UNINSTALL=$(FORCE) bash ./scripts/iac-gio-platform-gateway.sh uninstall $(CONTEXT) gateway

install-platform: check-portainer-connectivity
	@$(MAKE) install-repository CONTEXT=$(CONTEXT)
	@$(MAKE) validate-repository CONTEXT=$(CONTEXT)
	@$(MAKE) install-management CONTEXT=$(CONTEXT)
	@$(MAKE) validate-management CONTEXT=$(CONTEXT)
	@$(MAKE) install-gateway CONTEXT=$(CONTEXT)
	@$(MAKE) validate-gateway CONTEXT=$(CONTEXT)
	@echo "Fluxo ponta a ponta concluído (repository -> management -> gateway)."

validate-platform:
	@$(MAKE) validate-repository CONTEXT=$(CONTEXT)
	@$(MAKE) validate-management CONTEXT=$(CONTEXT)
	@$(MAKE) validate-gateway CONTEXT=$(CONTEXT)
	@echo "Validação ponta a ponta concluída."

uninstall-platform: require-uninstall-approval
	@$(MAKE) uninstall-gateway ALLOW_UNINSTALL=$(ALLOW_UNINSTALL) FORCE=$(FORCE) CONTEXT=$(CONTEXT)
	@$(MAKE) uninstall-management ALLOW_UNINSTALL=$(ALLOW_UNINSTALL) FORCE=$(FORCE) CONTEXT=$(CONTEXT)
	@$(MAKE) uninstall-repository ALLOW_UNINSTALL=$(ALLOW_UNINSTALL) FORCE=$(FORCE) CONTEXT=$(CONTEXT)
	@echo "Remoção ponta a ponta concluída (gateway -> management -> repository)."


# --- Interface estilo 'stacks' (compatível com o projeto de referência) ---

stacks:
	@if [ "$(word 2,$(MAKECMDGOALS))" = "install" ]; then \
	  TARGET_ARG="$(word 3,$(MAKECMDGOALS))"; \
	  if [ -z "$$TARGET_ARG" ]; then \
	    echo "Uso: ENVIRONMENT=<dsv|hml|prd> make stacks install <repository|management|gateway|platform>"; \
	    exit 1; \
	  fi; \
	  bash ./scripts/deploy-stacks.sh "$$TARGET_ARG"; \
	elif [ "$(word 2,$(MAKECMDGOALS))" = "uninstall" ]; then \
	  TARGET_ARG="$(word 3,$(MAKECMDGOALS))"; \
	  if [ -z "$$TARGET_ARG" ]; then \
	    echo "Uso: ENVIRONMENT=<dsv|hml|prd> make stacks uninstall <repository|management|gateway|platform>"; \
	    exit 1; \
	  fi; \
	  bash ./scripts/delete-stacks.sh "$$TARGET_ARG"; \
	elif [ "$(word 2,$(MAKECMDGOALS))" = "check" ]; then \
	  TARGET_ARG="$(word 3,$(MAKECMDGOALS))"; \
	  if [ -z "$$TARGET_ARG" ]; then \
	    echo "Uso: ENVIRONMENT=<dsv|hml|prd> make stacks check <repository|management|gateway|platform>"; \
	    exit 1; \
	  fi; \
	  bash ./scripts/iac.sh check $(ENVIRONMENT) "$$TARGET_ARG" $(WITH_PREREQS); \
	elif [ "$(word 2,$(MAKECMDGOALS))" = "clean" ]; then \
	  TARGET_ARG="$(word 3,$(MAKECMDGOALS))"; \
	  if [ -z "$$TARGET_ARG" ]; then \
	    echo "Uso: ENVIRONMENT=<dsv|hml|prd> make stacks clean <repository|management|gateway|platform>"; \
	    exit 1; \
	  fi; \
	  bash ./scripts/clean-stacks.sh "$$TARGET_ARG"; \
	elif [ "$(word 2,$(MAKECMDGOALS))" = "clean-hard" ]; then \
	  TARGET_ARG="$(word 3,$(MAKECMDGOALS))"; \
	  if [ -z "$$TARGET_ARG" ]; then \
	    echo "Uso: ENVIRONMENT=<dsv|hml|prd> make stacks clean-hard <repository|management|gateway|platform>"; \
	    exit 1; \
	  fi; \
	  bash ./scripts/clean-hard-stacks.sh "$$TARGET_ARG"; \
	else \
	  echo "Uso: make stacks <install|uninstall|check|clean|clean-hard> <target>"; \
	  exit 1; \
	fi

install:
	@if [ "$(firstword $(MAKECMDGOALS))" != "install" ]; then \
	  :; \
	else \
	  bash ./scripts/deploy-stacks.sh $(TARGET); \
	fi

uninstall:
	@if [ "$(firstword $(MAKECMDGOALS))" != "uninstall" ]; then \
	  :; \
	else \
	  bash ./scripts/delete-stacks.sh $(TARGET); \
	fi

check:
	@if [ "$(firstword $(MAKECMDGOALS))" != "check" ]; then \
	  :; \
	else \
	  bash ./scripts/iac.sh check $(ENVIRONMENT) $(TARGET) $(WITH_PREREQS); \
	fi

clean:
	@if [ "$(firstword $(MAKECMDGOALS))" != "clean" ]; then \
	  :; \
	else \
	  bash ./scripts/clean-stacks.sh $(TARGET); \
	fi

clean-hard:
	@if [ "$(firstword $(MAKECMDGOALS))" != "clean-hard" ]; then \
	  :; \
	else \
	  bash ./scripts/clean-hard-stacks.sh $(TARGET); \
	fi

%:
	@:

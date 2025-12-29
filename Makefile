SRCS =  $(wildcard capitoli/*.typ)

.PHONY: format build
all: format build

format:
	@for file in $(SRCS); do \
		fmt -w 80 -s "$$file" | sponge "$$file"; \
	done

build:
	typst c main.typ

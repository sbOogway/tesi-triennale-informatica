SRCS =  $(wildcard capitoli/*.typ)

.PHONY: format build
all: format build

format:
	@for file in $(SRCS); do \
		fmt -w 80 -s "$$file" | sponge "$$file"; \
	done

build:
	typst c main.typ
	gs -dPDFA -dBATCH -dNOPAUSE -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite -sPDFACompatibi
lityPolicy=1 -sOutputFile=main_pdfa.pdf main.pdf


presentation:
	cd presentazione && typst compile --root .. slides.typ slides.pdf

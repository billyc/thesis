# --------------------------------------------------
# standard Makefile preamble see https://tech.davis-hansson.com/p/make/
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.DELETE_ON_ERROR:
ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error Your Make does not support .RECIPEPREFIX. Use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >
# --------------------------------------------------

SRC = .
TEX = phd

BUILD_DEPS := $(SRC)/$(TEX).tex
BUILD_DEPS += $(SRC)/settings/mysettings.tex
BUILD_DEPS += $(shell find $(SRC)/bib/*)
BUILD_DEPS += Makefile $(shell find $(SRC)/chapters/*)

build: $(TEX).pdf
.PHONY: build

$(TEX).pdf: $(BUILD_DEPS)
> pdflatex $(TEX).tex
> BIBINPUTS=$(SRC)/bib bibtex $(TEX)
> pdflatex $(TEX).tex
# > pdflatex $(TEX).tex

serve:
> fswatch -o -e "aux$$" $(TEX).tex `find chapters -type f` `find bib -type f` | xargs -n1 -I{} gmake
> # inotifywait -qrm --event modify src/* | while read file; do make; done
.PHONY: serve

clean:
> find . -name "*.aux" | xargs rm
> rm -rf $(SRC)/*.pdf $(SRC)/*.ps
> rm -rf $(SRC)/*.out $(SRC)/*.log
> for EXT in acn acr alg bbl blg brf dvi glg glo gls ist lof log lot tdo toc; \
    do rm -f $(TEX).$$EXT; done
.PHONY: clean

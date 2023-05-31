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
BUILD_DEPS += Makefile $(shell find $(SRC) -name "*.tex")
BUILD_DEPS += $(SRC)/settings/mysettings.tex
BUILD_DEPS += $(shell find $(SRC)/bib/*)
BUILD_DEPS += $(shell find $(SRC) -name "*.png")

$(TEX).pdf: $(BUILD_DEPS)
> rm -f *.log
> pdflatex -synctex=1 -interaction nonstopmode $(TEX).tex

.sentinel-final: $(TEX).pdf
> BIBINPUTS=$(SRC)/bib bibtex $(TEX)
> makeglossaries $(TEX)
> pdflatex -interaction batchmode $(TEX).tex
> pdflatex -interaction batchmode $(TEX).tex
> pdflatex -interaction batchmode $(TEX).tex
> touch $@  # only creates .sentinel-final when the entire build process completes successfully

final: .sentinel-final
.PHONY: final

serve:
> fswatch -o -e "aux$$" -e "png$$" $(TEX).tex chapters bib | xargs -n1 -I{} gmake
> # inotifywait -qrm --event modify src/* | while read file; do make; done
.PHONY: serve

clean:
> rm -f $(TEX).pdf
> rm -f .sentinel*
# on MacOS this requires "brew install findutils" to get gxargs
> find . -name "*.aux" | gxargs -d '\n' rm
> for EXT in acn acr alg bbl blg brf dvi glg glo gls ist lof log lot tdo toc; \
    do rm -f $(TEX).$$EXT; done
.PHONY: clean

# variables:
# >@echo BUILD_DEPS: ${BUILD_DEPS}
# .PHONY: variables

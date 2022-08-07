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

PNG_IMAGES := $(shell find $(SRC)/chapters -name "*.png")
PDF_IMAGES := $(patsubst %.png, %.png.pdf, $(PNG_IMAGES))

BUILD_DEPS := $(SRC)/$(TEX).tex
BUILD_DEPS += Makefile $(shell find $(SRC) -name "*.tex")
BUILD_DEPS += $(SRC)/settings/mysettings.tex
BUILD_DEPS += $(shell find $(SRC)/bib/*)
BUILD_DEPS += $(PDF_IMAGES)

build: images $(TEX).pdf
.PHONY: build

$(TEX).pdf: $(BUILD_DEPS)
> rm -f *.log
> pdflatex -interaction batchmode -draftmode $(TEX).tex
> makeglossaries phd
> BIBINPUTS=$(SRC)/bib bibtex $(TEX)
> pdflatex -interaction batchmode $(TEX).tex #--third try needed?
> pdflatex -interaction batchmode $(TEX).tex
# > pdflatex -interaction batchmode $(TEX).tex
# > pdflatex -interaction batchmode $(TEX).tex

images: $(PDF_IMAGES)
.PHONY: images

%.png.pdf: %.png
> convert -compress LZW $*.png pdf:$*.png.pdf

serve:
> fswatch -o -e "aux$$"-e "pdf$$" $(TEX).tex chapters bib | xargs -n1 -I{} gmake
> # inotifywait -qrm --event modify src/* | while read file; do make; done
.PHONY: serve

clean:
> rm -f $(TEX).pdf
> rm -f .sentinel*
> find . -name "*.aux" | xargs rm
> find . -name "*.png.pdf" | xargs rm
> for EXT in acn acr alg bbl blg brf dvi glg glo gls ist lof log lot tdo toc; \
    do rm -f $(TEX).$$EXT; done
.PHONY: clean

variables:
>@echo PNG_IMAGES: ${PNG_IMAGES}
>@echo PDF_IMAGES: ${PDF_IMAGES}
# >@echo BUILD_DEPS: ${BUILD_DEPS}
.PHONY: variables

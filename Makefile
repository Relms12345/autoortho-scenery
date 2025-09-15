# Requires:
# * Github CLI (gh) command to facilitate authenticated requests to the API
# * pipenv (for otv)
#
# Quick start:
#   Generate tile set:
#     export TILESET=eur ZL=16 VARIANT=o4xp1.40 VERSION=1.0 && nice make -j $(nproc --ignore=6) --keep-going z_ao_${TILESET}_zl${ZL}_${VARIANT}_v${VERSION}
#
#   Generate single tile:
#     export TILE=+78+015 ZL=16 VARIANT=o4xp1.40 VERSION=1.0 && nice make -j $(nproc --ignore=6) z_ao__single_${TILE}_zl${ZL}_${VARIANT}_v${VERSION}
#
#   Make all:
#     export ZL=16 VARIANT=o4xp1.40 VERSION=1.0 && nice make -j $(nproc --ignore=6)
#
#   Stats:
#     make stats

# remove make builtin rules for more useful make -d 
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
SHELL=/bin/sh

ZL?=16
VARIANT?=o4xp1.40
VERSION?=1.0

# paranthesis to use in shell commands
# make chokes on () in shell commands
OP:=(
CP:=)

#
# Work on tile lists
#
.DEFAULT_GOAL := all
var/run/Makefile.tilelistRules_zl$(ZL)_$(VARIANT)_v$(VERSION): bin/genMakefileTilelistRules *_tile_list
	@mkdir -p var/run/
	@echo "[$@]"
	@bin/genMakefileTilelistRules $(ZL) $(VARIANT) $(VERSION) > $@
include var/run/Makefile.tilelistRules_zl$(ZL)_$(VARIANT)_v$(VERSION)

stats:
	@printf "                 validated  (done) /total\n"
	@allDsf="$$(find build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/*/_docs -name 'generated_by_*' -printf "%f\n" 2> /dev/null | sed -E -e 's/generated_by_//' -e 's/\.txt/.dsf/' | sort)" \
	&& validatedDsf="$$(find build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/*/_docs -name 'checked_by_*' -printf "%f\n" 2> /dev/null | sed -E -e 's/checked_by_//' -e 's/\.txt/.dsf/' | sort)" \
		&& for tiles in *_tile_list; do \
			dsfTile="$$(sort $$tiles | uniq)" \
			&& printf "%-20s %5d (%5d) /%5d\n" \
				"$$tiles" \
				$$(comm --total -123 \
						<(echo "$$dsfTile") \
						<(echo "$$validatedDsf") \
					| cut -f3) \
				$$(comm --total -123 <(echo "$$dsfTile") <(echo "$$allDsf") | cut -f3) \
				$$(cat $$tiles | wc -l); \
		done \
		&& printf "——————————————————————————————————————————\n" \
		&& printf "%20s %5d (%5d) /%5d\n" \
			"=" \
			$$(comm --total -123 \
					<(sort *_tile_list | uniq) \
					<(echo "$$validatedDsf") \
				| cut -f3) \
			$$(comm --total -123 <(sort *_tile_list | uniq) <(echo "$$allDsf") | cut -f3) \
			$$(cat *_tile_list | wc -l);
	@printf "\ngenerated_by:\n"
	@sort build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_*/_docs/generated_by* 2> /dev/null | uniq -c

# shows stats with changes from last call
statsdiff:
	@mkdir -p var/run/
	@[ -e var/run/prevStats ] || touch var/run/prevStats
	@new="$$($(MAKE) --silent stats)" \
	&& diff --new-line-format='+%L' --old-line-format='-%L' --unchanged-line-format=' %L' var/run/prevStats <(echo "$$new"); \
	echo "$$new" > var/run/prevStats

sort-rasters:
	./bin/compare_files.sh xplane-rasters.txt antarctica_tiles antarctica_tiles.not-in-xplane-rasters
	./bin/exclude_files.sh antarctica_tiles antarctica_tiles.not-in-xplane-rasters antarctica_tile_list

	./bin/compare_files.sh xplane-rasters.txt eur_tiles eur_tiles.not-in-xplane-rasters
	./bin/exclude_files.sh eur_tiles eur_tiles.not-in-xplane-rasters eur_tile_list

	./bin/compare_files.sh xplane-rasters.txt greenland_tiles greenland_tiles.not-in-xplane-rasters
	./bin/exclude_files.sh greenland_tiles greenland_tiles.not-in-xplane-rasters greenland_tile_list

	./bin/compare_files.sh xplane-rasters.txt na_tiles na_tiles.not-in-xplane-rasters
	./bin/exclude_files.sh na_tiles na_tiles.not-in-xplane-rasters na_tile_list

	./bin/compare_files.sh antarctica_tile_list xplane-rasters.txt xplane-rasters.not-in-tilelist

	./bin/compare_files.sh eur_tile_list xplane-rasters.not-in-tilelist xplane-rasters.not-in-tilelist.new
	mv xplane-rasters.not-in-tilelist.new xplane-rasters.not-in-tilelist

	./bin/compare_files.sh greenland_tile_list xplane-rasters.not-in-tilelist xplane-rasters.not-in-tilelist.new
	mv xplane-rasters.not-in-tilelist.new xplane-rasters.not-in-tilelist

	./bin/compare_files.sh na_tile_list xplane-rasters.not-in-tilelist xplane-rasters.not-in-tilelist.new
	mv xplane-rasters.not-in-tilelist.new xplane-rasters.not-in-tilelist

# creates directories
%/:
	@echo "[$@]"
	@mkdir -p $@

#
# tilesets and tiles
#

z_ao__single_%_zl$(ZL)_$(VARIANT)_v$(VERSION): build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_%/_docs/checked_by_*.txt
	@echo "[$@]"
	@rm -rf $@/
	@cp --force --link --recursive build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/ $@/

z_ao__single_%_zl$(ZL)_$(VARIANT)_v$(VERSION).zip: z_ao__single_%_zl$(ZL)_$(VARIANT)_v$(VERSION)
	@echo "[$@]"
	@cd z_ao__single_$*_zl$(ZL)_$(VARIANT)_v$(VERSION) \
		&& zip -r ../$@ .

z_ao_%_zl$(ZL)_$(VARIANT)_v$(VERSION): %_tile_list var/run/%_zl$(ZL)_$(VARIANT)_v$(VERSION)_tiles var/run/Makefile.tilelistRules_zl$(ZL)_$(VARIANT)_v$(VERSION)
	@echo "[$@]"
	@rm -rf $@/
	@mkdir -p $@
	@cd build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/ \
		&& for dsf in $$(cat $(CURDIR)/$*_tile_list); do \
			echo $$dsf \
				&& dir=zOrtho4XP_$$(basename -- $$dsf .dsf) \
				&& [ -e $$dir/"Earth nav data"/*/$$dsf ] \
				&& cp --force --recursive --link $$dir/* $(CURDIR)/$@/. \
				|| exit 1; \
		done

#
# Ortho4XP setup
#

Ortho4XP:
	@echo "[$@]"
	[ ! -e $@ ] || rm -rf $@
	git clone https://github.com/shred86/Ortho4XP $@
	@mkdir -p build/Elevation_data/ build/Geotiffs/ build/Masks/ build/OSM_data/ build/Orthophotos build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)
	@set -x && cd $@/ \
		&& echo "$$(git remote get-url origin)|$$(git describe --tags --long)" > generated_by.template \
		&& ln -snfr ../Ortho4XP.cfg ../Ortho4XP_noroads.cfg ../Ortho4XP_no_minangle.cfg . \
		&& ln -snfr ../build/Elevation_data ../build/Geotiffs ../build/Masks ../build/OSM_data ../build/Orthophotos . \
		&& python3 -m venv .venv \
		&& . .venv/bin/activate \
		&& sed -i '/gdal/d' requirements.txt \
		&& pip install numpy==1.26.4 wheel setuptools --no-cache --force-reinstall \
		&& pip install gdal==$$(gdalinfo --version | cut -f 2 -d' ' | cut -f1 -d ',') --no-cache --force-reinstall \
		&& pip install -r requirements.txt

#
# dyoung522/otv (Tile Checker) fork
#

otv:
	@echo "[$@]"
	[ ! -e $@ ] || rm -rf $@
	git clone --single-branch --branch develop https://github.com/jonaseberle/otv.git
	@cd $@/ \
		&& echo "$$(git remote get-url origin)|$$(git describe --tags --long)" > checked_by.template \
		&& PIPENV_PIPFILE=./Pipfile PIPENV_IGNORE_VIRTUALENVS=1 pipenv install \
		&& pipenv install colorama


#
# Build and test tile
#

build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_%/_docs/checked_by_*.txt: build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_%/_docs/generated_by_*.txt otv
	@echo [$@]
	@cd $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$* \
		&& PIPENV_PIPFILE=$(CURDIR)/otv/Pipfile PIPENV_IGNORE_VIRTUALENVS=1 pipenv run \
			$(CURDIR)/otv/bin/otv --all --ignore-textures --no-progress . \
		&& mkdir -p _docs/ \
		&& rm -f Data* *.bak "Earth nav data"/*/*.bak \
		&& ( ls Ortho4XP_*.cfg &>/dev/null && mv Ortho4XP_*.cfg _docs/ || true ) \
		&& cp $(CURDIR)/otv/checked_by.template _docs/checked_by_$*.txt \


build/Tiles/zl$(ZL)/o4xp1.40/v$(VERSION)/zOrtho4XP_%/_docs/generated_by_*.txt: Ortho4XP
	@echo [$@]
	@mkdir -p $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/_docs/
	@# this silences deprecation warnings in Ortho4XP for more concise output
	@set -x; \
	echo $(@); \
	export COORDS=$$(echo $(@) | sed -e 's/.*\([-+][0-9]\+\)\([-+][0-9]\+\).*/\1 \2/g'); \
	cd $(CURDIR)/Ortho4XP \
		&& cp Ortho4XP.cfg $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Ortho4XP_$*.cfg \
		&& sed -i "/^default_zl=/s/=.*/=$(ZL)/" $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Ortho4XP_$*.cfg \
		&& ln -snfr ../build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION) ./Tiles \
		&& . .venv/bin/activate \
		&& python3 Ortho4XP.py $$COORDS 2>&1 \
		&& [ -e "$(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Earth nav data/"*/$*.dsf ] \
		&& cp generated_by.template $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/_docs/generated_by_$*.txt; \
	[ -e "$(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Earth nav data/"*/$*.dsf ] || ( \
                echo "ERROR DETECTED! Retry tile $@ with no_minangle config."; \
                cd $(CURDIR)/Ortho4XP \
                        && cp Ortho4XP_no_minangle.cfg $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Ortho4XP_$*.cfg \
                        && sed -i "/^default_zl=/s/=.*/=$(ZL)/" $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Ortho4XP_$*.cfg \
                        && ln -snfr ../build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION) ./Tiles \
                        && . .venv/bin/activate \
                        && python3 Ortho4XP.py $$COORDS 2>&1 \
                        && [ -e "$(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Earth nav data/"*/$*.dsf ] \
                        && cp generated_by.template $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/_docs/generated_by_$*.txt \
        ); \
	[ -e "$(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Earth nav data/"*/$*.dsf ] || ( \
		echo "ERROR DETECTED! Retry tile $@ with noroads & no_minangle config."; \
		cd $(CURDIR)/Ortho4XP \
			&& cp Ortho4XP_noroads.cfg $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Ortho4XP_$*.cfg \
			&& sed -i "/^default_zl=/s/=.*/=$(ZL)/" $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Ortho4XP_$*.cfg \
			&& ln -snfr ../build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION) ./Tiles \
			&& . .venv/bin/activate \
			&& python3 Ortho4XP.py $$COORDS 2>&1 \
			&& [ -e "$(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/Earth nav data/"*/$*.dsf ] \
			&& cp generated_by.template $(CURDIR)/build/Tiles/zl$(ZL)/$(VARIANT)/v$(VERSION)/zOrtho4XP_$*/_docs/generated_by_$*.txt \
	); \

clean:
	@echo "[$@]"
	-rm -rf build/Tiles/*
	-rm -rf var/run
	-rm -rf z_*

distclean: clean
	@echo "[$@]"
	-rm -rf Ortho4XP
	-rm -rf build
	-rm -rf var
	-rm -rf z_*
	-rm -f *_tile_list.*

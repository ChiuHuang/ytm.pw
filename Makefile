# ytm.pw top-level build.
# Theos lives in ~/theos (or $THEOS). A decrypted YTM 9.34 IPA goes in ipa/
# for the package step; see docs/tweaks.md.

export THEOS ?= $(HOME)/theos

all: package

package:
	./scripts/check-layers.sh
	$(MAKE) -C tweak package

release: package
	@echo "[OK] deb in tweak/packages/ -- inject into your decrypted IPA and sign"

install:
	$(MAKE) -C tweak install

log:
	idevicesyslog -m ytmglass || idevicesyslog | grep ytmglass

clean:
	$(MAKE) -C tweak clean

.PHONY: all package release install log clean

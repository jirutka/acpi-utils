prefix       := $(or $(prefix),$(PREFIX),/usr/local)
prefix       := /usr/local
bindir       := $(prefix)/bin
mandir       := $(prefix)/share/man

ASCIIDOCTOR  := asciidoctor
INSTALL      := install
GIT          := git
SED          := sed

SCRIPTS       = lid-state power-supply
MAN_PAGES     = $(addsuffix .1,$(SCRIPTS))
MAKEFILE_PATH = $(lastword $(MAKEFILE_LIST))


#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_PATH) \
		| while read label desc; do printf '%-15s %s\n' "$$label" "$$desc"; done

#: Build sources.
build: man

#: Build man pages.
man: $(MAN_PAGES)

#: Remove generated files.
clean:
	rm -f ./*.[1-9]

#: Install into $DESTDIR.
install: install-other install-man

#: Install everything except the man pages into $DESTDIR.
install-other: $(SCRIPTS)
	$(INSTALL) -D -m755 -t "$(DESTDIR)$(bindir)/" $^

#: Install man pages into $DESTDIR/$mandir/man1/.
install-man: $(MAN_PAGES)
	$(INSTALL) -D -m644 -t $(DESTDIR)$(mandir)/man1/ $^

#: Uninstall from $DESTDIR.
uninstall:
	for name in $(SCRIPTS); do \
		rm -f "$(DESTDIR)$(bindir)/$$name"; \
	done
	for name in $(MAN_PAGES); do \
		rm -f "$(DESTDIR)$(mandir)/man1/$$name"; \
	done

#: Update version in the scripts and README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" $(SCRIPTS)
	$(SED) -E -i "s/^(:version:).*/\1 $(VERSION)/" README.adoc

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version
	test -n "$(VERSION)"  # $$VERSION
	$(GIT) add .
	$(GIT) commit -m "Release version $(VERSION)"
	$(GIT) tag -s v$(VERSION) -m v$(VERSION)

.PHONY: help build man clean install install-other install-man uninstall bump-version release


.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: .check-git-clean


%.1: %.1.adoc
	$(ASCIIDOCTOR) -b manpage -o $@ $<

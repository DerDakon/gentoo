# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Suite of DNS client programs and libraries for Unix systems"
HOMEPAGE="https://www.skarnet.org/software/s6-dns/"
SRC_URI="https://www.skarnet.org/software/${PN}/${P}.tar.gz"

LICENSE="ISC"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"

RDEPEND=">=dev-libs/skalibs-2.14.3.0:="
DEPEND="${RDEPEND}"

HTML_DOCS=( doc/. )

src_prepare() {
	default

	# Avoid QA warning for LDFLAGS addition
	sed -i -e 's/.*-Wl,--hash-style=both$/:/' configure || die

	sed -i -e '/AR := /d' -e '/RANLIB := /d' Makefile || die
}

src_configure() {
	tc-export AR CC RANLIB

	local myconf=(
		--bindir=/bin
		--dynlibdir="/$(get_libdir)"
		--libdir="/usr/$(get_libdir)/${PN}"
		--with-dynlib="/$(get_libdir)"
		--with-lib="/usr/$(get_libdir)/skalibs"
		--with-sysdeps="/usr/$(get_libdir)/skalibs"

		--enable-pkgconfig
		--pkgconfdir="/usr/$(get_libdir)/pkgconfig"

		--enable-shared
		--disable-allstatic
		--disable-static
		--disable-static-libc
	)

	econf "${myconf[@]}"
}

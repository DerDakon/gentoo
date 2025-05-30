# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_COMMIT=a578956
PYTHON_COMPAT=( python3_{10..13} )
PYTHON_REQ_USE="threads(+)"

inherit python-any-r1 waf-utils

DESCRIPTION="X terminal emulator rendering through OpenGL ES Compute Shaders"
HOMEPAGE="https://tomscii.sig7.se/zutty/ https://git.hq.sig7.se/zutty.git"
SRC_URI="https://git.hq.sig7.se/zutty.git/snapshot/${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}"/${P}-${MY_COMMIT}

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

# It is possible to run the tests using virtualx, but it seems to take
# screenshots of the terminal window, and compares checksums that never
# seem to match.
RESTRICT="test"

RDEPEND="
	media-libs/freetype:2
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXmu
	x11-libs/libXt
"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	virtual/pkgconfig
"

PATCHES=(
	# Remove default CXX/LDFLAGS, bug #830405.
	"${FILESDIR}"/${PN}-0.12-cxxflags.patch
)

DOCS=( doc/KEYS.org doc/USAGE.org )

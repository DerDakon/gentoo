# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

MY_P=${PN}2-${PV}

DESCRIPTION="Active OS fingerprinting tool - this is Xprobe2"
HOMEPAGE="http://sys-security.com/blog/xprobe2"
SRC_URI="https://downloads.sourceforge.net/${PN}/${MY_P}.tar.gz"
S="${WORKDIR}"/${MY_P}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~sparc x86"

DEPEND="net-libs/libpcap"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${P}-gcc43.patch
	"${FILESDIR}"/${P}-cxx11.patch
	"${FILESDIR}"/${P}-gcc-12.patch
	"${FILESDIR}"/${P}-makefiles.patch
	"${FILESDIR}"/${P}-demangle-output.patch
	"${FILESDIR}"/${P}-clang.patch
)

src_prepare() {
	default

	tc-export AR
}

src_install() {
	default

	dodoc AUTHORS CHANGELOG CREDITS README TODO docs/*.{txt,pdf}
}

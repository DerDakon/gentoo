# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools

DESCRIPTION="A tool for determining a firewall's rule set"
HOMEPAGE="http://packetfactory.openwall.net/projects/firewalk/"
SRC_URI="mirror://gentoo/${P}.tgz"
S=${WORKDIR}/${PN^}

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"

DEPEND="
	dev-libs/libdnet
	net-libs/libnet:1.1
	net-libs/libpcap
"
RDEPEND="
	${DEPEND}
"
DOCS=( README TODO BUGS )
PATCHES=(
	"${FILESDIR}"/${P}-gcc3.4.diff
	"${FILESDIR}"/${P}-usage.diff
	"${FILESDIR}"/${P}-signal.patch
)

src_prepare() {
	default

	# bug https://bugs.gentoo.org/899922
	eautoreconf
}

src_install() {
	default
	doman man/firewalk.8
}

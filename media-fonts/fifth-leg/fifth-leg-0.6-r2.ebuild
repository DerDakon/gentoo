# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit font

OPENSUSE_RELEASE="12.2"
DESCRIPTION="Simplistic, technical sans serif - openSUSE font"
HOMEPAGE="https://jimmac.eu/"
SRC_URI="https://api.opensuse.org/public/source/openSUSE:${OPENSUSE_RELEASE}/fifth-leg-font/opensuse-font-${P}.tar.bz2"
S="${WORKDIR}"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~loong ~riscv ~x86"
IUSE=""

FONT_SUFFIX="otf sfd"

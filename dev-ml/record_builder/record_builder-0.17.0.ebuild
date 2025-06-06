# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit dune

DESCRIPTION="A library which provides traversal of records with an applicative"
HOMEPAGE="https://github.com/janestreet/record_builder"
SRC_URI="https://github.com/janestreet/${PN}/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~amd64 ~arm64"
IUSE="+ocamlopt"

RDEPEND="
	>=dev-lang/ocaml-5
	dev-ml/base:${SLOT}[ocamlopt]
	dev-ml/ppx_jane:${SLOT}[ocamlopt]
"
DEPEND="${RDEPEND}"
BDEPEND=">=dev-ml/dune-3.11"

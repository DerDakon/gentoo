# Copyright 2019-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

git_hash=32cc98e

DESCRIPTION="the spiffe runtime environment"
HOMEPAGE="https://github.com/spiffe/spire"
SRC_URI="https://github.com/spiffe/spire/archive/v${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" https://dev.gentoo.org/~arthurzam/distfiles/app-misc/${PN}/${P}-deps.tar.xz"

LICENSE="Apache-2.0"
# Dependent licenses
LICENSE+=" BSD-2 BSD MIT ISC MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"
PROPERTIES="test_network"

DEPEND="
	acct-group/spire
	acct-user/spire
"
RDEPEND="${DEPEND}"

src_compile() {
	local go_ldflags+="
		-X github.com/spiffe/spire/pkg/common/version.gittag=${PV}
		-X github.com/spiffe/spire/pkg/common/version.githash=${git_hash}"
	ego build -ldflags "${go_ldflags}" \
		-o bin/spire-agent ./cmd/spire-agent
	ego build -ldflags "${go_ldflags}" \
		-o bin/spire-server ./cmd/spire-server
}

src_test() {
	ego test ./...
}

src_install() {
	exeinto /opt/spire
	doexe bin/*
	keepdir /opt/spire/.data
	insinto /etc/spire
	doins -r conf/*
	dosym ../../etc/spire /opt/spire/conf
	dosym ../../opt/spire/spire-agent /usr/bin/spire-agent
	dosym ../../opt/spire/spire-server /usr/bin/spire-server
	dodoc -r doc/*
	newconfd "${FILESDIR}"/spire-agent.confd spire-agent
	newinitd "${FILESDIR}"/spire-agent.initd spire-agent
	newconfd "${FILESDIR}"/spire-server.confd spire-server
	newinitd "${FILESDIR}"/spire-server.initd spire-server
	keepdir /var/log/spire
	fowners spire:spire /opt/spire/.data
	fowners spire:spire /var/log/spire
}

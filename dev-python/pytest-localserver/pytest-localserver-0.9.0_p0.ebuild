# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} pypy3_11 )

inherit distutils-r1 pypi

DESCRIPTION="Pytest plugin to test server connections locally"
HOMEPAGE="
	https://github.com/pytest-dev/pytest-localserver/
	https://pypi.org/project/pytest-localserver/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~m68k ppc ppc64 ~riscv ~s390 sparc x86 ~x64-macos"

RDEPEND="
	>=dev-python/werkzeug-0.10[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/pytest[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/six[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

EPYTEST_IGNORE=(
	# requires aiosmtpd that is dead and broken beyond repair
	tests/test_smtp.py
)

src_prepare() {
	# remove aiosmtpd dep
	sed -e '/aiosmtpd/d' -i setup.py || die
	distutils-r1_src_prepare
}

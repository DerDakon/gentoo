# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYPI_NO_NORMALIZE=1
PYPI_PN=PyOpenGL
PYTHON_REQ_USE="tk?"
PYTHON_COMPAT=( pypy3 python3_{10..13} )

inherit distutils-r1 virtualx

DESCRIPTION="Python OpenGL bindings"
HOMEPAGE="
	https://pyopengl.sourceforge.net/
	https://github.com/mcfletch/pyopengl/
	https://pypi.org/project/PyOpenGL/
"
# 3.1.8 is missing from pypi: https://github.com/mcfletch/pyopengl/issues/123
SRC_URI="https://github.com/mcfletch/pyopengl/archive/refs/tags/release-${PV}.tar.gz -> ${P}.gh.tar.gz"
S="${WORKDIR}"/${PN}-release-${PV}

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ppc ppc64 ~riscv x86 ~amd64-linux ~x86-linux"
IUSE="tk"

RDEPEND="
	media-libs/freeglut
	virtual/opengl
	x11-libs/libXi
	x11-libs/libXmu
	tk? ( dev-tcltk/togl )
"
DEPEND="
	${RDEPEND}
"

# The tests need an X server with the GLX extension. Software rendering
# under Xvfb works but only with llvmpipe, not softpipe or swr.
BDEPEND="
	test? (
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pygame[${PYTHON_USEDEP},opengl,X]
		!prefix? (
			media-libs/mesa[llvm]
			x11-base/xorg-server[-minimal,xorg]
		)
	)
"

distutils_enable_tests pytest

PATCHES=(
	# https://github.com/mcfletch/pyopengl/pull/109
	"${FILESDIR}/${PN}-3.1.7-pypy3.patch"
	# https://github.com/mcfletch/pyopengl/issues/123
	"${FILESDIR}/${P}-fix-version.patch"
)

python_test() {
	local EPYTEST_DESELECT=(
		# unreliable memory counting test
		tests/test_vbo_memusage.py::test_sf_2980896
	)
	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1

	nonfatal epytest tests || die "Tests failed with ${EPYTHON}"
}

src_test() {
	virtx distutils-r1_src_test
}

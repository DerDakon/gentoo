# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..13} )

inherit distutils-r1

DESCRIPTION="Python implementation of the Engine.IO realtime server"
HOMEPAGE="
	https://python-engineio.readthedocs.io/
	https://github.com/miguelgrinberg/python-engineio/
	https://pypi.org/project/python-engineio/"
SRC_URI="
	https://github.com/miguelgrinberg/python-engineio/archive/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="
	dev-python/aiohttp[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	>=dev-python/simple-websocket-0.10.0[${PYTHON_USEDEP}]
	dev-python/websocket-client[${PYTHON_USEDEP}]
"
# Can use eventlet, werkzeug, or gevent, but no tests for werkzeug
BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/tornado[${PYTHON_USEDEP}]
		dev-python/websockets[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/alabaster

python_test() {
	local EPYTEST_IGNORE=(
		# eventlet is masked for removal
		tests/common/test_async_eventlet.py
	)

	local EPYTEST_DESELECT=(
		# also eventlet
		tests/common/test_server.py::TestServer::test_async_mode_eventlet
		tests/common/test_server.py::TestServer::test_connect
		tests/common/test_server.py::TestServer::test_service_task_started
		tests/common/test_server.py::TestServer::test_upgrades
	)

	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	epytest -p asyncio
}

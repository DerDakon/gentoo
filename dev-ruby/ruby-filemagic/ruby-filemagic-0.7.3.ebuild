# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
USE_RUBY="ruby31 ruby32 ruby33 ruby34"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="ChangeLog README TODO"

RUBY_FAKEGEM_EXTENSIONS=(ext/filemagic/extconf.rb)
RUBY_FAKEGEM_EXTENSION_LIBDIR="lib/filemagic"

RUBY_FAKEGEM_TASK_TEST=""

inherit ruby-fakegem

DESCRIPTION="Ruby binding to libmagic"
HOMEPAGE="https://github.com/blackwinter/ruby-filemagic"

LICENSE="Ruby-BSD"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="test"

DEPEND="${DEPEND} sys-apps/file test? ( >=sys-apps/file-5.30 )"
RDEPEND="${RDEPEND} sys-apps/file"

all_ruby_prepare() {
	# Fix up broken test symlink and regenerate compiled magic file
	pushd test || die
	rm -f pylink && ln -s pyfile pylink || die
	file -C -m perl || die
	popd || die

	sed -e '/test_\(abbrev_mime_type\|check_compiled\|singleton\)/aomit "different result with file 5.41"' \
		-i test/filemagic_test.rb || die
}

each_ruby_test() {
	find test
	${RUBY} -Ctest -I../lib filemagic_test.rb || die
}

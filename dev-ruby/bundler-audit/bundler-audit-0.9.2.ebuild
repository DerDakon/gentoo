# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

USE_RUBY="ruby31 ruby32 ruby33 ruby34"

RUBY_FAKEGEM_RECIPE_TEST="rspec3"

inherit ruby-fakegem

DESCRIPTION="Provides patch-level verification for Bundled apps"
HOMEPAGE="https://github.com/rubysec/bundler-audit"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="test"

#tests are trying to download files
RESTRICT=test

ruby_add_rdepend "
	dev-ruby/thor:1
	dev-ruby/bundler:2
"

all_ruby_prepare() {
	sed -i -e '/simplecov/I s:^:#:' spec/spec_helper.rb || die

	# Avoid specs that require network access via 'bundle install'
	rm spec/{integration,scanner}_spec.rb || die

	# Avoid specs that only work when the source is a git repository
	sed -i -e '/describe "path"/,/^  end/ s:^:#:' \
		-e '/describe "update!"/,/^  end/ s:^:#:' \
		spec/database_spec.rb || die
}

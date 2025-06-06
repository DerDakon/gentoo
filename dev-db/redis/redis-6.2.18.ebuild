# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Redis does NOT build with Lua 5.2 or newer at this time:
#  - 5.3 and 5.4 give:
# lua_bit.c:83:2: error: #error "Unknown number type, check LUA_NUMBER_* in luaconf.h"
#  - 5.2 fails with:
# scripting.c:(.text+0x1f9b): undefined reference to `lua_open'
#    because lua_open became lua_newstate in 5.2
LUA_COMPAT=( lua5-1 luajit )

# Upstream have deviated too far from vanilla Lua, adding their own APIs
# like lua_enablereadonlytable, but we still need the eclass and such
# for bug #841422.
inherit autotools edo flag-o-matic lua-single multiprocessing systemd tmpfiles toolchain-funcs

DESCRIPTION="A persistent caching system, key-value, and data structures database"
HOMEPAGE="https://redis.io"
SRC_URI="
	https://github.com/redis/redis/archive/refs/tags/${PV}.tar.gz
		-> ${P}.tar.gz
"

LICENSE="BSD"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="amd64 ~arm ~arm64 ~hppa ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="+jemalloc selinux ssl systemd tcmalloc test"
RESTRICT="!test? ( test )"

DEPEND="
	${LUA_DEPS}
	jemalloc? ( >=dev-libs/jemalloc-5.1:= )
	ssl? ( dev-libs/openssl:0= )
	systemd? ( sys-apps/systemd:= )
	tcmalloc? ( dev-util/google-perftools )
"

RDEPEND="
	${DEPEND}
	acct-group/redis
	acct-user/redis
	selinux? ( sec-policy/selinux-redis )
"

BDEPEND="
	acct-group/redis
	acct-user/redis
	virtual/pkgconfig
	test? (
		dev-lang/tcl:0=
		ssl? ( dev-tcltk/tls )
	)
"

REQUIRED_USE="?? ( jemalloc tcmalloc )
	${LUA_REQUIRED_USE}"

PATCHES=(
	"${FILESDIR}"/${PN}-6.2.1-config.patch
	"${FILESDIR}"/${PN}-5.0-shared.patch
	"${FILESDIR}"/${PN}-6.2.3-ppc-atomic.patch
	"${FILESDIR}"/${PN}-sentinel-5.0-config.patch
)

src_prepare() {
	default

	# Copy lua modules into build dir
	#cp "${S}"/deps/lua/src/{fpconv,lua_bit,lua_cjson,lua_cmsgpack,lua_struct,strbuf}.c "${S}"/src || die
	#cp "${S}"/deps/lua/src/{fpconv,strbuf}.h "${S}"/src || die
	# Append cflag for lua_cjson
	# https://github.com/antirez/redis/commit/4fdcd213#diff-3ba529ae517f6b57803af0502f52a40bL61
	append-cflags "-DENABLE_CJSON_GLOBAL"

	# now we will rewrite present Makefiles
	local makefiles="" MKF
	for MKF in $(find -name 'Makefile' | cut -b 3-); do
		mv "${MKF}" "${MKF}.in"
		sed -i	-e 's:$(CC):@CC@:g' \
			-e 's:$(CFLAGS):@AM_CFLAGS@:g' \
			-e 's: $(DEBUG)::g' \
			-e 's:$(OBJARCH)::g' \
			-e 's:ARCH:TARCH:g' \
			-e '/^CCOPT=/s:$: $(LDFLAGS):g' \
			"${MKF}.in" \
		|| die "Sed failed for ${MKF}"
		makefiles+=" ${MKF}"
	done
	# autodetection of compiler and settings; generates the modified Makefiles
	cp "${FILESDIR}"/configure.ac-3.2 configure.ac || die

	# Use the correct pkgconfig name for Lua.
	# The upstream configure script handles luajit specially, and is not
	# affected by these changes.
	sed -i	\
		-e "/^AC_INIT/s|, [0-9].+, |, $PV, |" \
		-e "s:AC_CONFIG_FILES(\[Makefile\]):AC_CONFIG_FILES([${makefiles}]):g" \
		-e "/PKG_CHECK_MODULES.*\<LUA\>/s,lua5.1,${ELUA},g" \
		configure.ac || die "Sed failed for configure.ac"
	eautoreconf
}

src_configure() {
	econf #$(use_with lua_single_target_luajit luajit)

	# Linenoise can't be built with -std=c99, see https://bugs.gentoo.org/451164
	# also, don't define ANSI/c99 for lua twice
	sed -i -e "s:-std=c99::g" deps/linenoise/Makefile deps/Makefile || die
}

src_compile() {
	local myconf=""

	if use jemalloc; then
		myconf+="MALLOC=jemalloc"
	elif use tcmalloc; then
		myconf+="MALLOC=tcmalloc"
	else
		myconf+="MALLOC=libc"
	fi

	if use ssl; then
		myconf+=" BUILD_TLS=yes"
	fi

	export USE_SYSTEMD=$(usex systemd)

	tc-export AR CC RANLIB
	emake V=1 ${myconf} AR="${AR}" CC="${CC}" RANLIB="${RANLIB}"
}

src_test() {
	local runtestargs=(
		--clients "$(makeopts_jobs)" # see bug #649868
	)

	if has usersandbox ${FEATURES} || ! has userpriv ${FEATURES}; then
		ewarn "unit/oom-score-adj test will be skipped." \
			"It is known to fail with FEATURES usersandbox or -userpriv. See bug #756382."

		# unit/oom-score-adj was introduced in version 6.2.0
		runtestargs+=( --skipunit unit/oom-score-adj ) # see bug #756382
	fi

	if use ssl; then
		edo ./utils/gen-test-certs.sh
		runtestargs+=( --tls )
	fi

	edo ./runtest "${runtestargs[@]}"
}

src_install() {
	insinto /etc/redis
	doins redis.conf sentinel.conf
	use prefix || fowners -R redis:redis /etc/redis /etc/redis/{redis,sentinel}.conf
	fperms 0750 /etc/redis
	fperms 0644 /etc/redis/{redis,sentinel}.conf

	newconfd "${FILESDIR}/redis.confd-r2" redis
	newinitd "${FILESDIR}/redis.initd-6" redis

	systemd_newunit "${FILESDIR}/redis.service-4" redis.service
	newtmpfiles "${FILESDIR}/redis.tmpfiles-2" redis.conf

	newconfd "${FILESDIR}/redis-sentinel.confd-r1" redis-sentinel
	newinitd "${FILESDIR}/redis-sentinel.initd-r1" redis-sentinel

	insinto /etc/logrotate.d/
	newins "${FILESDIR}/${PN}.logrotate" ${PN}

	dodoc 00-RELEASENOTES BUGS CONTRIBUTING MANIFESTO README.md

	dobin src/redis-cli
	dosbin src/redis-benchmark src/redis-server src/redis-check-aof src/redis-check-rdb
	fperms 0750 /usr/sbin/redis-benchmark
	dosym redis-server /usr/sbin/redis-sentinel

	if use prefix; then
		diropts -m0750
	else
		diropts -m0750 -o redis -g redis
	fi
	keepdir /var/{log,lib}/redis
}

pkg_postinst() {
	tmpfiles_process redis.conf

	ewarn "The default redis configuration file location changed to:"
	ewarn "  /etc/redis/{redis,sentinel}.conf"
	ewarn "Please apply your changes to the new configuration files."
}

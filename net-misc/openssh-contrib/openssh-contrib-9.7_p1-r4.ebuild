# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit user-info optfeature flag-o-matic autotools pam systemd toolchain-funcs verify-sig eapi9-ver

# Make it more portable between straight releases
# and _p? releases.
MY_P=${P/-contrib/}
PARCH=${MY_P/_}

# PV to USE for HPN patches
#HPN_PV="${PV^^}"
HPN_PV="8.5_P1"

HPN_VER="15.2"
HPN_PATCHES=(
	openssh-${HPN_PV/./_}-hpn-DynWinNoneSwitch-${HPN_VER}.diff
	openssh-${HPN_PV/./_}-hpn-PeakTput-${HPN_VER}.diff
)
HPN_GLUE_PATCH="openssh-9.6_p1-hpn-${HPN_VER}-glue.patch"
HPN_PATCH_DIR="HPN-SSH%%20${HPN_VER/./v}%%20${HPN_PV/_P/p}"

X509_VER="15.0"
X509_PATCH="${PARCH}+x509-${X509_VER}.diff.gz"
X509_PATCH="${X509_PATCH/p2/p1}"
X509_GLUE_PATCH="openssh-${PV}-X509-glue-${X509_VER}.patch"
#X509_HPN_GLUE_PATCH="${MY_P}-hpn-${HPN_VER}-X509-${X509_VER}-glue.patch"
X509_HPN_GLUE_PATCH="${MY_P}-hpn-${HPN_VER}-X509-${X509_VER%.1}-glue.patch"

DESCRIPTION="Port of OpenBSD's free SSH release with HPN/X509 patches"
HOMEPAGE="https://www.openssh.com/"
SRC_URI="mirror://openbsd/OpenSSH/portable/${PARCH}.tar.gz
	${HPN_VER:+hpn? (
		$(printf "https://downloads.sourceforge.net/project/hpnssh/Patches/${HPN_PATCH_DIR}/%s\n" "${HPN_PATCHES[@]}")
		https://dev.gentoo.org/~chutzpah/dist/openssh/${HPN_GLUE_PATCH}.xz
	)}
	${X509_VER:+X509? (
		https://roumenpetrov.info/openssh/x509-${X509_VER}/${X509_PATCH}
		https://dev.gentoo.org/~chutzpah/dist/openssh/${X509_GLUE_PATCH}.xz
		${HPN_VER:+hpn? ( https://dev.gentoo.org/~chutzpah/dist/openssh/${X509_HPN_GLUE_PATCH}.xz )}
	)}
	verify-sig? ( mirror://openbsd/OpenSSH/portable/${PARCH}.tar.gz.asc )
"
VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/openssh.org.asc
S="${WORKDIR}/${PARCH}"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="~amd64"
# Probably want to drop ssl defaulting to on in a future version.
IUSE="abi_mips_n32 audit debug hpn kerberos ldns libedit livecd pam +pie security-key selinux +ssl static test X X509 xmss"

RESTRICT="!test? ( test )"

REQUIRED_USE="
	hpn? ( ssl )
	ldns? ( ssl )
	pie? ( !static )
	static? ( !kerberos !pam )
	X509? ( ssl !xmss !security-key )
	xmss? ( ssl  )
	test? ( ssl )
"

# tests currently fail with XMSS
REQUIRED_USE+="test? ( !xmss )"

LIB_DEPEND="
	audit? ( sys-process/audit[static-libs(+)] )
	ldns? (
		net-libs/ldns[static-libs(+)]
		net-libs/ldns[ecdsa(+),ssl(+)]
	)
	libedit? ( dev-libs/libedit:=[static-libs(+)] )
	selinux? ( >=sys-libs/libselinux-1.28[static-libs(+)] )
	ssl? ( >=dev-libs/openssl-1.1.1l-r1:0=[static-libs(+)] )
	virtual/libcrypt:=[static-libs(+)]
	>=sys-libs/zlib-1.2.3:=[static-libs(+)]
"
RDEPEND="
	acct-group/sshd
	acct-user/sshd
	!static? ( ${LIB_DEPEND//\[static-libs(+)]} )
	pam? ( sys-libs/pam )
	kerberos? ( virtual/krb5 )
"
DEPEND="
	${RDEPEND}
	virtual/os-headers
	kernel_linux? ( !prefix-guest? ( >=sys-kernel/linux-headers-5.1 ) )
	static? ( ${LIB_DEPEND} )
"
RDEPEND="
	${RDEPEND}
	!net-misc/openssh
	pam? ( >=sys-auth/pambase-20081028 )
	!prefix? ( sys-apps/shadow )
"
BDEPEND="
	dev-build/autoconf
	virtual/pkgconfig
	verify-sig? ( sec-keys/openpgp-keys-openssh )
"

PATCHES=(
	"${FILESDIR}/openssh-9.4_p1-Allow-MAP_NORESERVE-in-sandbox-seccomp-filter-maps.patch"
	"${FILESDIR}/openssh-9.6_p1-fix-xmss-c99.patch"
	"${FILESDIR}/openssh-9.7_p1-config-tweaks.patch"
)

NON_X509_PATCHES=(
	"${FILESDIR}/openssh-9.6_p1-chaff-logic.patch"
	"${FILESDIR}/openssh-9.6_p1-CVE-2024-6387.patch"
)

pkg_pretend() {
	# this sucks, but i'd rather have people unable to `emerge -u openssh`
	# than not be able to log in to their server any more
	local missing=()
	check_feature() { use "${1}" && [[ -z ${!2} ]] && missing+=( "${1}" ); }
	check_feature hpn HPN_VER
	check_feature X509 X509_PATCH
	if [[ ${#missing[@]} -ne 0 ]] ; then
		eerror "Sorry, but this version does not yet support features"
		eerror "that you requested: ${missing[*]}"
		eerror "Please mask ${PF} for now and check back later:"
		eerror " # echo '=${CATEGORY}/${PF}' >> /etc/portage/package.mask"
		die "Missing requested third party patch."
	fi

	# Make sure people who are using tcp wrappers are notified of its removal. #531156
	if grep -qs '^ *sshd *:' "${EROOT}"/etc/hosts.{allow,deny} ; then
		ewarn "Sorry, but openssh no longer supports tcp-wrappers, and it seems like"
		ewarn "you're trying to use it.  Update your ${EROOT}/etc/hosts.{allow,deny} please."
	fi
}

src_unpack() {
	default

	# We don't have signatures for HPN, X509, so we have to write this ourselves
	use verify-sig && verify-sig_verify_detached "${DISTDIR}"/${PARCH}.tar.gz{,.asc}
}

src_prepare() {
	sed -i \
		-e "/_PATH_XAUTH/s:/usr/X11R6/bin/xauth:${EPREFIX}/usr/bin/xauth:" \
		pathnames.h || die

	# don't break .ssh/authorized_keys2 for fun
	sed -i '/^AuthorizedKeysFile/s:^:#:' sshd_config || die

	[[ -d ${WORKDIR}/patches ]] && PATCHES+=( "${WORKDIR}"/patches )

	eapply -- "${PATCHES[@]}"

	local PATCHSET_VERSION_MACROS=()

	if use X509 ; then
		pushd "${WORKDIR}" &>/dev/null || die
		eapply "${WORKDIR}/${X509_GLUE_PATCH}"
		eapply "${FILESDIR}/openssh-9.7_p1-X509-CVE-2024-6387.patch"
		popd &>/dev/null || die

		eapply "${WORKDIR}"/${X509_PATCH%.*}
		eapply "${FILESDIR}/openssh-9.0_p1-X509-uninitialized-delay.patch"

		# We need to patch package version or any X.509 sshd will reject our ssh client
		# with "userauth_pubkey: could not parse key: string is too large [preauth]"
		# error
		einfo "Patching package version for X.509 patch set ..."
		sed -i \
			-e "s/^AC_INIT(\[OpenSSH\], \[Portable\]/AC_INIT([OpenSSH], [${X509_VER}]/" \
			"${S}"/configure.ac || die "Failed to patch package version for X.509 patch"

		einfo "Patching version.h to expose X.509 patch set ..."
		sed -i \
			-e "/^#define SSH_PORTABLE.*/a #define SSH_X509               \"-PKIXSSH-${X509_VER}\"" \
			"${S}"/version.h || die "Failed to sed-in X.509 patch version"
		PATCHSET_VERSION_MACROS+=( 'SSH_X509' )
	else
		eapply "${NON_X509_PATCHES[@]}"
	fi

	if use hpn ; then
		local hpn_patchdir="${T}/openssh-${PV}-hpn${HPN_VER}"
		mkdir "${hpn_patchdir}" || die
		cp $(printf -- "${DISTDIR}/%s\n" "${HPN_PATCHES[@]}") "${hpn_patchdir}" || die
		pushd "${hpn_patchdir}" &>/dev/null || die
		eapply "${WORKDIR}/${HPN_GLUE_PATCH}"
		use X509 && eapply "${WORKDIR}/${X509_HPN_GLUE_PATCH}"
		popd &>/dev/null || die

		eapply "${hpn_patchdir}"

		use X509 || eapply "${FILESDIR}/openssh-9.6_p1-hpn-version.patch"

		einfo "Patching Makefile.in for HPN patch set ..."
		sed -i \
			-e "/^LIBS=/ s/\$/ -lpthread/" \
			"${S}"/Makefile.in || die "Failed to patch Makefile.in"

		einfo "Patching version.h to expose HPN patch set ..."
		sed -i \
			-e "/^#define SSH_PORTABLE/a #define SSH_HPN         \"-hpn${HPN_VER//./v}\"" \
			"${S}"/version.h || die "Failed to sed-in HPN patch version"
		PATCHSET_VERSION_MACROS+=( 'SSH_HPN' )

		if [[ -n "${HPN_DISABLE_MTAES}" ]] ; then
			# Before re-enabling, check https://bugs.gentoo.org/354113#c6
			# and be sure to have tested it.
			einfo "Disabling known non-working MT AES cipher per default ..."

			cat > "${T}"/disable_mtaes.conf <<- EOF

			# HPN's Multi-Threaded AES CTR cipher is currently known to be broken
			# and therefore disabled per default.
			DisableMTAES yes
			EOF
			sed -i \
				-e "/^#HPNDisabled.*/r ${T}/disable_mtaes.conf" \
				"${S}"/sshd_config || die "Failed to disabled MT AES ciphers in sshd_config"

			sed -i \
				-e "/AcceptEnv.*_XXX_TEST$/a \\\tDisableMTAES\t\tyes" \
				"${S}"/regress/test-exec.sh || die "Failed to disable MT AES ciphers in test config"
		fi
	fi

	if use X509 || use hpn ; then
		einfo "Patching sshconnect.c to use SSH_RELEASE in send_client_banner() ..."
		sed -i \
			-e "s/PROTOCOL_MAJOR_2, PROTOCOL_MINOR_2, SSH_VERSION/PROTOCOL_MAJOR_2, PROTOCOL_MINOR_2, SSH_RELEASE/" \
			"${S}"/sshconnect.c || die "Failed to patch send_client_banner() to use SSH_RELEASE (sshconnect.c)"

		einfo "Patching sshd.c to use SSH_RELEASE in sshd_exchange_identification() ..."
		sed -i \
			-e "s/PROTOCOL_MAJOR_2, PROTOCOL_MINOR_2, SSH_VERSION/PROTOCOL_MAJOR_2, PROTOCOL_MINOR_2, SSH_RELEASE/" \
			"${S}"/sshd.c || die "Failed to patch sshd_exchange_identification() to use SSH_RELEASE (sshd.c)"

		einfo "Patching version.h to add our patch sets to SSH_RELEASE ..."
		sed -i \
			-e "s/^#define SSH_RELEASE.*/#define SSH_RELEASE     SSH_VERSION SSH_PORTABLE ${PATCHSET_VERSION_MACROS[*]}/" \
			"${S}"/version.h || die "Failed to patch SSH_RELEASE (version.h)"
	fi

	eapply_user #473004

	# These tests are currently incompatible with PORTAGE_TMPDIR/sandbox
	sed -e '/\t\tpercent \\/ d' \
		-i regress/Makefile || die

	tc-export PKG_CONFIG
	local sed_args=(
		-e "s:-lcrypto:$(${PKG_CONFIG} --libs openssl):"
		# Disable fortify flags ... our gcc does this for us
		-e 's:-D_FORTIFY_SOURCE=2::'
	)

	# _XOPEN_SOURCE causes header conflicts on Solaris
	[[ ${CHOST} == *-solaris* ]] && sed_args+=(
		-e 's/-D_XOPEN_SOURCE//'
	)
	sed -i "${sed_args[@]}" configure{.ac,} || die

	eautoreconf
}

src_configure() {
	addwrite /dev/ptmx

	use debug && append-cppflags -DSANDBOX_SECCOMP_FILTER_DEBUG
	use static && append-ldflags -static
	use xmss && append-cflags -DWITH_XMSS

	if [[ ${CHOST} == *-solaris* ]] ; then
		# Solaris' glob.h doesn't have things like GLOB_TILDE, configure
		# doesn't check for this, so force the replacement to be put in
		# place
		append-cppflags -DBROKEN_GLOB
	fi

	# use replacement, RPF_ECHO_ON doesn't exist here
	[[ ${CHOST} == *-darwin* ]] && export ac_cv_func_readpassphrase=no

	local myconf=(
		--with-ldflags="${LDFLAGS}"
		--disable-strip
		--with-pid-dir="${EPREFIX}"$(usex kernel_linux '' '/var')/run
		--sysconfdir="${EPREFIX}"/etc/ssh
		--libexecdir="${EPREFIX}"/usr/$(get_libdir)/misc
		--datadir="${EPREFIX}"/usr/share/openssh
		--with-privsep-path="${EPREFIX}"/var/empty
		--with-privsep-user=sshd
		# optional at runtime; guarantee a known path
		--with-xauth="${EPREFIX}"/usr/bin/xauth

		# --with-hardening adds the following in addition to flags we
		# already set in our toolchain:
		# * -ftrapv (which is broken with GCC anyway),
		# * -ftrivial-auto-var-init=zero (which is nice, but not the end of
		#    the world to not have)
		# * -fzero-call-used-regs=used (history of miscompilations with
		#    Clang (bug #872548), ICEs on m68k (bug #920350, gcc PR113086,
		#    gcc PR104820, gcc PR104817, gcc PR110934)).
		#
		# Furthermore, OSSH_CHECK_CFLAG_COMPILE does not use AC_CACHE_CHECK,
		# so we cannot just disable -fzero-call-used-regs=used.
		#
		# Therefore, just pass --without-hardening, given it doesn't negate
		# our already hardened toolchain defaults, and avoids adding flags
		# which are known-broken in both Clang and GCC and haven't been
		# proven reliable.
		--without-hardening

		$(use_with audit audit linux)
		$(use_with kerberos kerberos5 "${EPREFIX}"/usr)
		$(use_with ldns)
		$(use_with libedit)
		$(use_with pam)
		$(use_with pie)
		$(use_with selinux)
		$(use_with security-key security-key-builtin)
		$(usex X509 '' "$(use_with security-key security-key-builtin)")
		$(use_with ssl openssl)
		$(use_with ssl ssl-engine)
	)

	if use elibc_musl; then
		# musl defines bogus values for UTMP_FILE and WTMP_FILE
		myconf+=( --disable-utmp --disable-wtmp )
	fi

	# Workaround for Clang 15 miscompilation with -fzero-call-used-regs=all
	# bug #869839 (https://github.com/llvm/llvm-project/issues/57692)
	tc-is-clang && myconf+=( --without-hardening )

	econf "${myconf[@]}"
}

create_config_dropins() {
	local locale_vars=(
		# These are language variables that POSIX defines.
		# http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html#tag_08_02
		LANG LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC LC_TIME

		# These are the GNU extensions.
		# https://www.gnu.org/software/autoconf/manual/html_node/Special-Shell-Variables.html
		LANGUAGE LC_ADDRESS LC_IDENTIFICATION LC_MEASUREMENT LC_NAME LC_PAPER LC_TELEPHONE
	)

	mkdir -p "${WORKDIR}"/etc/ssh/ssh{,d}_config.d || die

	cat <<-EOF > "${WORKDIR}"/etc/ssh/ssh_config.d/9999999gentoo.conf || die
	# Send locale environment variables (bug #367017)
	SendEnv ${locale_vars[*]}

	# Send COLORTERM to match TERM (bug #658540)
	SendEnv COLORTERM
	EOF

	cat <<-EOF > "${WORKDIR}"/etc/ssh/ssh_config.d/9999999gentoo-security.conf || die
	RevokedHostKeys "${EPREFIX}/etc/ssh/ssh_revoked_hosts"
	EOF

	cat <<-EOF > "${WORKDIR}"/etc/ssh/ssh_revoked_hosts || die
	# https://github.blog/2023-03-23-we-updated-our-rsa-ssh-host-key/
	ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
	EOF

	cat <<-EOF > "${WORKDIR}"/etc/ssh/sshd_config.d/9999999gentoo.conf || die
	# Allow client to pass locale environment variables (bug #367017)
	AcceptEnv ${locale_vars[*]}

	# Allow client to pass COLORTERM to match TERM (bug #658540)
	AcceptEnv COLORTERM
	EOF

	cat <<-EOF > "${WORKDIR}"/etc/ssh/sshd_config.d/9999999gentoo-subsystem.conf || die
	# override default of no subsystems
	Subsystem	sftp	${EPREFIX}/usr/$(get_libdir)/misc/sftp-server
	EOF

	if use pam ; then
		cat <<-EOF > "${WORKDIR}"/etc/ssh/sshd_config.d/9999999gentoo-pam.conf || die
		UsePAM yes
		# This interferes with PAM.
		PasswordAuthentication no
		# PAM can do its own handling of MOTD.
		PrintMotd no
		PrintLastLog no
		EOF
	fi

	if use livecd ; then
		cat <<-EOF > "${WORKDIR}"/etc/ssh/sshd_config.d/9999999gentoo-livecd.conf || die
		# Allow root login with password on livecds.
		PermitRootLogin Yes
		EOF
	fi
}

src_compile() {
	default
	create_config_dropins
}

src_test() {
	local tests=( compat-tests )
	local shell=$(egetshell "${UID}")
	if [[ ${shell} == */nologin ]] || [[ ${shell} == */false ]] ; then
		ewarn "Running the full OpenSSH testsuite requires a usable shell for the 'portage'"
		ewarn "user, so we will run a subset only."
		tests+=( interop-tests )
	else
		tests+=( tests )
	fi

	local -x SUDO= SSH_SK_PROVIDER= TEST_SSH_UNSAFE_PERMISSIONS=1 REGRESS_INTEROP_PUTTY=1
	mkdir -p "${HOME}"/.ssh || die
	emake -j1 "${tests[@]}" </dev/null
}

src_install() {
	emake install-nokeys DESTDIR="${D}"
	fperms 600 /etc/ssh/sshd_config
	dobin contrib/ssh-copy-id
	newinitd "${FILESDIR}"/sshd-r1.initd sshd
	newconfd "${FILESDIR}"/sshd-r1.confd sshd

	if use pam; then
		newpamd "${FILESDIR}"/sshd.pam_include.2 sshd
	fi

	doman contrib/ssh-copy-id.1
	dodoc CREDITS OVERVIEW README* TODO sshd_config
	use hpn && dodoc HPN-README
	use X509 || dodoc ChangeLog

	rmdir "${ED}"/var/empty || die

	systemd_dounit "${FILESDIR}"/sshd.socket
	systemd_newunit "${FILESDIR}"/sshd.service.1 sshd.service
	systemd_newunit "${FILESDIR}"/sshd_at.service.1 'sshd@.service'

	# Install dropins with explicit mode, bug 906638, 915840
	diropts -m0755
	insopts -m0644
	insinto /etc/ssh
	doins -r "${WORKDIR}"/etc/ssh/ssh_config.d
	diropts -m0700
	insopts -m0600
	doins -r "${WORKDIR}"/etc/ssh/sshd_config.d
}

pkg_preinst() {
	if ! use ssl && has_version "${CATEGORY}/${PN}[ssl]"; then
		show_ssl_warning=1
	fi
}

pkg_postinst() {
	# bug #139235
	optfeature "x11 forwarding" x11-apps/xauth

	if ver_replacing -lt "5.8_p1"; then
		elog "Starting with openssh-5.8p1, the server will default to a newer key"
		elog "algorithm (ECDSA).  You are encouraged to manually update your stored"
		elog "keys list as servers update theirs.  See ssh-keyscan(1) for more info."
	fi
	if ver_replacing -lt "7.0_p1"; then
		elog "Starting with openssh-6.7, support for USE=tcpd has been dropped by upstream."
		elog "Make sure to update any configs that you might have.  Note that xinetd might"
		elog "be an alternative for you as it supports USE=tcpd."
	fi
	if ver_replacing -lt "7.1_p1"; then #557388 #555518
		elog "Starting with openssh-7.0, support for ssh-dss keys were disabled due to their"
		elog "weak sizes.  If you rely on these key types, you can re-enable the key types by"
		elog "adding to your sshd_config or ~/.ssh/config files:"
		elog "	PubkeyAcceptedKeyTypes=+ssh-dss"
		elog "You should however generate new keys using rsa or ed25519."

		elog "Starting with openssh-7.0, the default for PermitRootLogin changed from 'yes'"
		elog "to 'prohibit-password'.  That means password auth for root users no longer works"
		elog "out of the box.  If you need this, please update your sshd_config explicitly."
	fi
	if ver_replacing -lt "7.6_p1"; then
		elog "Starting with openssh-7.6p1, openssh upstream has removed ssh1 support entirely."
		elog "Furthermore, rsa keys with less than 1024 bits will be refused."
	fi
	if ver_replacing -lt "7.7_p1"; then
		elog "Starting with openssh-7.7p1, we no longer patch openssh to provide LDAP functionality."
		elog "Install sys-auth/ssh-ldap-pubkey and use OpenSSH's \"AuthorizedKeysCommand\" option"
		elog "if you need to authenticate against LDAP."
		elog "See https://wiki.gentoo.org/wiki/SSH/LDAP_migration for more details."
	fi
	if ver_replacing -lt "8.2_p1"; then
		ewarn "After upgrading to openssh-8.2p1 please restart sshd, otherwise you"
		ewarn "will not be able to establish new sessions. Restarting sshd over a ssh"
		ewarn "connection is generally safe."
	fi
	if ver_replacing -lt "9.2_p1-r1" && systemd_is_booted; then
		ewarn "From openssh-9.2_p1-r1 the supplied systemd unit file defaults to"
		ewarn "'Restart=on-failure', which causes the service to automatically restart if it"
		ewarn "terminates with an unclean exit code or signal. This feature is useful for most users,"
		ewarn "but it can increase the vulnerability of the system in the event of a future exploit."
		ewarn "If you have a web-facing setup or are concerned about security, it is recommended to"
		ewarn "set 'Restart=no' in your sshd unit file."
	fi

	if [[ -n ${show_ssl_warning} ]]; then
		elog "Be aware that by disabling openssl support in openssh, the server and clients"
		elog "no longer support dss/rsa/ecdsa keys.  You will need to generate ed25519 keys"
		elog "and update all clients/servers that utilize them."
	fi

	if use hpn && [[ -n "${HPN_DISABLE_MTAES}" ]] ; then
		elog ""
		elog "HPN's multi-threaded AES CTR cipher is currently known to be broken"
		elog "and therefore disabled at runtime per default."
		elog "Make sure your sshd_config is up to date and contains"
		elog ""
		elog "  DisableMTAES yes"
		elog ""
		elog "Otherwise you maybe unable to connect to this sshd using any AES CTR cipher."
		elog ""
	fi
}

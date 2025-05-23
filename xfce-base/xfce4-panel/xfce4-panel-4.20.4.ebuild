# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit vala xdg-utils

DESCRIPTION="Panel for the Xfce desktop environment"
HOMEPAGE="
	https://docs.xfce.org/xfce/xfce4-panel/start
	https://gitlab.xfce.org/xfce/xfce4-panel/
"
SRC_URI="https://archive.xfce.org/src/xfce/${PN}/${PV%.*}/${P}.tar.bz2"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="amd64 arm arm64 ~hppa ~loong ~mips ppc ppc64 ~riscv ~sparc x86"
IUSE="+dbusmenu introspection vala wayland X"
REQUIRED_USE="
	|| ( wayland X )
	vala? ( introspection )
"

DEPEND="
	>=dev-libs/glib-2.72.0
	>=x11-libs/cairo-1.16.0
	>=x11-libs/gtk+-3.24.0:3[X?,introspection?,wayland?]
	>=xfce-base/exo-4.18.0:=
	>=xfce-base/garcon-4.18.0:=
	>=xfce-base/libxfce4ui-4.18.0:=
	>=xfce-base/libxfce4util-4.18.0:=[introspection?,vala?]
	>=xfce-base/libxfce4windowing-4.20.1:=[X?]
	>=xfce-base/xfconf-4.18.0:=
	dbusmenu? ( >=dev-libs/libdbusmenu-16.04.0[gtk3] )
	introspection? ( >=dev-libs/gobject-introspection-1.66:= )
	wayland? (
		>=dev-libs/wayland-1.20
		>=gui-libs/gtk-layer-shell-0.7.0
	)
	X? (
		>=x11-libs/libX11-1.6.7
		>=x11-libs/libXext-1.0.0
		x11-libs/libwnck:3
	)
"
RDEPEND="
	${DEPEND}
"
BDEPEND="
	vala? ( $(vala_depend) )
	dev-build/xfce4-dev-tools
	dev-lang/perl
	dev-util/gdbus-codegen
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
"

src_configure() {
	local myconf=(
		$(use_enable introspection)
		$(use_enable dbusmenu dbusmenu-gtk3)
		$(use_enable vala)
		$(use_enable wayland)
		$(use_enable wayland gtk-layer-shell)
		$(use_enable X x11)
	)

	use vala && vala_setup
	econf "${myconf[@]}"
}

src_install() {
	default
	find "${D}" -name '*.la' -delete || die
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

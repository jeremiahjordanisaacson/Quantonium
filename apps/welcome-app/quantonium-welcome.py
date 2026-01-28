#!/usr/bin/env python3
"""
Quantonium Welcome App
A first-run experience application for Quantonium OS
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio, GLib, Gdk
import subprocess
import os
import webbrowser

class WelcomeWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.set_title("Welcome to Quantonium")
        self.set_default_size(900, 650)
        self.set_resizable(False)

        # Main container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_content(main_box)

        # Header bar
        header = Adw.HeaderBar()
        header.set_show_end_title_buttons(True)
        header.set_show_start_title_buttons(True)
        main_box.append(header)

        # Add autostart toggle
        autostart_button = Gtk.CheckButton(label="Show at startup")
        autostart_button.set_active(self.get_autostart_enabled())
        autostart_button.connect("toggled", self.on_autostart_toggled)
        header.pack_end(autostart_button)

        # Create view stack
        self.stack = Adw.ViewStack()
        self.stack.set_vexpand(True)

        # View switcher bar (bottom)
        switcher = Adw.ViewSwitcherBar()
        switcher.set_stack(self.stack)
        switcher.set_reveal(True)

        # Add pages
        self.add_welcome_page()
        self.add_features_page()
        self.add_apps_page()
        self.add_customize_page()
        self.add_help_page()

        main_box.append(self.stack)
        main_box.append(switcher)

    def add_welcome_page(self):
        """Create the welcome/landing page"""
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        page.set_margin_top(40)
        page.set_margin_bottom(40)
        page.set_margin_start(60)
        page.set_margin_end(60)
        page.set_valign(Gtk.Align.CENTER)
        page.set_halign(Gtk.Align.CENTER)

        # Logo
        logo = Gtk.Image.new_from_icon_name("quantonium-logo")
        logo.set_pixel_size(128)
        page.append(logo)

        # Title
        title = Gtk.Label(label="Welcome to Quantonium")
        title.add_css_class("title-1")
        page.append(title)

        # Subtitle
        subtitle = Gtk.Label(label="The Future of Desktop Linux")
        subtitle.add_css_class("dim-label")
        page.append(subtitle)

        # Description
        desc = Gtk.Label(
            label="Thank you for choosing Quantonium OS!\n"
                  "Take a moment to explore your new system and make it yours."
        )
        desc.set_justify(Gtk.Justification.CENTER)
        desc.set_wrap(True)
        desc.set_max_width_chars(60)
        desc.set_margin_top(20)
        page.append(desc)

        # Quick actions
        actions_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        actions_box.set_halign(Gtk.Align.CENTER)
        actions_box.set_margin_top(30)

        # Tour button
        tour_btn = Gtk.Button(label="Take a Tour")
        tour_btn.add_css_class("suggested-action")
        tour_btn.add_css_class("pill")
        tour_btn.connect("clicked", self.on_tour_clicked)
        actions_box.append(tour_btn)

        # Release notes button
        notes_btn = Gtk.Button(label="Release Notes")
        notes_btn.add_css_class("pill")
        notes_btn.connect("clicked", self.on_release_notes_clicked)
        actions_box.append(notes_btn)

        page.append(actions_box)

        self.stack.add_titled_with_icon(page, "welcome", "Welcome", "go-home-symbolic")

    def add_features_page(self):
        """Create the features overview page"""
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(800)

        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(30)
        page.set_margin_bottom(30)
        page.set_margin_start(20)
        page.set_margin_end(20)

        # Title
        title = Gtk.Label(label="What's New in Quantonium 1.0")
        title.add_css_class("title-2")
        title.set_halign(Gtk.Align.START)
        page.append(title)

        # Feature cards
        features = [
            ("Quantum Design", "Beautiful, cohesive visual design with dark and light themes",
             "preferences-desktop-theme-symbolic"),
            ("Ubuntu-Style Workflow", "Familiar dock-based workflow with app indicators and desktop icons",
             "preferences-desktop-symbolic"),
            ("Privacy First", "No telemetry, no tracking. Your data stays yours.",
             "security-high-symbolic"),
            ("Latest Software", "GNOME 46, Linux 6.8 kernel, and cutting-edge applications",
             "system-software-update-symbolic"),
            ("Developer Ready", "Pre-configured with popular development tools and languages",
             "utilities-terminal-symbolic"),
            ("Flatpak & Snap", "Access thousands of apps from multiple sources",
             "system-software-install-symbolic"),
        ]

        listbox = Gtk.ListBox()
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        listbox.add_css_class("boxed-list")

        for name, desc, icon in features:
            row = Adw.ActionRow()
            row.set_title(name)
            row.set_subtitle(desc)

            icon_widget = Gtk.Image.new_from_icon_name(icon)
            icon_widget.set_pixel_size(32)
            row.add_prefix(icon_widget)

            listbox.append(row)

        page.append(listbox)

        clamp.set_child(page)
        scroll.set_child(clamp)

        self.stack.add_titled_with_icon(scroll, "features", "Features", "starred-symbolic")

    def add_apps_page(self):
        """Create the default apps page"""
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(800)

        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(30)
        page.set_margin_bottom(30)
        page.set_margin_start(20)
        page.set_margin_end(20)

        # Title
        title = Gtk.Label(label="Your Default Applications")
        title.add_css_class("title-2")
        title.set_halign(Gtk.Align.START)
        page.append(title)

        # App categories
        categories = [
            ("Internet", [
                ("Firefox", "Web Browser", "firefox", "firefox.desktop"),
                ("Thunderbird", "Email Client", "thunderbird", "thunderbird.desktop"),
            ]),
            ("Office", [
                ("LibreOffice Writer", "Documents", "libreoffice-writer", "libreoffice-writer.desktop"),
                ("LibreOffice Calc", "Spreadsheets", "libreoffice-calc", "libreoffice-calc.desktop"),
            ]),
            ("Media", [
                ("Rhythmbox", "Music Player", "rhythmbox", "rhythmbox.desktop"),
                ("Videos", "Video Player", "totem", "org.gnome.Totem.desktop"),
            ]),
            ("Utilities", [
                ("Files", "File Manager", "org.gnome.Nautilus", "org.gnome.Nautilus.desktop"),
                ("Terminal", "Command Line", "utilities-terminal", "org.gnome.Terminal.desktop"),
            ]),
        ]

        for category_name, apps in categories:
            # Category label
            cat_label = Gtk.Label(label=category_name)
            cat_label.add_css_class("heading")
            cat_label.set_halign(Gtk.Align.START)
            cat_label.set_margin_top(10)
            page.append(cat_label)

            listbox = Gtk.ListBox()
            listbox.set_selection_mode(Gtk.SelectionMode.NONE)
            listbox.add_css_class("boxed-list")

            for app_name, app_desc, app_icon, desktop_file in apps:
                row = Adw.ActionRow()
                row.set_title(app_name)
                row.set_subtitle(app_desc)
                row.set_activatable(True)
                row.connect("activated", self.on_app_row_activated, desktop_file)

                icon_widget = Gtk.Image.new_from_icon_name(app_icon)
                icon_widget.set_pixel_size(32)
                row.add_prefix(icon_widget)

                arrow = Gtk.Image.new_from_icon_name("go-next-symbolic")
                row.add_suffix(arrow)

                listbox.append(row)

            page.append(listbox)

        # Software Center button
        software_btn = Gtk.Button(label="Open Software Center")
        software_btn.add_css_class("suggested-action")
        software_btn.add_css_class("pill")
        software_btn.set_halign(Gtk.Align.CENTER)
        software_btn.set_margin_top(20)
        software_btn.connect("clicked", self.on_software_center_clicked)
        page.append(software_btn)

        clamp.set_child(page)
        scroll.set_child(clamp)

        self.stack.add_titled_with_icon(scroll, "apps", "Apps", "view-app-grid-symbolic")

    def add_customize_page(self):
        """Create the customization page"""
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(800)

        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(30)
        page.set_margin_bottom(30)
        page.set_margin_start(20)
        page.set_margin_end(20)

        # Title
        title = Gtk.Label(label="Make It Yours")
        title.add_css_class("title-2")
        title.set_halign(Gtk.Align.START)
        page.append(title)

        # Quick settings
        options = [
            ("Appearance", "Change themes and colors", "preferences-desktop-theme-symbolic",
             "gnome-control-center appearance"),
            ("Background", "Set your wallpaper", "preferences-desktop-wallpaper-symbolic",
             "gnome-control-center background"),
            ("Displays", "Configure monitors", "video-display-symbolic",
             "gnome-control-center display"),
            ("Keyboard Shortcuts", "Customize shortcuts", "preferences-desktop-keyboard-shortcuts-symbolic",
             "gnome-control-center keyboard"),
            ("Extensions", "Add GNOME extensions", "application-x-addon-symbolic",
             "gnome-extensions-app"),
            ("GNOME Tweaks", "Advanced customization", "org.gnome.tweaks-symbolic",
             "gnome-tweaks"),
        ]

        listbox = Gtk.ListBox()
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        listbox.add_css_class("boxed-list")

        for opt_name, opt_desc, opt_icon, opt_cmd in options:
            row = Adw.ActionRow()
            row.set_title(opt_name)
            row.set_subtitle(opt_desc)
            row.set_activatable(True)
            row.connect("activated", self.on_settings_row_activated, opt_cmd)

            icon_widget = Gtk.Image.new_from_icon_name(opt_icon)
            icon_widget.set_pixel_size(32)
            row.add_prefix(icon_widget)

            arrow = Gtk.Image.new_from_icon_name("go-next-symbolic")
            row.add_suffix(arrow)

            listbox.append(row)

        page.append(listbox)

        # All Settings button
        settings_btn = Gtk.Button(label="All Settings")
        settings_btn.add_css_class("suggested-action")
        settings_btn.add_css_class("pill")
        settings_btn.set_halign(Gtk.Align.CENTER)
        settings_btn.set_margin_top(20)
        settings_btn.connect("clicked", self.on_all_settings_clicked)
        page.append(settings_btn)

        clamp.set_child(page)
        scroll.set_child(clamp)

        self.stack.add_titled_with_icon(scroll, "customize", "Customize", "preferences-system-symbolic")

    def add_help_page(self):
        """Create the help and resources page"""
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(800)

        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(30)
        page.set_margin_bottom(30)
        page.set_margin_start(20)
        page.set_margin_end(20)

        # Title
        title = Gtk.Label(label="Help & Support")
        title.add_css_class("title-2")
        title.set_halign(Gtk.Align.START)
        page.append(title)

        # Resources
        resources = [
            ("Documentation", "Learn how to use Quantonium", "help-browser-symbolic",
             "https://docs.quantonium.io"),
            ("Community Forum", "Connect with other users", "system-users-symbolic",
             "https://community.quantonium.io"),
            ("Report a Bug", "Help us improve", "dialog-error-symbolic",
             "https://github.com/quantonium/quantonium-os/issues"),
            ("Contribute", "Get involved in development", "face-smile-big-symbolic",
             "https://github.com/quantonium/quantonium-os"),
        ]

        listbox = Gtk.ListBox()
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        listbox.add_css_class("boxed-list")

        for res_name, res_desc, res_icon, res_url in resources:
            row = Adw.ActionRow()
            row.set_title(res_name)
            row.set_subtitle(res_desc)
            row.set_activatable(True)
            row.connect("activated", self.on_url_row_activated, res_url)

            icon_widget = Gtk.Image.new_from_icon_name(res_icon)
            icon_widget.set_pixel_size(32)
            row.add_prefix(icon_widget)

            link_icon = Gtk.Image.new_from_icon_name("external-link-symbolic")
            row.add_suffix(link_icon)

            listbox.append(row)

        page.append(listbox)

        # System Info section
        info_label = Gtk.Label(label="System Information")
        info_label.add_css_class("heading")
        info_label.set_halign(Gtk.Align.START)
        info_label.set_margin_top(20)
        page.append(info_label)

        info_listbox = Gtk.ListBox()
        info_listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        info_listbox.add_css_class("boxed-list")

        # Get system info
        system_info = self.get_system_info()
        for key, value in system_info:
            row = Adw.ActionRow()
            row.set_title(key)
            row.set_subtitle(value)
            info_listbox.append(row)

        page.append(info_listbox)

        clamp.set_child(page)
        scroll.set_child(clamp)

        self.stack.add_titled_with_icon(scroll, "help", "Help", "help-about-symbolic")

    def get_system_info(self):
        """Get system information"""
        info = []

        # OS version
        try:
            with open('/etc/os-release') as f:
                for line in f:
                    if line.startswith('PRETTY_NAME='):
                        name = line.split('=')[1].strip().strip('"')
                        info.append(("Operating System", name))
                        break
        except:
            info.append(("Operating System", "Quantonium OS 1.0"))

        # Kernel version
        try:
            kernel = subprocess.check_output(['uname', '-r']).decode().strip()
            info.append(("Kernel", kernel))
        except:
            info.append(("Kernel", "Unknown"))

        # Desktop environment
        desktop = os.environ.get('XDG_CURRENT_DESKTOP', 'Unknown')
        info.append(("Desktop", desktop))

        # Session type
        session = os.environ.get('XDG_SESSION_TYPE', 'Unknown')
        info.append(("Session Type", session.capitalize()))

        return info

    def get_autostart_enabled(self):
        """Check if autostart is enabled"""
        autostart_file = os.path.expanduser(
            "~/.config/autostart/quantonium-welcome.desktop"
        )
        return os.path.exists(autostart_file)

    def on_autostart_toggled(self, button):
        """Handle autostart toggle"""
        autostart_dir = os.path.expanduser("~/.config/autostart")
        autostart_file = os.path.join(autostart_dir, "quantonium-welcome.desktop")

        if button.get_active():
            # Enable autostart
            os.makedirs(autostart_dir, exist_ok=True)
            desktop_content = """[Desktop Entry]
Type=Application
Name=Quantonium Welcome
Exec=quantonium-welcome
Icon=quantonium-logo
Terminal=false
Categories=Utility;
"""
            with open(autostart_file, 'w') as f:
                f.write(desktop_content)
        else:
            # Disable autostart
            try:
                os.remove(autostart_file)
            except FileNotFoundError:
                pass

    def on_tour_clicked(self, button):
        """Launch GNOME Tour"""
        try:
            subprocess.Popen(['gnome-tour'])
        except FileNotFoundError:
            print("GNOME Tour not found")

    def on_release_notes_clicked(self, button):
        """Open release notes"""
        webbrowser.open("https://quantonium.io/releases/1.0")

    def on_app_row_activated(self, row, desktop_file):
        """Launch application from desktop file"""
        try:
            subprocess.Popen(['gtk-launch', desktop_file])
        except:
            pass

    def on_settings_row_activated(self, row, command):
        """Open settings panel"""
        try:
            subprocess.Popen(command.split())
        except:
            pass

    def on_url_row_activated(self, row, url):
        """Open URL in browser"""
        webbrowser.open(url)

    def on_software_center_clicked(self, button):
        """Open software center"""
        try:
            subprocess.Popen(['gnome-software'])
        except:
            pass

    def on_all_settings_clicked(self, button):
        """Open all settings"""
        try:
            subprocess.Popen(['gnome-control-center'])
        except:
            pass


class WelcomeApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="io.quantonium.welcome",
            flags=Gio.ApplicationFlags.FLAGS_NONE
        )

    def do_activate(self):
        win = self.props.active_window
        if not win:
            win = WelcomeWindow(application=self)
        win.present()


def main():
    app = WelcomeApp()
    return app.run(None)


if __name__ == "__main__":
    main()

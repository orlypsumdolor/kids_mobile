#!/usr/bin/env python3
"""Generate a non-technical volunteer guide PDF for the Kids Church check-in app."""

from io import BytesIO
from pathlib import Path

from fpdf import FPDF

from flow_diagram_images import (
    diagram_attendance,
    diagram_camera_qr,
    diagram_checkout,
    diagram_guardian_checkin,
    diagram_main_menu_roles,
    diagram_one_child_optional,
    diagram_open_app,
    diagram_settings,
    diagram_sign_in,
    diagram_troubleshooting,
)

OUT_PATH = Path(__file__).resolve().parent.parent / "docs" / "Kids_Church_Check-In_App_Volunteer_Guide.pdf"


class GuidePDF(FPDF):
    def __init__(self) -> None:
        super().__init__()
        self.set_auto_page_break(auto=True, margin=18)
        self.set_margins(left=18, top=18, right=18)

    def _text_width(self) -> float:
        return self.w - self.l_margin - self.r_margin

    def title_block(self, title: str, subtitle: str = "") -> None:
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "B", 20)
        self.multi_cell(self._text_width(), 10, title)
        self.ln(2)
        if subtitle:
            self.set_x(self.l_margin)
            self.set_font("Helvetica", "", 12)
            self.multi_cell(self._text_width(), 6, subtitle)
        self.ln(8)

    def section(self, heading: str) -> None:
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "B", 14)
        self.multi_cell(self._text_width(), 8, heading)
        self.ln(2)

    def paragraph(self, text: str) -> None:
        self.set_x(self.l_margin)
        self.set_font("Helvetica", "", 11)
        self.multi_cell(self._text_width(), 6, text)
        self.ln(4)

    def bullets(self, lines: list[str]) -> None:
        self.set_font("Helvetica", "", 11)
        w = self._text_width()
        for line in lines:
            self.set_x(self.l_margin)
            self.multi_cell(w, 6, f"- {line}")
        self.ln(4)

    def diagram(self, image_buf: BytesIO, caption: str = "") -> None:
        """Embed a PNG flow diagram; keeps width within printable margins."""
        self.ln(3)
        self.set_x(self.l_margin)
        img_w = self._text_width()
        self.image(image_buf, x=self.l_margin, w=img_w)
        if caption:
            self.ln(2)
            self.set_font("Helvetica", "I", 9)
            self.set_x(self.l_margin)
            self.multi_cell(self._text_width(), 5, caption)
        self.ln(5)


def build_pdf() -> None:
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    pdf = GuidePDF()
    pdf.add_page()

    pdf.title_block(
        "Kids Church Check-In App",
        "Volunteer guide: what happens on the kiosk, step by step.\n"
        "This booklet is written in plain language for greeters and check-in helpers.",
    )

    pdf.section("When you first open the app")
    pdf.paragraph(
        "The app shows a short welcome screen while it wakes up. After that, one of two things happens:"
    )
    pdf.bullets(
        [
            "If a staff member is already signed in on this device, you go straight to the main menu.",
            "If nobody is signed in, you see the sign-in screen. Enter the username and password your church gave you, then tap Sign In.",
        ]
    )
    pdf.paragraph(
        "If the password is wrong, read the message on the screen and try again. When sign-in works, you land on the main menu."
    )
    pdf.paragraph(
        "To leave: use Sign out from the menu at the top. The gear icon opens Settings (for example, the printer)."
    )
    pdf.diagram(
        diagram_open_app(),
        "Flow overview: from opening the app to the main menu or sign-in.",
    )
    pdf.diagram(
        diagram_sign_in(),
        "Detail when you land on sign-in: fill the form, then success or try again.",
    )

    pdf.section("Who sees which buttons on the main menu")
    pdf.paragraph("Not every login sees the same choices. In general:")
    pdf.bullets(
        [
            "Door volunteers usually see Guardian check-in and Check-out.",
            "Some staff logins also see attendance or summary-style reports.",
            "Head admins may see extra shortcuts, including Settings under an admin area.",
        ]
    )
    pdf.paragraph(
        "Everyone signed in can use the gear icon for Settings and the menu for Sign out."
    )
    pdf.diagram(
        diagram_main_menu_roles(),
        "Illustration: helpers usually see check-in and check-out; everyone can open Settings from the gear.",
    )

    pdf.section("Guardian check-in (families arriving)")
    pdf.paragraph(
        "This is the usual path when a parent or guardian brings children for the service."
    )
    pdf.bullets(
        [
            "Open Guardian check-in from the main menu.",
            "If the screen says the printer is not ready, follow the on-screen steps or go to Settings and connect the label printer first. Stickers and pickup slips need the printer.",
            "When the printer is ready, scan the guardian's QR code with the built-in kiosk scanner, or use the camera option if your team uses that.",
            "If the code is not recognized, you will see an error. Try scanning again or ask a leader for help.",
            "When it works, you see the adult's name and the children linked to them.",
            "Choose the service (if asked) and select which children are checking in.",
            "Confirm check-in. You should see a success message, and stickers should print for the children.",
            "The screen then clears so the next family can step up.",
        ]
    )
    pdf.diagram(
        diagram_guardian_checkin(),
        "Diagram: printer check, scan family, confirm, print, reset for the next family.",
    )

    pdf.section("Check-out (pickup time)")
    pdf.paragraph(
        "When a family leaves, someone authorized to pick up the children should have the pickup slip with a QR code."
    )
    pdf.bullets(
        [
            "Open Check-out from the main menu.",
            "Scan that pickup slip QR code with the kiosk scanner, or use the camera button if your process uses it.",
            "If the slip is wrong or damaged, the app will say so. Scan again or get help from a leader.",
            "When the scan is good, the screen lists the children and their pickup codes so you can double-check.",
            "If something is wrong, use Cancel or Start over and scan again.",
            "When everything matches, confirm check-out. The app marks those children as picked up and shows a success message.",
            "Then you are ready for the next family.",
        ]
    )
    pdf.diagram(
        diagram_checkout(),
        "Diagram: scan slip, confirm details, complete check-out, next family.",
    )

    pdf.section("Using the camera for a QR code")
    pdf.paragraph(
        "Sometimes the app opens the device camera to read a QR code. The first time, the tablet may ask for camera permission. Allow it if your church uses camera scanning. Point the camera at the code until it reads; then the camera screen closes and the app continues where you left off."
    )
    pdf.diagram(
        diagram_camera_qr(),
        "Diagram: camera permission, then scan, then return to the task you were doing.",
    )

    pdf.section("Attendance summary (if you have it)")
    pdf.paragraph(
        "Some accounts can open a screen that shows who checked in or out for a chosen day. Use the date controls on that screen to change the day. If the list looks like sample names, your church may still be connecting this screen to live data; ask a leader."
    )
    pdf.diagram(
        diagram_attendance(),
        "Diagram: open summary, pick date, read the list.",
    )

    pdf.section("Settings")
    pdf.paragraph(
        "Settings is where you connect or change the receipt or label printer (USB or Bluetooth, depending on your kiosk). Other switches on that screen are set by your church. If you are not sure what to change, ask an admin before adjusting anything."
    )
    pdf.diagram(
        diagram_settings(),
        "Diagram: Settings leads to printer setup and other admin-only options.",
    )

    pdf.section("One-child check-in (optional screen)")
    pdf.paragraph(
        "The app may also support a separate flow where you scan one child's code at a time, pick a service, and check that child in. That screen might not appear on your main menu; your church decides whether to use it. If you never see it, you can ignore this note."
    )
    pdf.diagram(
        diagram_one_child_optional(),
        "Optional linear flow when your church enables per-child check-in.",
    )

    pdf.section("If something goes wrong")
    pdf.bullets(
        [
            "Printer will not print: open Settings, check the printer connection, paper, and power.",
            "Scan never works: clean the scanner window, hold the code steady, try the camera option if allowed.",
            "Wrong family or child: use Start over or back, then scan again. When in doubt, call a leader.",
        ]
    )
    pdf.diagram(
        diagram_troubleshooting(),
        "Quick map of common fixes.",
    )

    pdf.set_y(-22)
    pdf.set_x(pdf.l_margin)
    pdf.set_font("Helvetica", "I", 9)
    pdf.multi_cell(
        pdf.w - pdf.l_margin - pdf.r_margin,
        5,
        "Generated from the Kids Church kiosk app volunteer guide. Regenerate with: pip install -r tools/requirements-pdf.txt then python tools/generate_volunteer_flows_pdf.py",
    )

    pdf.output(str(OUT_PATH))


if __name__ == "__main__":
    build_pdf()
    print(f"Wrote {OUT_PATH}")

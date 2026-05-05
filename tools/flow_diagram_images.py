"""Render simple volunteer-friendly flow diagrams as PNG bytes for the PDF guide."""

from __future__ import annotations

import textwrap
from io import BytesIO

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.patches as mpatches  # noqa: E402
import numpy as np  # noqa: E402

# Kiosk-friendly contrast
_BOX = "#E8F4FC"
_BOX_EDGE = "#1565C0"
_DIAMOND = "#FFF9C4"
_DIAMOND_EDGE = "#F57F17"
_ARROW = "#1565C0"


def _box(ax, x: float, y: float, w: float, h: float, text: str, fc: str = _BOX, ec: str = _BOX_EDGE) -> None:
    patch = mpatches.FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.06,rounding_size=0.15",
        linewidth=1.6,
        edgecolor=ec,
        facecolor=fc,
    )
    ax.add_patch(patch)
    wrapped = textwrap.fill(text, width=32)
    ax.text(x + w / 2, y + h / 2, wrapped, ha="center", va="center", fontsize=9, linespacing=1.15)


def _diamond(ax, cx: float, cy: float, text: str, size: float = 1.0) -> None:
    pts = np.array(
        [
            [cx, cy + size],
            [cx + size * 1.15, cy],
            [cx, cy - size],
            [cx - size * 1.15, cy],
        ]
    )
    ax.add_patch(
        mpatches.Polygon(
            pts,
            closed=True,
            facecolor=_DIAMOND,
            edgecolor=_DIAMOND_EDGE,
            linewidth=1.6,
        )
    )
    ax.text(cx, cy, textwrap.fill(text, 22), ha="center", va="center", fontsize=9)


def _arrow(ax, x1: float, y1: float, x2: float, y2: float) -> None:
    ax.annotate(
        "",
        xy=(x2, y2),
        xytext=(x1, y1),
        arrowprops=dict(arrowstyle="-|>", color=_ARROW, lw=1.8, mutation_scale=12),
    )


def _to_bytes(fig) -> BytesIO:
    buf = BytesIO()
    fig.savefig(buf, format="png", dpi=130, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    buf.seek(0)
    return buf


def diagram_open_app() -> BytesIO:
    fig, ax = plt.subplots(figsize=(7.2, 8.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 11)
    ax.axis("off")
    ax.set_title("When you open the app", fontsize=12, fontweight="bold", pad=12, color="#0D47A1")

    _box(ax, 2.0, 9.35, 6.0, 0.85, "Open the app")
    _arrow(ax, 5.0, 9.35, 5.0, 8.95)
    _box(ax, 2.0, 7.95, 6.0, 0.85, "Brief welcome screen")
    _arrow(ax, 5.0, 7.95, 5.0, 7.55)
    _diamond(ax, 5.0, 6.55, "Is someone already signed in on this device?", size=0.95)
    _arrow(ax, 3.85, 6.55, 1.4, 6.55)
    ax.text(2.5, 6.85, "Yes", fontsize=8, fontweight="bold", color=_ARROW)
    _box(ax, 0.2, 4.85, 3.8, 0.85, "Main menu")
    _arrow(ax, 2.1, 6.4, 2.1, 5.7)

    _arrow(ax, 6.15, 6.55, 8.6, 6.55)
    ax.text(7.2, 6.85, "No", fontsize=8, fontweight="bold", color=_ARROW)
    _box(ax, 6.0, 4.85, 3.8, 0.85, "Sign-in screen")
    _arrow(ax, 7.9, 4.85, 7.9, 4.45)
    _box(ax, 6.0, 3.35, 3.8, 0.85, "Enter username and password, tap Sign In")
    _arrow(ax, 7.9, 3.35, 7.9, 2.95)
    _diamond(ax, 7.9, 1.85, "Correct sign-in?", size=0.75)
    _arrow(ax, 6.85, 1.85, 2.5, 1.85)
    ax.text(4.5, 2.15, "Yes", fontsize=8, fontweight="bold", color=_ARROW)
    _box(ax, 0.2, 0.35, 3.8, 0.85, "Main menu")
    _arrow(ax, 7.9, 1.1, 7.9, 0.5)
    ax.text(8.8, 0.75, "No: try again", fontsize=8, style="italic", color="#555")

    return _to_bytes(fig)


def _vertical_stack(
    ax,
    title: str,
    steps: list[str],
    ylim: tuple[float, float],
    y0: float = 8.2,
    h: float = 0.68,
    spacing: float = 0.32,
) -> None:
    ax.set_xlim(0, 10)
    ax.set_ylim(ylim[0], ylim[1])
    ax.axis("off")
    ax.set_title(title, fontsize=12, fontweight="bold", pad=12, color="#0D47A1")
    y = y0
    for i, s in enumerate(steps):
        _box(ax, 1.2, y, 7.6, h, s)
        if i < len(steps) - 1:
            y_next = y - spacing - h
            _arrow(ax, 5.0, y, 5.0, y_next + h)
            y = y_next


def diagram_sign_in() -> BytesIO:
    fig, ax = plt.subplots(figsize=(6.8, 7.2))
    steps = [
        "Sign-in screen",
        "Type username and password your church gave you",
        "Tap Sign In",
        "If it worked: you land on the main menu",
        "If it failed: read the message, fix typos, try again or ask a leader",
    ]
    _vertical_stack(ax, "Signing in", steps, (0, 9.5))
    return _to_bytes(fig)


def diagram_main_menu_roles() -> BytesIO:
    fig, ax = plt.subplots(figsize=(7.5, 5.8))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 7)
    ax.axis("off")
    ax.set_title("Main menu: typical buttons by role", fontsize=12, fontweight="bold", pad=12, color="#0D47A1")

    _box(ax, 3.0, 5.85, 4.0, 0.75, "Main menu (after sign-in)")
    _arrow(ax, 5.0, 5.85, 5.0, 5.45)
    _box(ax, 1.0, 3.95, 8.0, 0.7, "Door / check-in helpers")
    _arrow(ax, 3.0, 3.95, 2.0, 3.2)
    _arrow(ax, 5.0, 3.95, 5.0, 3.2)
    _arrow(ax, 7.0, 3.95, 8.0, 3.2)
    _box(ax, 0.2, 2.15, 2.8, 0.85, "Guardian check-in")
    _box(ax, 3.6, 2.15, 2.8, 0.85, "Check-out")
    _box(ax, 7.0, 2.15, 2.8, 0.85, "Gear: Settings for everyone")
    _arrow(ax, 5.0, 2.15, 5.0, 1.75)
    _box(ax, 1.5, 0.35, 7.0, 0.85, "Staff / admin may also see attendance or extra admin shortcuts")

    return _to_bytes(fig)


def diagram_guardian_checkin() -> BytesIO:
    fig, ax = plt.subplots(figsize=(7.2, 11))
    steps = [
        "Open Guardian check-in from the main menu",
        "If needed: connect the label printer in Settings",
        "Scan the guardian QR code (kiosk scanner or camera)",
        "If the code fails: try again or ask a leader",
        "When it works: choose service and select children",
        "Confirm check-in",
        "Success: stickers print; screen clears for the next family",
    ]
    _vertical_stack(
        ax,
        "Guardian check-in (family arriving)",
        steps,
        (0, 12.5),
        y0=11.35,
        h=0.62,
        spacing=0.28,
    )
    return _to_bytes(fig)


def diagram_checkout() -> BytesIO:
    fig, ax = plt.subplots(figsize=(7.0, 8.5))
    steps = [
        "Open Check-out from the main menu",
        "Scan the pickup slip QR (kiosk scanner or camera)",
        "If the slip is bad: read the error and scan again",
        "When good: review child names and pickup codes",
        "Tap confirm check-out when everything matches",
        "Success: children marked picked up; ready for the next family",
    ]
    _vertical_stack(
        ax,
        "Check-out (pickup time)",
        steps,
        (0, 10.2),
        y0=9.25,
        h=0.62,
        spacing=0.28,
    )
    return _to_bytes(fig)


def diagram_camera_qr() -> BytesIO:
    fig, ax = plt.subplots(figsize=(6.5, 5.8))
    steps = [
        "Camera screen opens",
        "If asked: allow camera permission for your church",
        "Point at the QR code until it reads",
        "Camera closes; the app continues where you left off",
    ]
    _vertical_stack(
        ax,
        "Camera QR scan (when the app opens the camera)",
        steps,
        (0, 7.0),
        y0=6.05,
        h=0.65,
        spacing=0.3,
    )
    return _to_bytes(fig)


def diagram_attendance() -> BytesIO:
    fig, ax = plt.subplots(figsize=(6.2, 4.6))
    steps = [
        "Open attendance or summary (if your login shows it)",
        "Change the date if needed",
        "Read the list for that day",
    ]
    _vertical_stack(
        ax,
        "Attendance summary (if your login has it)",
        steps,
        (0, 5.8),
        y0=4.85,
        h=0.65,
        spacing=0.3,
    )
    return _to_bytes(fig)


def diagram_settings() -> BytesIO:
    fig, ax = plt.subplots(figsize=(6.2, 4.4))
    steps = [
        "Open Settings (gear icon)",
        "Connect or change the printer (USB or Bluetooth)",
        "Other options: ask an admin before changing",
    ]
    _vertical_stack(
        ax,
        "Settings",
        steps,
        (0, 5.5),
        y0=4.45,
        h=0.65,
        spacing=0.3,
    )
    return _to_bytes(fig)


def diagram_one_child_optional() -> BytesIO:
    fig, ax = plt.subplots(figsize=(6.8, 6.5))
    steps = [
        "Choose service (if your church uses this screen)",
        "Make sure the printer is ready",
        "Scan one child's code",
        "Review the child on screen",
        "Confirm check-in",
        "Print label if your process includes it",
    ]
    _vertical_stack(
        ax,
        "Optional: one-child check-in (if your church uses it)",
        steps,
        (0, 7.8),
        y0=6.55,
        h=0.58,
        spacing=0.26,
    )
    ax.text(
        5.0,
        0.35,
        "This screen may not be on your main menu.",
        ha="center",
        fontsize=8,
        style="italic",
        color="#555",
    )
    return _to_bytes(fig)


def diagram_troubleshooting() -> BytesIO:
    fig, ax = plt.subplots(figsize=(7.0, 4.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 4.5)
    ax.axis("off")
    ax.set_title("If something goes wrong", fontsize=12, fontweight="bold", pad=12, color="#0D47A1")

    _box(ax, 0.35, 3.15, 4.4, 0.75, "Printer problems: Settings, power, paper, connection")
    _box(ax, 5.25, 3.15, 4.4, 0.75, "Scan problems: clean window, steady code, try camera")
    _arrow(ax, 5.0, 3.15, 5.0, 2.55)
    _box(ax, 1.5, 1.35, 7.0, 0.85, "Wrong family on screen: Start over or go back, then scan again; call a leader if unsure")

    return _to_bytes(fig)

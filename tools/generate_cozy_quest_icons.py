#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Callable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "linguaquest" / "lib" / "assets" / "image" / "cozy_icons"
SIZE = 1024
SCALE = 4
INK = "#2C7BE0"
PALE = "#EAF2FC"
NAVY = "#233A66"


class IconCanvas:
    def __init__(self) -> None:
        self.image = Image.new("RGBA", (SIZE * SCALE, SIZE * SCALE), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)

    def p(self, value: float) -> int:
        return round(value * SCALE)

    def box(self, xy: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
        return tuple(self.p(v) for v in xy)  # type: ignore[return-value]

    def line(
        self,
        points: list[tuple[float, float]],
        width: float = 44,
        fill: str = INK,
        closed: bool = False,
    ) -> None:
        pts = [(self.p(x), self.p(y)) for x, y in points]
        if closed:
            pts.append(pts[0])
        self.draw.line(pts, fill=fill, width=self.p(width), joint="curve")

    def circle(
        self,
        xy: tuple[float, float, float, float],
        fill: str | None = None,
        outline: str = INK,
        width: float = 44,
    ) -> None:
        self.draw.ellipse(self.box(xy), fill=fill, outline=outline, width=self.p(width))

    def rounded(
        self,
        xy: tuple[float, float, float, float],
        radius: float = 56,
        fill: str | None = None,
        outline: str = INK,
        width: float = 44,
    ) -> None:
        self.draw.rounded_rectangle(
            self.box(xy),
            radius=self.p(radius),
            fill=fill,
            outline=outline,
            width=self.p(width),
        )

    def polygon(
        self,
        pts: list[tuple[float, float]],
        fill: str = PALE,
        outline: str = INK,
        width: float = 44,
    ) -> None:
        scaled = [(self.p(x), self.p(y)) for x, y in pts]
        self.draw.polygon(scaled, fill=fill)
        self.draw.line(scaled + [scaled[0]], fill=outline, width=self.p(width), joint="curve")

    def arc(self, xy: tuple[float, float, float, float], start: float, end: float, width: float = 44) -> None:
        self.draw.arc(self.box(xy), start=start, end=end, fill=INK, width=self.p(width))

    def save(self, path: Path) -> None:
        img = self.image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
        img.save(path)


def cat_face(c: IconCanvas, bbox=(270, 230, 754, 724), fill=PALE, wink=False) -> None:
    x1, y1, x2, y2 = bbox
    c.polygon([(x1 + 95, y1 + 75), (x1 + 150, y1 - 70), (x1 + 230, y1 + 80)], fill=fill)
    c.polygon([(x2 - 230, y1 + 80), (x2 - 150, y1 - 70), (x2 - 95, y1 + 75)], fill=fill)
    c.circle((x1, y1, x2, y2), fill=fill)
    c.circle((x1 + 130, y1 + 195, x1 + 174, y1 + 239), fill=NAVY, outline=NAVY, width=0)
    if wink:
        c.line([(x2 - 178, y1 + 215), (x2 - 122, y1 + 215)], width=28, fill=NAVY)
    else:
        c.circle((x2 - 174, y1 + 195, x2 - 130, y1 + 239), fill=NAVY, outline=NAVY, width=0)
    c.circle((492, 494, 532, 534), fill=NAVY, outline=NAVY, width=0)
    c.line([(360, 510), (250, 486)], width=22)
    c.line([(362, 568), (254, 594)], width=22)
    c.line([(662, 510), (774, 486)], width=22)
    c.line([(660, 568), (770, 594)], width=22)


def sparkle(c: IconCanvas, x: float, y: float, r: float = 52) -> None:
    c.polygon([(x, y - r), (x + r * 0.35, y - r * 0.25), (x + r, y), (x + r * 0.35, y + r * 0.25), (x, y + r), (x - r * 0.35, y + r * 0.25), (x - r, y), (x - r * 0.35, y - r * 0.25)], fill=PALE, width=30)


def plus(c: IconCanvas, x: float = 512, y: float = 512, s: float = 170, width: float = 56) -> None:
    c.line([(x - s / 2, y), (x + s / 2, y)], width=width)
    c.line([(x, y - s / 2), (x, y + s / 2)], width=width)


def checkmark(c: IconCanvas, box=(300, 330, 725, 675), width=70) -> None:
    x1, y1, x2, y2 = box
    c.line([(x1, y1 + 185), (x1 + 145, y2), (x2, y1)], width=width)


def xmark(c: IconCanvas, box=(330, 330, 694, 694), width=66) -> None:
    x1, y1, x2, y2 = box
    c.line([(x1, y1), (x2, y2)], width=width)
    c.line([(x2, y1), (x1, y2)], width=width)


def draw_home(c: IconCanvas, filled=False) -> None:
    c.polygon([(210, 475), (512, 230), (814, 475), (760, 475), (760, 790), (264, 790), (264, 475)], fill=PALE if filled else None)
    c.polygon([(388, 330), (428, 222), (470, 360)], fill=PALE if filled else None, width=34)
    c.polygon([(554, 360), (596, 222), (636, 330)], fill=PALE if filled else None, width=34)
    c.rounded((450, 585, 574, 790), radius=44, fill=(PALE if filled else None), width=38)


def draw_controller(c: IconCanvas, filled=False) -> None:
    c.rounded((188, 360, 836, 690), radius=128, fill=PALE if filled else None)
    c.line([(320, 480), (320, 580)], width=46)
    c.line([(270, 530), (370, 530)], width=46)
    c.circle((610, 478, 664, 532), fill=INK, outline=INK, width=0)
    for x, y in [(714, 500), (680, 560), (748, 560), (714, 610)]:
        c.circle((x - 18, y - 18, x + 18, y + 18), fill=INK, outline=INK, width=0)


def draw_ai_learning(c: IconCanvas, filled=False) -> None:
    c.polygon([(306, 332), (404, 215), (420, 382)], fill=PALE if filled else None)
    c.arc((252, 235, 760, 745), 90, 276, width=50)
    c.arc((318, 410, 760, 834), 178, 360, width=50)
    c.circle((410, 430, 452, 472), fill=NAVY, outline=NAVY, width=0)
    c.line([(396, 560), (316, 548)], width=20)
    c.line([(690, 250), (690, 340)], width=34)
    c.line([(645, 295), (735, 295)], width=34)
    c.circle((650, 255, 730, 335), fill=None, width=24)


def draw_compass(c: IconCanvas, filled=False) -> None:
    c.circle((210, 210, 814, 814), fill=PALE if filled else None)
    c.polygon([(512, 270), (575, 500), (512, 754), (449, 500)], fill=PALE if filled else None)
    c.polygon([(512, 270), (558, 382), (466, 382)], fill=INK, outline=INK, width=0)
    c.circle((472, 472, 552, 552), fill=INK, outline=INK, width=0)


def draw_profile(c: IconCanvas, filled=False) -> None:
    cat_face(c, fill=PALE if filled else None)


def draw_speech_translate(c: IconCanvas) -> None:
    c.rounded((178, 260, 640, 560), radius=88, fill=PALE)
    c.rounded((384, 470, 846, 766), radius=88, fill=None)
    c.line([(318, 410), (408, 410), (362, 366), (408, 410), (362, 454)], width=34)
    c.line([(558, 612), (648, 612), (604, 568), (648, 612), (604, 656)], width=34)


def draw_swap_language(c: IconCanvas) -> None:
    c.arc((230, 230, 794, 794), 25, 205, width=48)
    c.arc((230, 230, 794, 794), 205, 385, width=48)
    c.polygon([(298, 330), (180, 338), (250, 432)], fill=INK, outline=INK, width=0)
    c.polygon([(726, 694), (844, 686), (774, 592)], fill=INK, outline=INK, width=0)
    c.rounded((430, 380, 594, 620), radius=40, fill=PALE)
    c.line([(476, 460), (548, 460)], width=32)
    c.line([(512, 420), (512, 540)], width=32)


def draw_context(c: IconCanvas) -> None:
    c.arc((245, 250, 435, 520), 96, 355, width=56)
    c.arc((590, 250, 780, 520), 96, 355, width=56)
    c.line([(270, 690), (754, 690)], width=56)


def draw_image_choice(c: IconCanvas) -> None:
    c.rounded((190, 244, 834, 780), radius=82, fill=PALE)
    c.polygon([(275, 675), (435, 500), (545, 620), (630, 530), (765, 675)], fill="#FFFFFF00")
    c.circle((650, 340, 730, 420), fill=INK, outline=INK, width=0)
    sparkle(c, 790, 280, 38)


def draw_listening(c: IconCanvas) -> None:
    c.polygon([(442, 225), (580, 272), (640, 438), (570, 620), (470, 660), (430, 570), (502, 510), (526, 430), (492, 360), (410, 335)], fill=PALE)
    c.arc((588, 325, 790, 600), -54, 54, width=42)
    c.arc((645, 245, 900, 685), -54, 54, width=38)


def draw_pencil_input(c: IconCanvas) -> None:
    c.line([(285, 650), (690, 245)], width=72)
    c.polygon([(690, 245), (778, 158), (820, 200), (733, 288)], fill=PALE)
    c.line([(250, 770), (720, 770)], width=28)
    for x in [330, 430, 530]:
        c.circle((x - 12, 730, x + 12, 754), fill=INK, outline=INK, width=0)
    c.line([(772, 585), (772, 705)], width=28)


def draw_stopwatch(c: IconCanvas) -> None:
    c.circle((298, 260, 726, 760), fill=PALE)
    c.rounded((448, 186, 576, 270), radius=32, fill=PALE)
    c.line([(512, 512), (512, 390)], width=40)
    c.line([(512, 512), (610, 560)], width=40)
    c.line([(190, 390), (95, 390)], width=36)
    c.line([(225, 500), (115, 500)], width=36)


def draw_survival(c: IconCanvas) -> None:
    c.rounded((210, 650, 390, 770), radius=42, fill=PALE)
    c.rounded((420, 520, 600, 770), radius=42, fill=PALE)
    c.rounded((630, 390, 810, 770), radius=42, fill=PALE)
    c.polygon([(720, 270), (775, 220), (830, 270), (830, 340), (720, 340)], fill=PALE)


def draw_spelling_game(c: IconCanvas) -> None:
    draw_pencil_input(c)
    for x in [330, 462, 594]:
        c.rounded((x, 690, x + 88, 770), radius=18, fill=None, width=28)


def draw_lightning(c: IconCanvas) -> None:
    c.polygon([(570, 150), (320, 545), (500, 545), (430, 874), (710, 430), (530, 430)], fill=PALE)


def draw_flame(c: IconCanvas) -> None:
    c.polygon([(516, 170), (655, 360), (630, 475), (735, 430), (770, 640), (620, 818), (405, 800), (278, 650), (330, 440), (430, 520), (410, 330)], fill=PALE)
    c.arc((425, 520, 635, 825), 240, 60, width=40)


def draw_trophy(c: IconCanvas) -> None:
    c.rounded((340, 250, 684, 560), radius=52, fill=PALE)
    c.arc((190, 280, 390, 520), 280, 90, width=44)
    c.arc((634, 280, 834, 520), 90, 260, width=44)
    c.line([(512, 560), (512, 710)], width=48)
    c.rounded((390, 700, 634, 780), radius=36, fill=PALE)


def draw_check(c: IconCanvas) -> None:
    c.circle((220, 220, 804, 804), fill=PALE)
    checkmark(c)


def draw_wrong(c: IconCanvas) -> None:
    c.circle((220, 220, 804, 804), fill=PALE)
    xmark(c)


def draw_flag(c: IconCanvas) -> None:
    c.line([(310, 210), (310, 820)], width=44)
    c.rounded((310, 250, 745, 505), radius=42, fill=PALE)
    c.line([(745, 505), (650, 590), (310, 590)], width=44)


def draw_leaderboard(c: IconCanvas) -> None:
    c.rounded((240, 560, 395, 780), radius=36, fill=PALE)
    c.rounded((435, 410, 590, 780), radius=36, fill=PALE)
    c.rounded((630, 500, 785, 780), radius=36, fill=PALE)
    sparkle(c, 512, 285, 48)


def draw_wordbook(c: IconCanvas) -> None:
    c.line([(512, 300), (512, 760)], width=34)
    c.rounded((210, 280, 512, 760), radius=64, fill=PALE)
    c.rounded((512, 280, 814, 760), radius=64, fill=PALE)
    c.arc((585, 555, 760, 845), 80, 235, width=34)


def draw_flashcard_add(c: IconCanvas) -> None:
    c.rounded((210, 300, 815, 720), radius=70, fill=PALE)
    plus(c, 680, 430, 130, 46)
    c.line([(310, 565), (535, 565)], width=38)


def draw_tag(c: IconCanvas) -> None:
    c.polygon([(280, 300), (610, 300), (790, 480), (480, 790), (280, 590)], fill=PALE)
    c.circle((380, 400, 440, 460), fill=None, width=28)


def draw_word_web(c: IconCanvas) -> None:
    c.line([(385, 395), (610, 520), (410, 680)], width=32)
    c.line([(385, 395), (410, 680)], width=32)
    c.circle((280, 290, 490, 500), fill=PALE)
    c.circle((535, 420, 745, 630), fill=PALE)
    c.circle((305, 580, 515, 790), fill=PALE)


def draw_sleeping_cat(c: IconCanvas) -> None:
    c.circle((230, 260, 790, 820), fill=PALE)
    c.arc((315, 315, 780, 840), 35, 330, width=54)
    c.polygon([(410, 335), (462, 230), (518, 350)], fill=PALE)
    c.line([(455, 520), (510, 520)], width=22, fill=NAVY)
    c.arc((520, 565, 720, 720), 215, 35, width=40)


def draw_celebrate(c: IconCanvas) -> None:
    cat_face(c, (290, 265, 734, 710), fill=PALE, wink=True)
    c.circle((205, 525, 325, 645), fill=PALE)
    c.circle((700, 525, 820, 645), fill=PALE)
    sparkle(c, 240, 245, 36)
    sparkle(c, 790, 265, 36)


def draw_lightbulb(c: IconCanvas) -> None:
    c.circle((320, 180, 704, 565), fill=PALE)
    c.rounded((410, 555, 614, 735), radius=42, fill=PALE)
    c.line([(390, 455), (270, 430)], width=24)
    c.line([(635, 455), (755, 430)], width=24)


def draw_warning(c: IconCanvas) -> None:
    c.polygon([(512, 190), (810, 780), (214, 780)], fill=PALE)
    c.polygon([(350, 260), (405, 155), (462, 290)], fill=PALE, width=30)
    c.polygon([(562, 290), (619, 155), (674, 260)], fill=PALE, width=30)
    c.line([(512, 390), (512, 570)], width=52)
    c.circle((486, 645, 538, 697), fill=INK, outline=INK, width=0)


def draw_gift(c: IconCanvas) -> None:
    c.rounded((250, 390, 774, 760), radius=54, fill=PALE)
    c.line([(512, 390), (512, 760)], width=42)
    c.line([(250, 505), (774, 505)], width=42)
    c.arc((330, 245, 515, 420), 185, 355, width=44)
    c.arc((510, 245, 695, 420), 185, 355, width=44)


def draw_lottery(c: IconCanvas) -> None:
    c.rounded((305, 210, 720, 820), radius=78, fill=PALE)
    c.circle((370, 280, 655, 565), fill=None, width=40)
    c.circle((440, 350, 500, 410), fill=INK, outline=INK, width=0)
    c.circle((535, 430, 595, 490), fill=INK, outline=INK, width=0)
    c.circle((490, 600, 590, 700), fill=None, width=34)
    c.circle((532, 634, 548, 650), fill=INK, outline=INK, width=0)


def draw_wallet(c: IconCanvas) -> None:
    for x, y in [(330, 570), (430, 500), (530, 430)]:
        c.circle((x, y, x + 250, y + 120), fill=PALE)
    sparkle(c, 690, 345, 36)


def draw_medal(c: IconCanvas) -> None:
    c.polygon([(380, 190), (500, 190), (545, 430), (430, 430)], fill=PALE)
    c.polygon([(524, 190), (644, 190), (594, 430), (480, 430)], fill=PALE)
    c.circle((330, 390, 694, 754), fill=PALE)
    cat_face(c, (440, 485, 584, 630), fill=None)


def draw_robot_cat(c: IconCanvas) -> None:
    c.rounded((270, 320, 754, 705), radius=86, fill=PALE)
    c.polygon([(330, 320), (390, 210), (445, 320)], fill=PALE)
    c.polygon([(579, 320), (634, 210), (694, 320)], fill=PALE)
    c.circle((405, 465, 455, 515), fill=NAVY, outline=NAVY, width=0)
    c.circle((570, 465, 620, 515), fill=NAVY, outline=NAVY, width=0)
    c.line([(440, 600), (585, 600)], width=30, fill=NAVY)


def draw_chat(c: IconCanvas) -> None:
    c.rounded((210, 285, 814, 655), radius=108, fill=PALE)
    c.polygon([(365, 285), (420, 185), (472, 306)], fill=PALE, width=32)
    c.polygon([(552, 306), (604, 185), (659, 285)], fill=PALE, width=32)
    c.line([(365, 485), (660, 485)], width=42)


def draw_arrow(c: IconCanvas, right=False) -> None:
    if right:
        c.line([(280, 512), (735, 512)], width=70)
        c.line([(560, 335), (735, 512), (560, 689)], width=70)
    else:
        c.line([(744, 512), (289, 512)], width=70)
        c.line([(464, 335), (289, 512), (464, 689)], width=70)


def draw_search(c: IconCanvas) -> None:
    c.circle((250, 220, 630, 600), fill=None)
    c.line([(600, 570), (780, 750)], width=60)


def draw_add(c: IconCanvas) -> None:
    c.circle((230, 230, 794, 794), fill=PALE)
    plus(c)


def draw_settings(c: IconCanvas) -> None:
    c.circle((378, 378, 646, 646), fill=PALE)
    for a in range(0, 360, 45):
        import math

        r1, r2 = 230, 310
        x1 = 512 + math.cos(math.radians(a)) * r1
        y1 = 512 + math.sin(math.radians(a)) * r1
        x2 = 512 + math.cos(math.radians(a)) * r2
        y2 = 512 + math.sin(math.radians(a)) * r2
        c.line([(x1, y1), (x2, y2)], width=54)
    c.circle((442, 442, 582, 582), fill=None, width=36)


def draw_refresh(c: IconCanvas) -> None:
    c.arc((245, 245, 780, 780), 35, 330, width=60)
    c.polygon([(740, 250), (842, 292), (750, 365)], fill=INK, outline=INK, width=0)


def draw_bell(c: IconCanvas) -> None:
    c.arc((300, 260, 724, 710), 190, 350, width=58)
    c.line([(300, 520), (245, 685), (779, 685), (724, 520)], width=50)
    c.circle((465, 700, 559, 794), fill=PALE)


def draw_calendar(c: IconCanvas) -> None:
    c.rounded((230, 250, 794, 780), radius=60, fill=PALE)
    c.line([(230, 390), (794, 390)], width=40)
    c.line([(360, 185), (360, 315)], width=40)
    c.line([(664, 185), (664, 315)], width=40)
    checkmark(c, (370, 455, 655, 660), width=48)


def draw_edit(c: IconCanvas) -> None:
    c.line([(300, 700), (710, 290)], width=76)
    c.polygon([(710, 290), (785, 215), (830, 260), (755, 335)], fill=PALE)
    c.line([(265, 760), (435, 725)], width=42)


def draw_filter(c: IconCanvas) -> None:
    for y, x in [(330, 640), (512, 390), (694, 575)]:
        c.line([(230, y), (794, y)], width=46)
        c.circle((x - 48, y - 48, x + 48, y + 48), fill=PALE, width=32)


def draw_lock(c: IconCanvas) -> None:
    c.rounded((290, 435, 734, 790), radius=62, fill=PALE)
    c.arc((365, 220, 660, 555), 180, 360, width=54)
    c.line([(512, 575), (512, 660)], width=40)


ICONS: list[tuple[str, str, Callable[[IconCanvas], None]]] = [
    ("01_home_active", "Home active", lambda c: draw_home(c, True)),
    ("01_home_outline", "Home outline", lambda c: draw_home(c, False)),
    ("02_training_active", "Training active", lambda c: draw_controller(c, True)),
    ("02_training_outline", "Training outline", lambda c: draw_controller(c, False)),
    ("03_ai_learning_active", "AI Learning active", lambda c: draw_ai_learning(c, True)),
    ("03_ai_learning_outline", "AI Learning outline", lambda c: draw_ai_learning(c, False)),
    ("04_discover_active", "Discover active", lambda c: draw_compass(c, True)),
    ("04_discover_outline", "Discover outline", lambda c: draw_compass(c, False)),
    ("05_profile_active", "Profile active", lambda c: draw_profile(c, True)),
    ("05_profile_outline", "Profile outline", lambda c: draw_profile(c, False)),
    ("06_meaning_translate", "Meaning / translate", draw_speech_translate),
    ("07_language_choice", "Chinese-English choice", draw_swap_language),
    ("08_context_sentence", "Context / sentence", draw_context),
    ("09_image_choice", "Image choice", draw_image_choice),
    ("10_listening", "Listening", draw_listening),
    ("11_spelling_input", "Spelling / input", draw_pencil_input),
    ("12_word_rush", "Word Rush", draw_stopwatch),
    ("13_survival", "Survival", draw_survival),
    ("14_spelling_game", "Spelling game", draw_spelling_game),
    ("15_xp_points", "XP / points", draw_lightning),
    ("16_streak", "Streak", draw_flame),
    ("17_trophy_achievement", "Trophy / achievement", draw_trophy),
    ("18_correct_check", "Correct / check", draw_check),
    ("19_wrong_retry", "Wrong / retry", draw_wrong),
    ("20_goal_flag", "Goal / flag", draw_flag),
    ("21_leaderboard", "Leaderboard", draw_leaderboard),
    ("22_wordbook", "Wordbook", draw_wordbook),
    ("23_add_word_card", "Add word card", draw_flashcard_add),
    ("24_tag_label", "Tag / label", draw_tag),
    ("25_word_family_relations", "Word family / relations", draw_word_web),
    ("26_empty_state", "Empty state", draw_sleeping_cat),
    ("27_success_celebration", "Success / celebration", draw_celebrate),
    ("28_hint_tip", "Hint / tip", draw_lightbulb),
    ("29_warning", "Warning", draw_warning),
    ("30_gift_reward", "Gift / reward", draw_gift),
    ("31_lottery_draw", "Lottery / draw", draw_lottery),
    ("32_wallet_coins", "Wallet / coins", draw_wallet),
    ("33_badge_medal", "Badge / medal", draw_medal),
    ("34_ai_tutor_bot", "AI tutor bot", draw_robot_cat),
    ("35_chat_dialogue", "Chat / dialogue", draw_chat),
    ("36_back", "Back", lambda c: draw_arrow(c, False)),
    ("37_next_forward", "Next / forward", lambda c: draw_arrow(c, True)),
    ("38_search", "Search", draw_search),
    ("39_add", "Add", draw_add),
    ("40_settings", "Settings", draw_settings),
    ("41_refresh_replay", "Refresh / replay", draw_refresh),
    ("42_close", "Close", lambda c: xmark(c, (330, 330, 694, 694), 68)),
    ("43_notifications", "Notifications", draw_bell),
    ("44_check_in_calendar", "Check-in / calendar", draw_calendar),
    ("45_edit", "Edit", draw_edit),
    ("46_filter", "Filter", draw_filter),
    ("47_lock", "Lock", draw_lock),
]


def render_contact_sheet(paths: list[Path]) -> None:
    thumb = 160
    pad = 24
    cols = 8
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (thumb + pad) + pad, rows * (thumb + pad) + pad), (250, 248, 245, 255))
    for idx, path in enumerate(paths):
        img = Image.open(path).convert("RGBA").resize((thumb, thumb), Image.Resampling.LANCZOS)
        x = pad + (idx % cols) * (thumb + pad)
        y = pad + (idx // cols) * (thumb + pad)
        sheet.alpha_composite(img, (x, y))
    sheet.save(OUT_DIR / "cozy_icons_contact_sheet.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rendered: list[Path] = []
    manifest = []
    for slug, title, fn in ICONS:
        canvas = IconCanvas()
        fn(canvas)
        path = OUT_DIR / f"{slug}.png"
        canvas.save(path)
        rendered.append(path)
        manifest.append({"file": path.name, "title": title, "size": SIZE, "palette": [INK, PALE, NAVY]})
    render_contact_sheet(rendered)
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Rendered {len(rendered)} icons to {OUT_DIR}")


if __name__ == "__main__":
    main()

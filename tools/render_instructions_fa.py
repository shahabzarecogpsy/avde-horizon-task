# -*- coding: utf-8 -*-
"""Render all participant-facing Persian screens of AVDE v0.13.0 as PNG files.
Requires Pillow built with libraqm (RTL shaping). Font: Vazirmatn (SIL OFL 1.1).
Run:  python tools/render_instructions_fa.py   (writes assets/instructions_fa/*.png)
The text below is the single source of truth for participant wording; it is
reproduced in docs/PARTICIPANT_TEXT_FA.md by the same script."""
import os
from PIL import Image, ImageDraw, ImageFont, features
assert features.check('raqm'), 'Pillow needs libraqm for correct Persian shaping'
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'assets', 'instructions_fa')
REG = os.path.join(HERE, 'fonts', 'Vazirmatn-Regular.ttf')
BOLD = os.path.join(HERE, 'fonts', 'Vazirmatn-Bold.ttf')
W, H = 1600, 900
BG, CARD, EDGE, INK, TITLE, MUTED, ACC, BOXBG = (242,244,247), (255,255,255), (196,203,212), (30,34,40), (24,72,128), (105,112,122), (24,72,128), (230,240,250)
def font(p, s): return ImageFont.truetype(p, s)
def tw(d, t, f): return d.textlength(t, font=f, direction='rtl', language='fa')
def wrap(d, text, f, maxw):
    words, lines, cur = text.split(' '), [], ''
    for w in words:
        c = (cur + ' ' + w).strip()
        if tw(d, c, f) <= maxw: cur = c
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines
TRANSCRIPT = []
def rtl(d, x_right, y, t, f, fill): d.text((x_right, y), t, font=f, fill=fill, anchor='ra', direction='rtl', language='fa')
def base(title):
    im = Image.new('RGB', (W, H), BG); d = ImageDraw.Draw(im)
    d.rounded_rectangle((60, 40, W-60, H-70), 28, fill=CARD, outline=EDGE, width=3)
    rtl(d, W-120, 80, title, font(BOLD, 46), TITLE)
    d.line((120, 150, W-120, 150), fill=EDGE, width=2)
    return im, d
def footer(d, text='برای ادامه، کلید فاصله (Space) را فشار دهید.'):
    rtl(d, W-120, H-55, text, font(REG, 24), MUTED)
def bullets(d, items, y=180, size=31, maxw=1280, gap=16):
    f = font(REG, size)
    for it in items:
        lines = wrap(d, it, f, maxw)
        d.ellipse((W-132, y+14, W-118, y+28), fill=ACC)
        for ln in lines:
            rtl(d, W-150, y, ln, f, INK); y += size + 18
        y += gap
    return y
def box(d, text, y, size=30):
    f = font(BOLD, size); lines = wrap(d, text, f, 1250)
    h = len(lines)*(size+18) + 40
    d.rounded_rectangle((150, y, W-150, y+h), 18, fill=BOXBG, outline=ACC, width=2)
    yy = y + 20
    for ln in lines: rtl(d, W-185, yy, ln, f, TITLE); yy += size+18
def centered(d, text, y, size=34, fill=INK, bold=False):
    f = font(BOLD if bold else REG, size)
    for ln in wrap(d, text, f, 1250):
        d.text((W/2, y), ln, font=f, fill=fill, anchor='ma', direction='rtl', language='fa'); y += size+20
    return y
S = {}
S['instr_01_goal'] = ('راهنمای آزمایش (۱ از ۳): هدف', [
 'این آزمایش از تعدادی بازی کوتاه تشکیل شده است. در هر بازی دو منبع امتیاز دارید: یکی در سمت چپ و یکی در سمت راست صفحه.',
 'هر بار که از یک منبع امتیاز گرفته می‌شود، یک عدد (امتیاز) نمایش داده می‌شود. امتیازهای هر منبع ثابت نیستند و از یک بار به بار دیگر تغییر می‌کنند.',
 'در هر بازی، یکی از دو منبع به‌طور میانگین امتیاز بیشتری می‌دهد. این‌که کدام منبع بهتر است از بازی به بازی فرق می‌کند؛ هر بازی با دو منبع تازه شروع می‌شود.',
 'فقط امتیازهای انتخاب‌های آزاد خودتان در امتیاز کل شما حساب می‌شوند. امتیازهای نمونه‌ای که در ابتدای هر بازی به‌طور خودکار نشان داده می‌شوند حساب نمی‌شوند.'],
 'هدف شما: جمع‌کردن بیشترین امتیاز ممکن با انتخاب‌های آزاد خودتان.')
S['instr_02_sequence'] = ('راهنمای آزمایش (۲ از ۳): مراحل هر بازی', [
 'مرحلهٔ ۱ ـ تصاویر: ابتدا چهار تصویر چهره نمایش داده می‌شود؛ دو تصویر مربوط به منبع چپ و دو تصویر مربوط به منبع راست. هر تصویر کنار منبع خودش ظاهر می‌شود. در این مرحله لازم نیست کاری انجام دهید.',
 'مرحلهٔ ۲ ـ امتیازهای نمونه: سپس چهار امتیاز نمونه به‌طور خودکار نمایش داده می‌شود. منبعی که نمونه از آن گرفته می‌شود قاب زرد دارد و عدد در ستون همان منبع نوشته می‌شود. علامت XX در ستون دیگر یعنی در آن نمونه از آن منبع امتیازی گرفته نشده است. در این مرحله هم لازم نیست کاری انجام دهید.',
 'مرحلهٔ ۳ ـ انتخاب‌های آزاد: سپس خودتان منبع را انتخاب می‌کنید. پس از هر انتخاب، امتیاز منبع انتخاب‌شده و یک تصویر چهره از همان منبع نمایش داده می‌شود.'],
 'همهٔ امتیازهایی که در یک بازی دیده‌اید تا پایان همان بازی روی صفحه باقی می‌مانند.')
S['instr_03_choices'] = ('راهنمای آزمایش (۳ از ۳): انتخاب و زمان پاسخ', [
 'وقتی دو پیکان آبی کنار منبع‌ها ظاهر شد، با کلید جهت‌دار چپ منبع چپ و با کلید جهت‌دار راست منبع راست را انتخاب کنید.',
 'برای هر انتخاب ۴ ثانیه فرصت دارید. اگر در این مدت پاسخ ندهید، آن انتخاب از دست می‌رود، امتیازی نمی‌گیرید و یک خط تیره (-) ثبت می‌شود. کلیدی که پیش از ظاهرشدن پیکان‌ها فشار داده شود پذیرفته نمی‌شود.',
 'تعداد انتخاب‌های آزاد در هر بازی ۱ یا ۶ است. تعداد خانه‌های زیر هر منبع این را نشان می‌دهد: ۵ خانه یعنی ۱ انتخاب آزاد و ۱۰ خانه یعنی ۶ انتخاب آزاد.',
 'دو عدد کوچک بالای صفحه نشان می‌دهند چندمین بازی را انجام می‌دهید و کل آزمایش چند بازی دارد. پس از هر ۱۶ بازی یک استراحت دارید و هر وقت آماده بودید با کلید فاصله ادامه می‌دهید.'],
 'ابتدا چند بازی تمرینی انجام می‌دهید. امتیازهای تمرین حساب نمی‌شوند.')
def page(name, title, items, note):
    TRANSCRIPT.append((name, [title] + list(items) + [note, 'برای ادامه، کلید فاصله (Space) را فشار دهید.']))
    im, d = base(title); y = bullets(d, items); box(d, note, max(y+10, 640)); footer(d); im.save(os.path.join(OUT, name+'.png'))
def simple(name, title, text, foot=True, sub=None):
    TRANSCRIPT.append((name, [title, text] + ([sub] if sub else []) + (['برای ادامه، کلید فاصله (Space) را فشار دهید.'] if foot else [])))
    im, d = base(title); y = centered(d, text, 300, 36)
    if sub: centered(d, sub, y+30, 28, MUTED)
    if foot: footer(d)
    im.save(os.path.join(OUT, name+'.png'))
Q = [('آیا یک منبع همیشه همان امتیاز را می‌دهد؟', 'نه؛ امتیازهای هر منبع از یک بار به بار دیگر تغییر می‌کنند.', 'بله؛ هر منبع همیشه یک عدد ثابت می‌دهد.'),
     ('علامت XX در یک خانهٔ جدول یعنی چه؟', 'آن منبع صفر امتیاز داده است.', 'در آن نمونه، از آن منبع امتیازی گرفته نشده است.'),
     ('کدام امتیازها در امتیاز کل شما حساب می‌شوند؟', 'امتیازهای انتخاب‌های آزاد خودتان', 'امتیازهای نمونهٔ ابتدای هر بازی'),
     ('اگر زیر هر منبع ۱۰ خانه وجود داشته باشد، در این بازی چند بار خودتان انتخاب می‌کنید؟', 'یک بار', 'شش بار'),
     ('اگر ظرف ۴ ثانیه پاسخ ندهید چه می‌شود؟', 'آن انتخاب از دست می‌رود و امتیازی نمی‌گیرید.', 'بازی منتظر می‌ماند تا پاسخ دهید.')]
KEY = 'LRLRL'
def question(i, q, left, right):
    TRANSCRIPT.append(('comp_q%d' % (i+1), ['بررسی درک دستورالعمل (%s از ۵)' % '۱۲۳۴۵'[i], q, 'LEFT key box: ' + left, 'RIGHT key box: ' + right, 'correct: ' + KEY[i], 'پاسخ را با کلید جهت‌دار چپ یا راست انتخاب کنید.']))
    im, d = base('بررسی درک دستورالعمل (%s از ۵)' % '۱۲۳۴۵'[i])
    centered(d, q, 210, 36, INK, True)
    f = font(REG, 30)
    for (x0, txt, lab, sgn) in [(150, left, 'کلید چپ', -1), (W/2+40, right, 'کلید راست', 1)]:
        d.rounded_rectangle((x0, 420, x0+W/2-190, 640), 20, fill=(248,249,251), outline=EDGE, width=3)
        yy = 470
        for ln in wrap(d, txt, f, W/2-260):
            d.text((x0+(W/2-190)/2, yy), ln, font=f, fill=INK, anchor='ma', direction='rtl', language='fa'); yy += 48
        cx = x0+(W/2-190)/2
        d.text((cx, 665), lab, font=font(BOLD, 30), fill=ACC, anchor='ma', direction='rtl', language='fa')
        ax = cx + sgn*120; ay = 684
        d.polygon([(ax+sgn*26, ay), (ax-sgn*6, ay-18), (ax-sgn*6, ay+18)], fill=ACC); d.rectangle((min(ax-sgn*6, ax-sgn*30), ay-6, max(ax-sgn*6, ax-sgn*30), ay+6), fill=ACC)
    footer(d, 'پاسخ را با کلید جهت‌دار چپ یا راست انتخاب کنید.')
    im.save(os.path.join(OUT, 'comp_q%d.png' % (i+1)))
if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for k,(t,it,n) in S.items(): page(k, t, it, n)
    simple('practice_guided_1', 'بازی تمرینی ۱ (راهنمایی‌شده)', 'در این بازی با روند کار آشنا می‌شوید. به چهار تصویر، چهار امتیاز نمونه، تعداد خانه‌های زیر هر منبع و پیکان‌های آبی توجه کنید. این بازی ۵ خانه و فقط ۱ انتخاب آزاد دارد.', sub='امتیازهای تمرین حساب نمی‌شوند.')
    simple('practice_guided_2', 'بازی تمرینی ۲ (راهنمایی‌شده)', 'این بازی ۱۰ خانه و ۶ انتخاب آزاد دارد. پس از هر انتخاب، امتیاز و یک تصویر چهره از منبع انتخاب‌شده نمایش داده می‌شود و امتیاز در جدول همان منبع ثبت می‌شود.', sub='پس از این، چند بازی تمرینی دیگر بدون راهنما انجام می‌دهید.')
    simple('practice_repeat', 'تمرین دوباره', 'چند بازی تمرینی دیگر انجام می‌دهید. امتیازهای تمرین حساب نمی‌شوند.')
    simple('comp_intro', 'بررسی درک دستورالعمل', 'اکنون پنج پرسش کوتاه دربارهٔ قواعد بازی می‌بینید. برای هر پرسش، پاسخ درست را با کلید جهت‌دار چپ یا راست انتخاب کنید.')
    for i,(q,l,r) in enumerate(Q): question(i, q, l, r)
    simple('comp_pass', 'آماده‌اید', 'پاسخ‌های شما درست بود. اکنون بازی‌های اصلی شروع می‌شوند: ۱۱۲ بازی در ۷ بخش، با استراحت پس از هر بخش.', sub='هر وقت آماده بودید، کلید فاصله را فشار دهید.')
    simple('comp_fail', 'مرور دوباره', 'برخی پاسخ‌ها نادرست بود. راهنما دوباره نمایش داده می‌شود و سپس چند بازی تمرینی دیگر انجام می‌دهید.')
    simple('comp_stop', 'پایان تمرین', 'لطفاً آزمایشگر را صدا کنید.', foot=False)
    TRANSCRIPT.append(('break', ['استراحت', 'این بخش تمام شد. کمی استراحت کنید. هر زمان آماده بودید، برای ادامه کلید فاصله را فشار دهید.', 'بخش‌های انجام‌شده (عدد زیر):', '[runtime: k / 7 drawn below]']))
    im, d = base('استراحت'); centered(d, 'این بخش تمام شد. کمی استراحت کنید. هر زمان آماده بودید، برای ادامه کلید فاصله را فشار دهید.', 300, 36)
    centered(d, 'بخش‌های انجام‌شده (عدد زیر):', 690, 28, MUTED); im.save(os.path.join(OUT, 'break.png'))  # runtime draws 'k / 7' at 88% height
    simple('loading', 'در حال آماده‌سازی', 'لطفاً چند لحظه صبر کنید...', foot=False)
    simple('resume', 'ادامهٔ آزمایش', 'آزمایش از جایی که متوقف شده بود ادامه پیدا می‌کند.')
    simple('end', 'پایان آزمایش', 'از همکاری شما سپاسگزاریم. لطفاً آزمایشگر را صدا کنید.', foot=False)
    with open(os.path.join(ROOT, 'docs', 'PARTICIPANT_TEXT_FA.md'), 'w', encoding='utf-8') as fh:
        fh.write('# AVDE — complete transcript of every participant-facing screen\n\n')
        fh.write('Generated by tools/render_instructions_fa.py from the same strings that are rendered into assets/instructions_fa/*.png. ')
        fh.write('Runtime-drawn text (Latin digits only): progress counter "g / 112" during core games; "k / 7" on the break screen; "+N" points at outcomes; "XX" and "-" in the history table.\n\n')
        for name, lines in TRANSCRIPT:
            fh.write('## %s.png\n\n' % name); [fh.write('- %s\n' % x) for x in lines]; fh.write('\n')
    print('rendered', len(os.listdir(OUT)), 'screens')

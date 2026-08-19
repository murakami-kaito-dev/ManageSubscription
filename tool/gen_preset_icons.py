#!/usr/bin/env python3
"""プリセットアイコン（スケッチ風SVG）ジェネレータ.

「解約方法」タブ収録の48サービス分のアイコンを assets/preset_icons/ に生成する。
方針（.claude/docs/feature-cancellation-guide.md / 開発者承認済みの対応表に従う）:
  - ブランド近似色1色の角丸タイル ＋ 白（明るいタイルは炭色）の手描き風ストローク
  - ロゴ・マスコット・トレードドレスの形状は一切使わない（内容モチーフのみ）
実行: python3 tool/gen_preset_icons.py
"""
import os

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'preset_icons')

# ── 手描き風の共通スタイル ──────────────────────────────────────────────
# viewBox 120x120 / タイル角丸28 / ストロークは丸端・丸継ぎで「描いた」感を出す。
# 各モチーフはわずかに回転させ、直線も微妙に曲げてスケッチらしさを出す。

def luminance(hexcolor):
    r = int(hexcolor[1:3], 16) / 255
    g = int(hexcolor[3:5], 16) / 255
    b = int(hexcolor[5:7], 16) / 255
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def icon(bg, body, rot=0.0, stroke=None):
    ink = stroke or ('#3B3A36' if luminance(bg) > 0.63 else '#FFFFFF')
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">'
        f'<rect x="2" y="2" width="116" height="116" rx="28" fill="{bg}"/>'
        f'<g transform="rotate({rot} 60 62)" fill="none" stroke="{ink}" '
        'stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round">'
        f'{body}</g></svg>'
    )


# ── モチーフ（手描き風: 直線の代わりに緩いカーブを使う） ──────────────────
M = {}

M['smartphone'] = (
    '<rect x="42" y="28" width="36" height="66" rx="9"/>'
    '<path d="M54 36 q6 1.5 12 0"/>'
    '<path d="M56 84 q4 1 8 0"/>'
)

M['popcorn'] = (
    '<path d="M38 58 q22 -6 44 0 l-6 34 q-16 4 -32 0 z"/>'
    '<path d="M50 60 q1 16 2 30"/><path d="M68 60 q-1 16 -2 30"/>'
    '<circle cx="46" cy="48" r="8"/><circle cx="60" cy="42" r="9"/>'
    '<circle cx="74" cy="49" r="8"/>'
)

M['box'] = (
    '<path d="M34 48 q26 -5 52 0 l-2 38 q-24 5 -48 0 z"/>'
    '<path d="M34 48 l12 -14 q14 -3 28 0 l12 14"/>'
    '<path d="M60 50 q1 18 0 36"/>'
)

M['shootingstar'] = (
    '<path d="M70 40 l5 11 12 1 -9 8 3 12 -11 -6 -11 6 3 -12 -9 -8 12 -1 z"/>'
    '<path d="M46 44 q-9 3 -17 8"/><path d="M48 60 q-11 4 -20 10"/>'
    '<path d="M52 74 q-8 4 -14 9"/>'
)

M['clapperboard'] = (
    '<rect x="34" y="56" width="52" height="34" rx="5"/>'
    '<path d="M33 52 l53 -9 -3 -12 -52 9 z"/>'
    '<path d="M43 49 l7 -12"/><path d="M58 46 l7 -12"/><path d="M73 44 l7 -12"/>'
)

M['soccer'] = (
    '<circle cx="60" cy="62" r="28"/>'
    '<path d="M60 50 l10 7 -4 12 -12 0 -4 -12 z"/>'
    '<path d="M60 50 l0 -15"/><path d="M70 57 l13 -5"/><path d="M66 69 l9 11"/>'
    '<path d="M54 69 l-9 11"/><path d="M50 57 l-13 -5"/>'
)

M['tv'] = (
    '<rect x="32" y="42" width="56" height="40" rx="8"/>'
    '<path d="M48 30 l12 11 12 -12"/>'
    '<path d="M46 92 q14 3 28 0"/>'
)

M['remote'] = (
    '<rect x="46" y="28" width="28" height="66" rx="10"/>'
    '<circle cx="60" cy="48" r="8"/>'
    '<path d="M54 68 l0.5 0"/><path d="M66 68 l0.5 0"/>'
    '<path d="M54 80 l0.5 0"/><path d="M66 80 l0.5 0"/>'
)

M['sparkle'] = (
    '<path d="M56 30 q3 14 6 18 q4 4 18 8 q-14 4 -18 8 q-3 4 -6 18 q-3 -14 -7 -18 q-4 -4 -17 -8 q13 -4 17 -8 q4 -4 7 -18 z"/>'
    '<path d="M84 70 q1.5 6 3 8 q2 2 8 4 q-6 2 -8 4 q-1.5 2 -3 8 q-1.5 -6 -3 -8 q-2 -2 -8 -4 q6 -2 8 -4 q1.5 -2 3 -8 z"/>'
)

M['projector'] = (
    '<rect x="30" y="52" width="60" height="30" rx="9"/>'
    '<circle cx="72" cy="67" r="9"/><circle cx="45" cy="44" r="9"/>'
    '<path d="M90 60 l16 -7"/><path d="M90 74 l16 7"/>'
)

M['monitor'] = (
    '<rect x="30" y="34" width="60" height="42" rx="7"/>'
    '<path d="M60 78 q1 6 0 10"/><path d="M46 92 q14 -3 28 0"/>'
)

M['reel'] = (
    '<circle cx="60" cy="58" r="26"/><circle cx="60" cy="58" r="4"/>'
    '<circle cx="60" cy="42" r="5"/><circle cx="76" cy="58" r="5"/>'
    '<circle cx="60" cy="74" r="5"/><circle cx="44" cy="58" r="5"/>'
    '<path d="M82 78 q12 8 8 14 l-14 -6"/>'
)

M['parabola'] = (
    '<path d="M36 40 q-4 30 22 42 q26 -8 24 -40 q-24 -14 -46 -2 z" transform="rotate(-8 60 60)"/>'
    '<path d="M58 62 l14 26"/><path d="M60 88 q12 2 22 0"/>'
    '<path d="M88 34 q6 6 7 14"/><path d="M96 26 q9 9 10 20"/>'
)

M['satellite'] = (
    '<rect x="48" y="48" width="24" height="26" rx="5"/>'
    '<path d="M30 44 l14 12 -8 10 -14 -12 z"/>'
    '<path d="M76 62 l14 12 8 -10 -14 -12 z"/>'
    '<path d="M60 48 l6 -12"/><circle cx="68" cy="32" r="3.5"/>'
)

M['ticket'] = (
    '<path d="M30 46 q30 -5 60 0 l0 12 q-7 2 -7 8 t7 8 l0 14 q-30 5 -60 0 l0 -14 q7 -2 7 -8 t-7 -8 z"/>'
    '<path d="M60 48 l0 4 M60 58 l0 5 M60 69 l0 5 M60 80 l0 4" stroke-dasharray="1 7"/>'
)

M['bubble'] = (
    '<path d="M32 40 q28 -8 56 0 q4 14 0 28 q-18 5 -36 3 l-14 12 2 -14 q-8 -1 -8 -1 q-4 -14 0 -28 z"/>'
    '<path d="M44 52 q13 -2 26 0"/><path d="M44 62 q9 -1 18 0"/>'
)

M['headphones'] = (
    '<path d="M34 70 q-3 -34 26 -36 q29 2 26 36"/>'
    '<rect x="30" y="66" width="14" height="24" rx="6"/>'
    '<rect x="76" y="66" width="14" height="24" rx="6"/>'
)

M['note'] = (
    '<path d="M50 84 q0 8 -9 8 t-9 -8 q0 -7 9 -7 q6 0 9 3 l0 -44 q17 -3 34 -6 l0 42 q0 8 -9 8 t-9 -8 q0 -7 9 -7 q6 0 9 3"/>'
    '<path d="M50 48 q17 -4 34 -7"/>'
)

M['equalizer'] = (
    '<path d="M40 88 l0 -22"/><path d="M54 88 l0 -44"/>'
    '<path d="M68 88 l0 -30"/><path d="M82 88 l0 -54"/>'
)

M['crown'] = (
    '<path d="M34 76 l-3 -30 14 11 15 -20 15 20 14 -11 -3 30 q-26 5 -52 0 z"/>'
    '<path d="M38 86 q22 4 44 0"/>'
)

M['microphone'] = (
    '<rect x="49" y="26" width="22" height="38" rx="11"/>'
    '<path d="M38 56 q0 20 22 20 t22 -20"/>'
    '<path d="M60 78 l0 14"/><path d="M48 94 q12 -3 24 0"/>'
)

M['robot'] = (
    '<rect x="36" y="42" width="48" height="40" rx="10"/>'
    '<circle cx="50" cy="58" r="3"/><circle cx="70" cy="58" r="3"/>'
    '<path d="M50 70 q10 5 20 0"/>'
    '<path d="M60 42 l0 -10"/><circle cx="60" cy="28" r="3.5"/>'
    '<path d="M30 56 l0 12"/><path d="M90 56 l0 12"/>'
)

M['quill'] = (
    '<path d="M82 30 q-26 8 -36 34 q-4 10 -6 24 q12 -2 22 -8 q24 -12 26 -44 q-3 -4 -6 -6 z"/>'
    '<path d="M44 84 q16 -22 30 -36"/>'
    '<path d="M34 94 q10 1 18 -2"/>'
)

M['palette'] = (
    '<path d="M60 30 q30 2 30 26 q0 10 -10 10 l-8 0 q-6 0 -6 7 q0 4 3 7 q3 4 -3 7 q-3 1 -6 1 q-30 -2 -30 -29 t30 -29 z"/>'
    '<circle cx="48" cy="46" r="3"/><circle cx="64" cy="42" r="3"/>'
    '<circle cx="44" cy="60" r="3"/>'
)

M['document'] = (
    '<path d="M38 28 l30 0 14 14 0 50 q-22 4 -44 0 z"/>'
    '<path d="M68 28 l0 14 14 0"/>'
    '<path d="M46 56 q13 -1 27 0"/><path d="M46 66 q13 -1 27 0"/>'
    '<path d="M46 76 q9 -1 18 0"/>'
)

M['folder'] = (
    '<path d="M32 40 l20 0 8 9 28 0 q4 20 0 39 q-28 4 -56 0 q-4 -24 0 -48 z"/>'
    '<path d="M34 56 q26 -3 52 0"/>'
)

M['cloud'] = (
    '<path d="M42 82 q-14 0 -14 -13 q0 -11 11 -12 q2 -13 16 -13 q11 0 15 9 q14 -2 16 11 q1 13 -12 14 q-16 3 -32 4 z"/>'
)

M['openbox'] = (
    '<path d="M38 58 l44 0 -2 30 q-20 4 -40 0 z"/>'
    '<path d="M38 58 l-10 -12 18 -6 12 12"/>'
    '<path d="M82 58 l10 -12 -18 -6 -12 12"/>'
    '<path d="M60 30 l0 -0.5"/>'
)

M['pencil_ruler'] = (
    '<path d="M34 78 l40 -44 10 10 -40 44 -12 2 z"/>'
    '<path d="M70 40 l8 8"/>'
    '<path d="M44 92 q22 2 42 0"/><path d="M56 92 l0 -5 M68 92 l0 -5 M80 92 l0 -5"/>'
)

M['notebook'] = (
    '<rect x="40" y="28" width="44" height="64" rx="7"/>'
    '<path d="M40 42 l-8 0 M40 58 l-8 0 M40 74 l-8 0"/>'
    '<path d="M52 46 q11 -1 22 0"/><path d="M52 58 q11 -1 22 0"/>'
    '<path d="M52 70 q8 -1 16 0"/>'
)

M['code'] = (
    '<path d="M42 42 q-12 9 -18 20 q6 11 18 20"/>'
    '<path d="M78 42 q12 9 18 20 q-6 11 -18 20"/>'
    '<path d="M66 36 q-7 24 -13 48"/>'
)

M['gamepad'] = (
    '<path d="M36 44 q24 -6 48 0 q10 3 10 22 q0 16 -10 16 q-6 0 -11 -8 q-13 -3 -26 0 q-5 8 -11 8 q-10 0 -10 -16 q0 -19 10 -22 z"/>'
    '<path d="M46 56 l0 12 M40 62 l12 0"/>'
    '<circle cx="76" cy="58" r="2.5"/><circle cx="84" cy="66" r="2.5"/>'
)

M['trophy'] = (
    '<path d="M44 32 q16 -3 32 0 q1 20 -6 30 q-5 8 -10 8 t-10 -8 q-7 -10 -6 -30 z"/>'
    '<path d="M44 38 q-12 0 -10 12 q2 8 12 9"/>'
    '<path d="M76 38 q12 0 10 12 q-2 8 -12 9"/>'
    '<path d="M60 70 l0 12"/><path d="M46 90 q14 -4 28 0"/>'
)

M['openbook'] = (
    '<path d="M60 42 q-12 -8 -28 -6 q-3 24 0 48 q16 -2 28 6 q12 -8 28 -6 q3 -24 0 -48 q-16 -2 -28 6 z"/>'
    '<path d="M60 42 l0 48"/>'
    '<path d="M40 52 q8 -1 14 2"/><path d="M40 62 q8 -1 14 2"/>'
    '<path d="M66 54 q8 -3 14 -2"/><path d="M66 64 q8 -3 14 -2"/>'
)

M['magazine'] = (
    '<rect x="38" y="28" width="44" height="64" rx="6"/>'
    '<path d="M46 42 q14 -2 28 0"/>'
    '<rect x="46" y="52" width="28" height="20" rx="4"/>'
    '<path d="M46 82 q10 -1 20 0"/>'
)

M['magazine_stack'] = (
    '<rect x="42" y="24" width="40" height="56" rx="6" transform="rotate(6 62 52)"/>'
    '<rect x="36" y="36" width="44" height="60" rx="6"/>'
    '<path d="M44 50 q14 -2 28 0"/><rect x="44" y="60" width="28" height="18" rx="4"/>'
)

M['audiobook'] = (
    '<path d="M36 34 q14 -6 24 0 l0 52 q-10 -6 -24 0 z"/>'
    '<path d="M74 46 q6 6 6 16 t-6 16"/>'
    '<path d="M84 38 q10 10 10 24 t-10 24"/>'
)

M['newspaper'] = (
    '<path d="M34 32 l52 0 0 56 q0 6 -8 6 l-44 0 q8 0 8 -6 z" transform="rotate(-2 60 62)"/>'
    '<rect x="42" y="42" width="18" height="16" rx="3"/>'
    '<path d="M66 44 l12 0 M66 52 l12 0"/>'
    '<path d="M42 68 q18 -2 36 0"/><path d="M42 78 q18 -2 36 0"/>'
)

M['deliverybag'] = (
    '<path d="M38 46 q22 -5 44 0 q4 22 0 44 q-22 5 -44 0 q-4 -22 0 -44 z"/>'
    '<path d="M48 46 q0 -16 12 -16 t12 16"/>'
    '<path d="M40 60 q20 -3 40 0"/>'
)

M['gift'] = (
    '<path d="M34 52 l52 0 -2 36 q-24 4 -48 0 z"/>'
    '<path d="M30 42 l60 0 0 10 -60 0 z"/>'
    '<path d="M60 42 l0 46"/>'
    '<path d="M60 40 q-16 2 -14 -8 q2 -8 14 8 z"/>'
    '<path d="M60 40 q16 2 14 -8 q-2 -8 -14 8 z"/>'
)

M['megaphone'] = (
    '<path d="M36 54 l34 -20 q6 22 0 44 l-34 -16 q-3 -4 0 -8 z"/>'
    '<path d="M38 64 l4 20 q6 3 10 0 l-3 -15"/>'
    '<path d="M82 48 q6 8 6 14 t-6 14" transform="rotate(-4 85 62)"/>'
)

M['gradcap'] = (
    '<path d="M60 34 l34 14 -34 14 -34 -14 z"/>'
    '<path d="M42 56 l0 18 q18 10 36 0 l0 -18"/>'
    '<path d="M90 50 l0 20"/><circle cx="90" cy="76" r="3.5"/>'
)

M['globe'] = (
    '<circle cx="60" cy="60" r="28"/>'
    '<ellipse cx="60" cy="60" rx="12" ry="28"/>'
    '<path d="M34 50 q26 -5 52 0"/><path d="M34 70 q26 5 52 0"/>'
)

M['dumbbell'] = (
    '<path d="M44 60 q16 -3 32 0" transform="rotate(-6 60 60)"/>'
    '<g transform="rotate(-6 60 60)">'
    '<rect x="30" y="44" width="10" height="32" rx="5"/>'
    '<rect x="80" y="44" width="10" height="32" rx="5"/>'
    '<rect x="20" y="50" width="8" height="20" rx="4"/>'
    '<rect x="92" y="50" width="8" height="20" rx="4"/></g>'
)

M['sneaker'] = (
    '<path d="M30 72 q2 -14 12 -14 q10 1 16 -8 q16 12 32 14 q6 2 6 8 l0 6 q-33 4 -66 0 z"/>'
    '<path d="M30 84 q33 4 66 0"/>'
    '<path d="M54 58 l6 6 M62 54 l6 6"/>'
)

# ── 固定費用モチーフ（クイック追加メニュー用。2026-08 追加）──────────────────
M['house'] = (
    '<path d="M32 62 q28 -26 56 0" />'
    '<path d="M38 58 l1 32 q21 4 42 0 l1 -32"/>'
    '<path d="M53 90 l0 -18 q7 -3 14 0 l0 18"/>'
)

M['bulb'] = (
    '<path d="M60 28 q22 1 22 22 q0 10 -8 17 q-4 3 -4 9 l-20 0 q0 -6 -4 -9 q-8 -7 -8 -17 q0 -21 22 -22 z"/>'
    '<path d="M52 84 q8 2 16 0"/><path d="M54 92 q6 2 12 0"/>'
    '<path d="M56 62 l4 8 4 -8"/>'
)

M['flame'] = (
    '<path d="M60 26 q4 14 14 22 q12 10 10 24 q-2 18 -24 20 q-22 -2 -24 -20 q-2 -14 10 -24 q10 -8 14 -22 z"/>'
    '<path d="M60 58 q8 6 6 14 q-1 8 -6 10 q-5 -2 -6 -10 q-2 -8 6 -14 z"/>'
)

M['droplet'] = (
    '<path d="M60 26 q22 26 22 42 q0 20 -22 22 q-22 -2 -22 -22 q0 -16 22 -42 z"/>'
    '<path d="M48 68 q1 12 12 14"/>'
)

M['car'] = (
    '<path d="M32 66 q2 -12 10 -14 q4 -12 18 -12 q14 0 18 12 q8 2 10 14 q1 8 -4 10 l-48 0 q-5 -2 -4 -10 z"/>'
    '<circle cx="44" cy="80" r="7"/><circle cx="76" cy="80" r="7"/>'
    '<path d="M48 52 q12 -3 24 0"/>'
)

M['umbrella'] = (
    '<path d="M28 58 q4 -28 32 -30 q28 2 32 30 q-8 -6 -16 0 q-8 -6 -16 0 q-8 -6 -16 0 q-8 -6 -16 0 z"/>'
    '<path d="M60 60 l0 26 q0 8 -8 8 q-6 0 -7 -6"/>'
    '<path d="M60 28 l0 -2"/>'
)

M['piggybank'] = (
    '<path d="M36 62 q0 -20 24 -20 q22 0 24 16 q8 1 8 8 q0 6 -7 6 q-3 10 -12 13 l0 7 -9 0 -2 -6 q-6 1 -10 0 l-2 6 -9 0 0 -8 q-14 -6 -5 -22 z" transform="rotate(-2 60 60)"/>'
    '<path d="M52 40 q8 -3 16 0"/>'
    '<circle cx="72" cy="56" r="2.5"/>'
)

# ── サービス → (色, モチーフ, 回転) 対応表（開発者承認済み） ─────────────────
SERVICES = [
    ('app_store',              '#4A90D9', 'smartphone', -2),
    ('google_play',            '#34A853', 'smartphone', 2),
    ('netflix',                '#E50914', 'popcorn', -2),
    ('amazon_prime',           '#00A8E1', 'box', 2),
    ('disney_plus',            '#113CCF', 'shootingstar', 0),
    ('unext',                  '#1D1D1D', 'clapperboard', -2),
    ('dazn',                   '#232323', 'soccer', 0),
    ('hulu',                   '#1CE783', 'tv', 2),
    ('abema',                  '#00D452', 'remote', -2),
    ('danime',                 '#EE7700', 'sparkle', 0),
    ('lemino',                 '#8B5CF6', 'projector', -2),
    ('fod',                    '#E60012', 'monitor', 2),
    ('telasa',                 '#00B5AD', 'reel', 0),
    ('wowow',                  '#0068B7', 'parabola', 0),
    ('skyperfectv',            '#00A0E9', 'satellite', 6),
    ('dmm_tv',                 '#17153A', 'ticket', -3),
    ('niconico_premium',       '#252525', 'bubble', 2),
    ('spotify',                '#1DB954', 'headphones', -2),
    ('apple_music',            '#FA243C', 'note', 2),
    ('amazon_music',           '#46C3D0', 'equalizer', 0),
    ('youtube_premium',        '#FF0000', 'crown', -2),
    ('line_music',             '#06C755', 'microphone', 2),
    ('chatgpt',                '#10A37F', 'robot', 0),
    ('claude',                 '#DA7756', 'quill', 0),
    ('adobe_cc',               '#FA0F00', 'palette', -2),
    ('microsoft_365',          '#D83B01', 'document', 2),
    ('google_one',             '#4285F4', 'folder', -2),
    ('icloud',                 '#3693F3', 'cloud', 0),
    ('dropbox',                '#0061FF', 'openbox', 2),
    ('canva',                  '#00C4CC', 'pencil_ruler', 0),
    ('notion',                 '#191919', 'notebook', -2),
    ('github_copilot',         '#24292F', 'code', 0),
    ('nintendo_switch_online', '#E60012', 'gamepad', -2),
    ('playstation_plus',       '#00439C', 'trophy', 0),
    ('xbox_game_pass',         '#107C10', 'gamepad', 2),
    ('kindle_unlimited',       '#144E7A', 'openbook', 0),
    ('dmagazine',              '#CC0033', 'magazine', -2),
    ('rakuten_magazine',       '#BF0000', 'magazine_stack', 0),
    ('audible',                '#F8991C', 'audiobook', 0),
    ('nikkei',                 '#003A70', 'newspaper', 0),
    ('uber_one',               '#06C167', 'deliverybag', 2),
    ('lyp_premium',            '#FF0033', 'gift', -2),
    ('x_premium',              '#0F1419', 'megaphone', 0),
    ('studysapuri',            '#00A0E2', 'gradcap', 0),
    ('duolingo',               '#58CC02', 'globe', -2),
    ('chocozap',               '#FFD800', 'dumbbell', 0),
    ('anytime_fitness',        '#5F249F', 'sneaker', -2),
    ('submana_premium',        '#6E9080', 'piggybank', 0),
    # ── 固定費（クイック追加メニュー用。catalog.json の色と揃える）──────────
    ('rent',                   '#8D6E63', 'house', 0),
    ('electricity',            '#F9A825', 'bulb', 0),
    ('gas',                    '#EF6C00', 'flame', 0),
    ('water',                  '#039BE5', 'droplet', 0),
    ('mobile_plan',            '#5E35B1', 'smartphone', -2),
    ('parking',                '#546E7A', 'car', 0),
    ('insurance',              '#00897B', 'umbrella', -2),
    ('nhk',                    '#3949AB', 'tv', 2),
]


def main():
    os.makedirs(OUT, exist_ok=True)
    for sid, color, motif, rot in SERVICES:
        svg = icon(color, M[motif], rot=rot)
        with open(os.path.join(OUT, f'{sid}.svg'), 'w') as f:
            f.write(svg)
    print(f'generated {len(SERVICES)} icons -> {os.path.abspath(OUT)}')


if __name__ == '__main__':
    main()

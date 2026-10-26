<!-- split from UI spec · lines 4428-4971 -->

## پیوست الف. design\_tokens.json (متن کامل و sha256)

**وضعیت:** پیشنهاد (Proposed) و ذیل `ADR-UI-001`. مالک این پیوست Agent 1 است؛ Agent 2 تا 5 مقدارها را فقط از `design_tokens.g.dart` می‌خوانند (TK-01). پیوست مقدار تازه‌ای نمی‌سازد: همه‌ی مقدارها از جدول‌های ۲-۲ تا ۲-۵، ۳-۱ و ۴-۲ برداشته شده‌اند، جز `tooltip-delay` = ۵۰۰ که TP-04 ثبت کرده است.

این پیوست شامل الف-۱ قواعد پیوست، الف-۲ فهرست نام توکن‌ها، الف-۳ متن کامل فایل، الف-۴ جفت‌های کنتراست و الف-۵ آزمون است. شناسه‌های AX برای قواعد و AXT برای ردیف‌های فهرست نام‌هاست.

### الف-۱ قواعد پیوست

- **AX-01 (منبع و برابری):** متن کامل فایل در الف-۳ است و همان `design_tokens.json` مخزن است؛ مخزن و پیوست باید بایت‌به‌بایت برابر باشند. اختلاف خطای VT-01 است و هر دو در یک درخواست ادغام تغییر می‌کنند.
- **AX-02 (قالب مرجع و checksum):** قالب فایل: UTF-8 بدون BOM، پایان خط LF، تورفتگی دو فاصله، کلیدها به ترتیب الف-۳، آرایه‌ی عددها یا رشته‌ها در یک خط و یک LF در پایان فایل (بلوک الف-۳ بدون این LF پایانی نمایش داده می‌شود). `meta.checksum` برابر sha256 بایت‌های فایل است وقتی مقدار `checksum` رشته‌ی تهی `""` باشد (VT-01 گام ۳). مقدار مرجع: `e6064535e236c5fcb322e0f454173e30d5c2dcdbac603a0a97d18dfebca33e3e`. این همان «sha256» ۲-۱ است؛ sha256 فایلِ دارای `checksum` پرشده مرجع نیست.
- **AX-03 (نام‌ها):** الف-۲ نام همه‌ی توکن‌ها را فهرست می‌کند و VT-01 گام ۱ نام‌های فایل را با آن می‌سنجد؛ نام بی‌ثبت و نام ثبت‌شده‌ی غایب هر دو خطاست. نام یا مقدار تازه فقط با TK-09 و AGX-04 اضافه می‌شود.
- **AX-04 (آنچه تازه است):** تنها مقدار تازه `motion.timing.tooltip-delay` = ۵۰۰ است (TP-04). این نام‌ها برای مقدارهای موجود در ۲-۲ تا ۲-۶ و ۴-۲ تازه‌اند و مقدار تازه نیستند (نام تازه؛ تأیید Agent 1): `sidebar-width-collapsed` (۷۲) و `sidebar-width-open` (۲۶۴)، کلیدهای `state-opacity` و `scrim-opacity`، کلیدهای `layout` برای مقدارهای جدول چیدمان ۲-۵، `alias.accent-finance*` و ساختار `contrast` (AX-05). `font-family-fa` و `font-family-latin` تا پذیرش ADR-UI-003 همان `system` می‌مانند (AD-07 ت).
- **AX-05 (ساختار contrast):** `contrast.groups` گروه‌های VTG-01 تا VTG-10 را می‌آورد. هر مجموعه (`sets`) این کلیدها را دارد: `mode` برابر `product` (هر عضو `fg` با هر عضو `bg`) یا `zip` (عضو n‌ام `fg` با عضو n‌ام `bg`)، `count-per-theme`، `min-light` و `min-dark` (گرد تا دو رقم) و `row-2-8` که می‌گوید مجموعه ردیفی از ۲-۸ است. VT-02 جفت‌ها را از همین‌جا می‌سازد و VT-03 `min-*` را با ۲-۸ و با محاسبه‌ی خودش می‌سنجد.
- **AX-07 (تغییر):** هر تغییر فایل فقط با ADR، TK-09 و AGX-04 یا AGX-05 است. در همان درخواست ادغام فایل مخزن، الف-۳، مقدار checksum در AX-02، جدول‌های ۲-۲ تا ۲-۸، ۳-۱ و ۴-۲ و `design_tokens.g.dart` با هم عوض می‌شوند؛ سپس golden‌ها بازتولید می‌شوند (VR-04، GM-06) و GTX-01 باز می‌شود (GT-07).

### الف-۲ فهرست نام توکن‌ها

جدول الف-۲-الف: نام‌های ثبت‌شده در `design_tokens.json` (VT-01 گام ۱)

| شناسه | بخش فایل | نام‌ها | شمار |
| --- | --- | --- | --- |
| AXT-01 | `meta` | `name`، `tokens-version`، `format-version`، `checksum` | ۴ |
| AXT-02 | `color.light` و `color.dark` (خنثی) | `background`، `surface`، `surface-raised`، `border`، `border-strong`، `text-primary`، `text-secondary`، `text-disabled`، `on-fill`، `ring-track`، `focus-ring`، `inverse-surface`، `inverse-text`، `scrim` | ۱۴ در هر تم |
| AXT-03 | `color.light` و `color.dark` (پرکننده) | `primary`، `accent-health`، `accent-tasks`، `accent-car`، `success`، `warning`، `danger`، `info`؛ برای هر کدام خود نام و پسوندهای `-hover`، `-pressed` و `-subtle` | ۳۲ در هر تم |
| AXT-04 | `alias` | `accent-finance`، `accent-finance-hover`، `accent-finance-pressed`، `accent-finance-subtle` | ۴ |
| AXT-05 | `scrim-opacity` و `state-opacity` | `light`، `dark`؛ `hover-layer`، `pressed-layer`، `disabled-content`، `disabled-surface` | ۶ |
| AXT-06 | `elevation` | `elev-0`، `elev-1`، `elev-2` | ۳ |
| AXT-07 | `typography` | `font-family-fa`، `font-family-latin`، `weights`، `letter-spacing`، و در `scale`: `caption`، `body-sm`، `body`، `label`، `title-sm`، `title`، `heading`، `display` | ۱۲ |
| AXT-08 | `space` | `space-1`، `space-2`، `space-3`، `space-4`، `space-6`، `space-8`، `space-12` | ۷ |
| AXT-09 | `radius` | `radius-sm`، `radius-md`، `radius-lg`، `radius-xl`، `radius-full` | ۵ |
| AXT-10 | `size` | `touch-min`، `control-sm`، `control-md`، `control-lg`، `icon-sm`، `icon-md`، `icon-lg`، `dot-sm`، `dot-md`، `dot-lg`، `avatar-sm`، `avatar-md`، `fab`، `bottom-nav-height`، `topbar-height`، `side-panel-width`، `reading-max-width`، `ring-diameter`، `ring-stroke`، `ring-gap`، `state-icon`، `content-max`، `sidebar-width-collapsed`، `sidebar-width-open` | ۲۴ |
| AXT-11 | `layout` | `compact`، `medium`، `expanded`، `large`؛ در هر کدام `min-width`، `max-width`، `page-padding`، `card-padding`، `card-gap`، `section-gap` | ۴ کلاس × ۶ کلید |
| AXT-12 | `motion` | `duration`: `instant`، `micro`، `exit`، `base`، `enter`، `max`، `ring-stagger`، `spinner-loop`، `skeleton-loop`، `breathe-loop`؛ `timing`: `skeleton-delay`، `toast-visible`، `toast-undo-visible`، `tooltip-delay`؛ `curve`: `standard`، `decelerate`، `accelerate` | ۱۷ |
| AXT-13 | `contrast` | `surfaces` و `groups` با شناسه‌های VTG-01 تا VTG-10 | ۱۰ گروه |

### الف-۳ متن کامل فایل

```json
{
  "meta": {
    "name": "BlueHesab Mini design tokens",
    "tokens-version": "1.1",
    "format-version": 1,
    "checksum": "e6064535e236c5fcb322e0f454173e30d5c2dcdbac603a0a97d18dfebca33e3e"
  },
  "color": {
    "light": {
      "background": "#F8FAFC",
      "surface": "#FFFFFF",
      "surface-raised": "#FFFFFF",
      "border": "#E2E8F0",
      "border-strong": "#7C8BA1",
      "text-primary": "#0F172A",
      "text-secondary": "#64748B",
      "text-disabled": "#94A3B8",
      "on-fill": "#FFFFFF",
      "ring-track": "#E2E8F0",
      "focus-ring": "#2563EB",
      "inverse-surface": "#0F172A",
      "inverse-text": "#F8FAFC",
      "scrim": "#0F172A",
      "primary": "#2563EB",
      "primary-hover": "#225BD8",
      "primary-pressed": "#2055CA",
      "accent-health": "#007974",
      "accent-health-hover": "#006F6B",
      "accent-health-pressed": "#006864",
      "accent-tasks": "#6E53B6",
      "accent-tasks-hover": "#654CA7",
      "accent-tasks-pressed": "#5F479D",
      "accent-car": "#9B418B",
      "accent-car-hover": "#8F3C80",
      "accent-car-pressed": "#853878",
      "success": "#15803D",
      "success-hover": "#137638",
      "success-pressed": "#126E34",
      "warning": "#B45309",
      "warning-hover": "#A64C08",
      "warning-pressed": "#9B4708",
      "danger": "#B91C1C",
      "danger-hover": "#AA1A1A",
      "danger-pressed": "#9F1818",
      "info": "#0369A1",
      "info-hover": "#036194",
      "info-pressed": "#035A8A",
      "primary-subtle": "#EEF3FD",
      "accent-health-subtle": "#EBF4F4",
      "accent-tasks-subtle": "#F3F1F9",
      "accent-car-subtle": "#F7F0F6",
      "success-subtle": "#F1F7F3",
      "warning-subtle": "#FAF5F0",
      "danger-subtle": "#FBF1F1",
      "info-subtle": "#F0F6F9"
    },
    "dark": {
      "background": "#0B1220",
      "surface": "#111A2C",
      "surface-raised": "#17233A",
      "border": "#26324A",
      "border-strong": "#64748B",
      "text-primary": "#E8EDF5",
      "text-secondary": "#9AA8BD",
      "text-disabled": "#5B6B87",
      "on-fill": "#0B1220",
      "ring-track": "#26324A",
      "focus-ring": "#60A5FA",
      "inverse-surface": "#E8EDF5",
      "inverse-text": "#0B1220",
      "scrim": "#000000",
      "primary": "#60A5FA",
      "primary-hover": "#5898E6",
      "primary-pressed": "#538ED7",
      "accent-health": "#0DCBC3",
      "accent-health-hover": "#0CBBB3",
      "accent-health-pressed": "#0BAFA8",
      "accent-tasks": "#B4A1FC",
      "accent-tasks-hover": "#A694E8",
      "accent-tasks-pressed": "#9B8AD9",
      "accent-car": "#E490D2",
      "accent-car-hover": "#D284C1",
      "accent-car-pressed": "#C47CB5",
      "success": "#4ADE80",
      "success-hover": "#44CC76",
      "success-pressed": "#40BF6E",
      "warning": "#FBBF24",
      "warning-hover": "#E7B021",
      "warning-pressed": "#D8A41F",
      "danger": "#F87171",
      "danger-hover": "#E46868",
      "danger-pressed": "#D56161",
      "info": "#38BDF8",
      "info-hover": "#34AEE4",
      "info-pressed": "#30A3D5",
      "primary-subtle": "#1E304D",
      "accent-health-subtle": "#103644",
      "accent-tasks-subtle": "#2B304D",
      "accent-car-subtle": "#332D47",
      "success-subtle": "#1A3939",
      "warning-subtle": "#36342B",
      "danger-subtle": "#362837",
      "info-subtle": "#17344D"
    }
  },
  "alias": {
    "accent-finance": "primary",
    "accent-finance-hover": "primary-hover",
    "accent-finance-pressed": "primary-pressed",
    "accent-finance-subtle": "primary-subtle"
  },
  "scrim-opacity": {
    "light": 0.4,
    "dark": 0.6
  },
  "state-opacity": {
    "hover-layer": 0.08,
    "pressed-layer": 0.12,
    "disabled-content": 0.38,
    "disabled-surface": 0.12
  },
  "elevation": {
    "elev-0": null,
    "elev-1": {
      "light": {
        "x": 0,
        "y": 4,
        "blur": 16,
        "color": "#0F172A",
        "opacity": 0.08
      },
      "dark": {
        "x": 0,
        "y": 4,
        "blur": 16,
        "color": "#000000",
        "opacity": 0.4
      }
    },
    "elev-2": {
      "light": {
        "x": 0,
        "y": 8,
        "blur": 24,
        "color": "#0F172A",
        "opacity": 0.12
      },
      "dark": {
        "x": 0,
        "y": 8,
        "blur": 24,
        "color": "#000000",
        "opacity": 0.5
      }
    }
  },
  "typography": {
    "font-family-fa": "system",
    "font-family-latin": "system",
    "weights": [400, 500, 600, 700],
    "letter-spacing": 0,
    "scale": {
      "caption": {
        "size": 12,
        "weight": 400,
        "line": 20
      },
      "body-sm": {
        "size": 14,
        "weight": 400,
        "line": 24
      },
      "body": {
        "size": 16,
        "weight": 400,
        "line": 28
      },
      "label": {
        "size": 14,
        "weight": 500,
        "line": 22
      },
      "title-sm": {
        "size": 20,
        "weight": 600,
        "line": 30
      },
      "title": {
        "size": 24,
        "weight": 600,
        "line": 34
      },
      "heading": {
        "size": 32,
        "weight": 700,
        "line": 44
      },
      "display": {
        "size": 44,
        "weight": 700,
        "line": 58
      }
    }
  },
  "space": {
    "space-1": 4,
    "space-2": 8,
    "space-3": 12,
    "space-4": 16,
    "space-6": 24,
    "space-8": 32,
    "space-12": 48
  },
  "radius": {
    "radius-sm": 6,
    "radius-md": 8,
    "radius-lg": 12,
    "radius-xl": 16,
    "radius-full": 9999
  },
  "size": {
    "touch-min": 44,
    "control-sm": 36,
    "control-md": 44,
    "control-lg": 48,
    "icon-sm": 16,
    "icon-md": 20,
    "icon-lg": 24,
    "dot-sm": 6,
    "dot-md": 8,
    "dot-lg": 12,
    "avatar-sm": 32,
    "avatar-md": 40,
    "fab": 56,
    "bottom-nav-height": 64,
    "topbar-height": 64,
    "side-panel-width": 420,
    "reading-max-width": 720,
    "ring-diameter": 184,
    "ring-stroke": 10,
    "ring-gap": 4,
    "state-icon": 48,
    "content-max": 1120,
    "sidebar-width-collapsed": 72,
    "sidebar-width-open": 264
  },
  "layout": {
    "compact": {
      "min-width": 0,
      "max-width": 599,
      "page-padding": 16,
      "card-padding": 16,
      "card-gap": 16,
      "section-gap": 24
    },
    "medium": {
      "min-width": 600,
      "max-width": 839,
      "page-padding": 24,
      "card-padding": 16,
      "card-gap": 16,
      "section-gap": 24
    },
    "expanded": {
      "min-width": 840,
      "max-width": 1199,
      "page-padding": 32,
      "card-padding": 24,
      "card-gap": 24,
      "section-gap": 32
    },
    "large": {
      "min-width": 1200,
      "max-width": null,
      "page-padding": 32,
      "card-padding": 24,
      "card-gap": 24,
      "section-gap": 32
    }
  },
  "motion": {
    "duration": {
      "instant": 0,
      "micro": 120,
      "exit": 200,
      "base": 240,
      "enter": 320,
      "max": 350,
      "ring-stagger": 60,
      "spinner-loop": 800,
      "skeleton-loop": 1200,
      "breathe-loop": 1600
    },
    "timing": {
      "skeleton-delay": 400,
      "toast-visible": 4000,
      "toast-undo-visible": 6000,
      "tooltip-delay": 500
    },
    "curve": {
      "standard": [0.2, 0, 0, 1],
      "decelerate": [0, 0, 0, 1],
      "accelerate": [0.3, 0, 1, 1]
    }
  },
  "contrast": {
    "surfaces": ["background", "surface", "surface-raised"],
    "groups": [
      {
        "id": "VTG-01",
        "threshold": 4.5,
        "sets": [
          {
            "mode": "product",
            "fg": ["text-primary"],
            "bg": ["background", "surface", "surface-raised"],
            "count-per-theme": 3,
            "min-light": 17.06,
            "min-dark": 13.35,
            "row-2-8": true
          },
          {
            "mode": "product",
            "fg": ["text-secondary"],
            "bg": ["background", "surface", "surface-raised"],
            "count-per-theme": 3,
            "min-light": 4.55,
            "min-dark": 6.51,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-02",
        "threshold": 4.5,
        "sets": [
          {
            "mode": "product",
            "fg": ["primary", "accent-health", "accent-tasks", "accent-car", "success", "warning", "danger", "info"],
            "bg": ["background", "surface", "surface-raised"],
            "count-per-theme": 24,
            "min-light": 4.79,
            "min-dark": 5.67,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-03",
        "threshold": 4.5,
        "sets": [
          {
            "mode": "product",
            "fg": ["on-fill"],
            "bg": ["primary", "primary-hover", "primary-pressed", "accent-health", "accent-health-hover", "accent-health-pressed", "accent-tasks", "accent-tasks-hover", "accent-tasks-pressed", "accent-car", "accent-car-hover", "accent-car-pressed", "success", "success-hover", "success-pressed", "warning", "warning-hover", "warning-pressed", "danger", "danger-hover", "danger-pressed", "info", "info-hover", "info-pressed"],
            "count-per-theme": 24,
            "min-light": 5.02,
            "min-dark": 5.09,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-04",
        "threshold": 4.5,
        "sets": [
          {
            "mode": "zip",
            "fg": ["primary", "accent-health", "accent-tasks", "accent-car", "success", "warning", "danger", "info"],
            "bg": ["primary-subtle", "accent-health-subtle", "accent-tasks-subtle", "accent-car-subtle", "success-subtle", "warning-subtle", "danger-subtle", "info-subtle"],
            "count-per-theme": 8,
            "min-light": 4.62,
            "min-dark": 5.01,
            "row-2-8": true
          },
          {
            "mode": "product",
            "fg": ["text-primary"],
            "bg": ["primary-subtle", "accent-health-subtle", "accent-tasks-subtle", "accent-car-subtle", "success-subtle", "warning-subtle", "danger-subtle", "info-subtle"],
            "count-per-theme": 8,
            "min-light": 15.94,
            "min-dark": 10.58,
            "row-2-8": false
          }
        ]
      },
      {
        "id": "VTG-05",
        "threshold": 4.5,
        "sets": [
          {
            "mode": "product",
            "fg": ["inverse-text"],
            "bg": ["inverse-surface"],
            "count-per-theme": 1,
            "min-light": 17.06,
            "min-dark": 15.93,
            "row-2-8": false
          }
        ]
      },
      {
        "id": "VTG-06",
        "threshold": 3,
        "sets": [
          {
            "mode": "product",
            "fg": ["border-strong"],
            "bg": ["background", "surface", "surface-raised"],
            "count-per-theme": 3,
            "min-light": 3.31,
            "min-dark": 3.3,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-07",
        "threshold": 3,
        "sets": [
          {
            "mode": "product",
            "fg": ["primary", "accent-health", "accent-tasks", "accent-car"],
            "bg": ["ring-track"],
            "count-per-theme": 4,
            "min-light": 4.19,
            "min-dark": 5.04,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-08",
        "threshold": 3,
        "sets": [
          {
            "mode": "product",
            "fg": ["primary", "accent-health", "accent-tasks", "accent-car", "success", "warning", "danger", "info"],
            "bg": ["background", "surface", "surface-raised"],
            "count-per-theme": 24,
            "min-light": 4.79,
            "min-dark": 5.67,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-09",
        "threshold": 3,
        "sets": [
          {
            "mode": "product",
            "fg": ["focus-ring"],
            "bg": ["background", "surface", "surface-raised"],
            "count-per-theme": 3,
            "min-light": 4.94,
            "min-dark": 6.17,
            "row-2-8": true
          }
        ]
      },
      {
        "id": "VTG-10",
        "threshold": 3.3,
        "sets": [
          {
            "mode": "product",
            "fg": ["primary", "text-secondary", "border-strong"],
            "bg": ["surface"],
            "count-per-theme": 3,
            "min-light": 3.46,
            "min-dark": 3.65,
            "row-2-8": false
          }
        ]
      }
    ]
  }
}
```

### الف-۴ جفت‌های کنتراست

جدول الف-۴-الف: مجموعه‌های `contrast.groups`، شمار جفت و کمینه‌ها (بازمحاسبه با روشنایی نسبی بدون گرد میانی؛ VT-02)

| گروه | مجموعه | جفت در هر تم | کمینه روشن | کمینه تیره | ردیف ۲-۸ |
| --- | --- | --- | --- | --- | --- |
| VTG-01 | `text-primary` روی سه سطح | ۳ | ۱۷٫۰۶ | ۱۳٫۳۵ | بله |
| VTG-01 | `text-secondary` روی سه سطح | ۳ | ۴٫۵۵ | ۶٫۵۱ | بله |
| VTG-02 | هشت رنگ پرکننده به‌عنوان متن روی سه سطح | ۲۴ | ۴٫۷۹ | ۵٫۶۷ | بله |
| VTG-03 | `on-fill` روی هشت رنگ پرکننده، hover و pressed | ۲۴ | ۵٫۰۲ | ۵٫۰۹ | بله |
| VTG-04 | هر رنگ روی `*-subtle` همان رنگ | ۸ | ۴٫۶۲ | ۵٫۰۱ | بله |
| VTG-04 | `text-primary` روی هشت `*-subtle` | ۸ | ۱۵٫۹۴ | ۱۰٫۵۸ | خیر |
| VTG-05 | `inverse-text` روی `inverse-surface` | ۱ | ۱۷٫۰۶ | ۱۵٫۹۳ | خیر |
| VTG-06 | `border-strong` روی سه سطح | ۳ | ۳٫۳۱ | ۳٫۳۰ | بله |
| VTG-07 | چهار رنگ کمان (`primary` و سه `accent-*`) روی `ring-track` | ۴ | ۴٫۱۹ | ۵٫۰۴ | بله |
| VTG-08 | هشت رنگ پرکننده روی سه سطح (مرز دکمه) | ۲۴ | ۴٫۷۹ | ۵٫۶۷ | بله |
| VTG-09 | `focus-ring` روی سه سطح | ۳ | ۴٫۹۴ | ۶٫۱۷ | بله |
| VTG-10 | `primary`، `text-secondary` و `border-strong` روی `surface` (جدا گزارش می‌شود) | ۳ | ۳٫۴۶ | ۳٫۶۵ | خیر |

- **AX-06 (شمار جفت‌ها):** کمینه‌ی هر ردیف ۲-۸ با `min-light` و `min-dark` همین جدول (تا دو رقم) برابر است. مجموع مجموعه‌های ردیف‌دار ۲-۸ ۹۶ جفت در هر تم و ۱۹۲ جفت در دو تم است و با دو مجموعه‌ی VTG-04 (`text-primary` روی `*-subtle`) و VTG-05 به ۱۰۵ جفت در هر تم و ۲۱۰ جفت می‌رسد؛ عدد ۲۱۰ در ۲-۱، ۲-۸، VT-03 و GTX-01 همین شمار است؛ VT-03 شمار را از `contrast.groups` می‌خواند و مغایرتش با ۲۱۰ را شکست گزارش می‌کند.

### الف-۵ آزمون

- **AX-08 (آزمون):** مطابق CM-13 و VR-06: الف) مرحله‌ی ایستای `ui_check.dart tokens` (VT-01 تا VT-06) روی فایل مخزن سبز است؛ ب) فایل مخزن با الف-۳ برابر و `checksum` آن با AX-02 درست است؛ پ) نام‌های جدول الف-۲-الف و کلیدهای فایل برابرند؛ ت) هر مقدار فایل با جدول‌های ۲-۲ تا ۲-۵، ۳-۱ و ۴-۲ برابر است و تنها مقدار تازه `tooltip-delay` است (AX-04)؛ ث) کمینه‌های جدول الف-۴-الف با ۲-۸ برابرند (دو رقم). شمار ۲۱۰ در AX-06 با جمع شمار جفت‌های الف-۴-الف برابر است و هر مغایرتی شکست VT-03 است.

# 03 - Theme and Navigation

`AppColors` centralizes navy, electric blue, cyan, teal, neutral surfaces, borders, and text colors. `AppTheme.light` configures Material 3 typography, cards, inputs, buttons, app bars, floating actions, navigation, and dividers.

The destination order is Categories, Offers, Home, Cart, Menu. Home is the default. A 66×66 circular center-docked button is the primary Home action. Regular navigation items have semantic labels, selected state, adequate tap bounds, and safe-area protection. Cart has a badge anchor but no fabricated count.

Home presents the approved full logo, future search location, category location, promotion location, and featured-product location without fake commerce data. Other destinations explicitly identify themselves as later-phase foundations.

## Physical-device verification

On the SM A556E, a forced cold start exposed Home as selected. Device UI semantics then verified `Categories foundation`, `Offers foundation`, `Cart foundation`, and `Menu foundation`. Tapping the center Home button removed Menu content and restored Home with its selected semantic state.

Screenshots and UI hierarchy inspection showed safe-area spacing and a visible centered Home action. The approved logo rendered legibly and at its natural aspect ratio. Log inspection found no Flutter error, fatal exception, RenderFlex warning, or overflow marker.

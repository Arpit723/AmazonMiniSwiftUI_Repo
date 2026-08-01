# Naming Conventions

## Swift / files

- Types: `PascalCase` (`ProductDetailView`, `CartViewModel`).
- Files named after their primary type (`ProductDetailView.swift`), one top-level type per file where practical.
- Protocols/enums: `AuthError`, `AppSpacing`, `CartItem`.
- Views that wrap a `ViewModifier` expose a `View` extension, e.g. `.chevronOnlyBackButton()` (see `Core/DesignSystem/BackButton.swift`).

## Design tokens (single source of truth: `Core/DesignSystem/DesignTokens.swift`)

- Colors: `Color.brandNavy` (headings), `.brandText`, `.brandSecondary`, `.brandOrange` (primary actions), `.brandOrangePressed`, `.fieldBackground`, `.fieldBorder`, `.hairline`, `.errorRed`, `.successGreen`, `.surface`.
- Spacing: `AppSpacing.{xs,sm,md,lg,xl}` (4/8/12/16/24).
- Radii: `AppRadius.{sm,md,lg}` (8/12/16).
- Type: `AppFont.{largeTitle,title,title2,headline,body,subheadline,footnote,caption}`.
- Do **not** hardcode hex/spacing/font sizes in views — use the tokens.

## Reusable components (`Core/DesignSystem/` + `Screens/Auth/View/AuthComponents.swift`)

`PriceText(amount:font:color:)`, `RemoteImage(urlString:contentMode:)`, `PrimaryButton(title:isLoading:isEnabled:action:)`, `AuthInputField(...)`, `QuantityStepper(quantity:onIncrement:onDecrement:)`, `.chevronOnlyBackButton()`.

## Git

- Branches: `feature/<topic>` (don't implement on `main`).
- Commit messages: present-tense imperative — `Add …`, `Fix …`, `Make …`. One logical change per commit.
- Never commit `.DS_Store`, secrets, or gitignored local data (`.kilo/plans`, `docs/superpowers/`).

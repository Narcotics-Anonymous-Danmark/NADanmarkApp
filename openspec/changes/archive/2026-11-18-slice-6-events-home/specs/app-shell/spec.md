# Spec Delta

## ADDED Requirements

### Requirement: Home dashboard

Home SHALL show, on the primary background, the welcome "Narcotics
Anonymous Denmark" with the helpline "Helpline: 70 20 01 85" (Hjælpelinje),
followed in this order by: the cleantime cards (one per profile, see
cleantime), the Just for today card (see jft) and the event cards (see
events). A card set with nothing to show is left out without leaving a gap.

> Source: App/src/app/pages/home/home.page.{ts,html} (legacy)

#### Scenario: Dashboard order

- **WHEN** Home opens with one cleantime profile and three events in the feed
- **THEN** the welcome, the cleantime card, the Just for today card and the event cards appear in that order from top to bottom

#### Scenario: Dashboard without profiles or events

- **WHEN** Home opens with no cleantime profile and an empty events feed
- **THEN** only the welcome and the Just for today card are shown

# EKS Workshop - Translations

To make the content more accessible EKS Workshop is translated to multiple languages. The translation process is designed to be primarily automated in order to facilitate on-going maintenance.

## Onboarding a language

To onboard a new language first do some setup:

1. Initialize the translation folder: `(cd website && write-translations --locale <code>)`
1. Create the required directory: `mkdir website/i18n/<code>/docusaurus-plugin-content-docs/current`

Then use `toolkit-md` to translate the Markdown content:

```bash
yarn toolkit-md translate --to <code> --write \
  --skip-file-suffix --translation-dir website/i18n/<code>/docusaurus-plugin-content-docs/current
```

This process will take around 30 minutes.

Next translate other values:

1. `website/i18n/<code>/docusaurus-theme-classic/navbar.json`: Navigation bar values
1. `website/i18n/<code>/docusaurus-theme-classic/footer.json`: Footer values
1. `website/i18n/<code>/docusaurus-plugin-content-docs/current.json`: Delete all values

TODO

## Ongoing updates

A GitHub Actions workflow is used to make ongoing updates to the translations as changes are merged to the `main` branch.

The high level process is:

1.

# EKS Workshop - Translations

To make the content more accessible, EKS Workshop is translated to multiple languages. The translation process is designed to be primarily automated using [toolkit-md](https://github.com/awslabs/toolkit-md), an AI-powered Markdown tool backed by Amazon Bedrock, in order to facilitate ongoing maintenance.

Currently supported languages:

- Japanese (`ja`)

Planned languages include French, Spanish, Portuguese, and Korean.

## How it works

Translation is handled by `toolkit-md`, which is configured via `.toolkit-mdrc` at the root of the repository. The key settings relevant to translation are:

- `contentDir`: points to `website/docs` as the English source
- `ai.styleGuides`: includes both the general `docs/style_guide.md` and the `i18n/` directory, from which toolkit-md automatically loads any language-specific style guide matching the target language (e.g. `i18n/style.ja.md` when translating to `ja`)
- `ai.contextStrategy`: set to `siblings`, meaning each file is translated with awareness of other files in the same directory

toolkit-md tracks whether the English source has changed since the last translation using a `tmdTranslationSourceHash` field stored in the frontmatter of each translated file. This means only files whose source content has changed will be re-translated on subsequent runs, keeping the process efficient and avoiding unnecessary churn.

## Language-specific style guides

Each language should have a style guide at `i18n/style.<code>.md`. This file is passed as additional context to the LLM during translation and should document:

- Terms that must remain in English (AWS service names, Kubernetes terminology, etc.)
- Terms that should be translated, with the preferred translation
- Any other language-specific conventions

The style guide for Japanese is at `i18n/style.ja.md`.

## Onboarding a new language

To add a new language, follow these steps:

**1. Add the locale to Docusaurus**

Add the language code to the `i18n.locales` array in `website/docusaurus.config.js`:

```js
i18n: {
  defaultLocale: 'en',
  locales: ['en', 'ja', '<code>'],
},
```

**2. Initialize the Docusaurus i18n directory**

```bash
cd website && yarn write-translations --locale <code>
```

Then create the directory for translated docs content:

```bash
mkdir -p website/i18n/<code>/docusaurus-plugin-content-docs/current
```

**3. Create a language-specific style guide**

Create `i18n/style.<code>.md` with translation rules for the language. This file will be automatically picked up by toolkit-md during translation runs. See `i18n/style.ja.md` as a reference.

**4. Translate the Markdown content**

Run toolkit-md to perform the initial translation. This process takes approximately 30 minutes:

```bash
yarn toolkit-md translate \
  --to <code> \
  --write \
  --skip-file-suffix \
  --translation-dir website/i18n/<code>/docusaurus-plugin-content-docs/current \
  ./website/docs
```

Note: `--skip-file-suffix` ensures translated files are written as `index.md` rather than `index.<code>.md`, which is required for Docusaurus i18n to work correctly.

**5. Translate static UI strings**

Manually translate the following files:

- `website/i18n/<code>/docusaurus-theme-classic/navbar.json`: navigation bar labels
- `website/i18n/<code>/docusaurus-theme-classic/footer.json`: footer labels
- `website/i18n/<code>/docusaurus-plugin-content-docs/current.json`: delete all values (Docusaurus will use English fallbacks)

**6. Add the language to the automation workflow**

Add the new language code to the `matrix.language` array in `.github/workflows/auto-translate.yaml`:

```yaml
strategy:
  matrix:
    language: [ja, <code>]
```

## Ongoing updates

A GitHub Actions workflow (`.github/workflows/auto-translate.yaml`) automatically keeps translations up to date as English content changes. It is triggered on every push to `main`, and can also be run manually via `workflow_dispatch`.

The workflow runs in three phases:

**1. Branch setup**

The workflow checks whether the `automated-translations` branch exists. If it does, it rebases it on the latest `main` to incorporate any new English content. If it doesn't exist, it creates it from `main`. This ensures translations are always applied on top of the latest source.

**2. Translation (parallel)**

Each language in the matrix runs as a parallel job. Each job:

- Checks out the `automated-translations` branch
- Assumes an AWS IAM role to access Amazon Bedrock (via `INFERENCE_AWS_ROLE_ARN`)
- Runs `toolkit-md translate` against `website/docs`, writing output to `website/i18n/<language>/docusaurus-plugin-content-docs/current`
- Uploads the translated files as a GitHub Actions artifact

Because toolkit-md uses `tmdTranslationSourceHash` to detect changes, only files whose English source has been modified since the last translation run will be re-translated.

**3. Consolidation and PR**

Once all language jobs complete, a final job:

- Downloads all translation artifacts
- Applies them to the `automated-translations` branch
- Commits the changes (skipping the commit if nothing changed)
- Creates or updates a pull request targeting `main`

The PR should be reviewed for translation quality and merged before each monthly release.

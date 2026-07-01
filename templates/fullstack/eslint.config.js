// Managed by bootstrap (fullstack profile). ESLint flat config (ESLint 9+),
// type-aware and strict. Requires @eslint/js, typescript-eslint, typescript and
// globals (see the npm dev deps printed by `bootstrap apply`).
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import globals from 'globals';

export default tseslint.config(
  {
    ignores: ['dist/**', 'build/**', 'public/**', 'vendor/**', 'var/**'],
  },

  // Base JS rules for every file.
  js.configs.recommended,

  // Type-aware rules for TypeScript. recommendedTypeChecked is strict but not
  // overbearing; stylisticTypeChecked adds consistency rules on top. Bump to
  // strictTypeChecked if you want the most demanding preset.
  ...tseslint.configs.recommendedTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,

  // Wire up type-aware linting: typescript-eslint locates the nearest tsconfig.
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: { ...globals.browser },
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  // Plain JS / config files have no type information. Turn the type-aware rules
  // off for them so ESLint doesn't error trying to type-check them.
  {
    files: ['**/*.{js,mjs,cjs}'],
    extends: [tseslint.configs.disableTypeChecked],
  },
);

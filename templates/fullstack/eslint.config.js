// Managed by bootstrap (fullstack profile). ESLint flat config (ESLint 9+).
// Requires @eslint/js (see the suggested npm dev deps printed by `bootstrap apply`).
import js from '@eslint/js';

export default [
  {
    ignores: ['dist/**', 'build/**', 'public/build/**', 'vendor/**', 'var/**'],
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
  },
];

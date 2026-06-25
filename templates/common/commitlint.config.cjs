// Managed by bootstrap. Conventional Commits + Gitmoji.
// Header shape: "<emoji> <type>(<scope?>): <subject>" — the leading emoji is optional.
// Requires commitlint on your PATH (mac-setup or the project's node_modules).
module.exports = {
  extends: ['@commitlint/config-conventional'],
  parserPreset: {
    parserOpts: {
      // Capture an optional leading emoji (unicode or :shortcode:) before the type.
      headerPattern:
        /^(?:(\p{Extended_Pictographic}|:[\w+-]+:)\s+)?(\w+)(?:\(([^)]+)\))?(!)?: (.+)$/u,
      headerCorrespondence: ['emoji', 'type', 'scope', 'breaking', 'subject'],
    },
  },
  rules: {
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
      ],
    ],
  },
};

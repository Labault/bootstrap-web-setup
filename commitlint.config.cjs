// Managed by bootstrap. Conventional Commits + Gitmoji — mirrors mac-setup.
// Needs these dev deps in the project (bootstrap suggests them, never installs):
//   @commitlint/cli @commitlint/config-conventional @gitmoji/gitmoji-regex commitlint-config-gitmoji
const { gitmojiCodeRegex, gitmojiUnicodeRegex } = require('@gitmoji/gitmoji-regex');

module.exports = {
  extends: ['@commitlint/config-conventional', 'gitmoji'],
  parserPreset: {
    parserOpts: {
      headerPattern: new RegExp(
        `^\\s*(?:${gitmojiCodeRegex.source}|${gitmojiUnicodeRegex.source})\\s(?<type>\\w*)(?:\\((?<scope>.*)\\))?!?:\\s(?<subject>.+)$`,
      ),
      headerCorrespondence: ['type', 'scope', 'subject'],
    },
  },
};
